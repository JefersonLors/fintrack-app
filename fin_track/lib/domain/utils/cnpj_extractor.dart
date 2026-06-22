enum CnpjDocumentContext { general, fiscal, transfer, payment }

enum CnpjSource { text, accessKey, qrCode }

class CnpjCandidate {
  const CnpjCandidate({
    required this.cnpj,
    required this.score,
    required this.source,
    required this.context,
    this.accessKey,
    this.urlQrCode,
  });

  final String cnpj;
  final double score;
  final CnpjSource source;
  final String context;
  final String? accessKey;
  final String? urlQrCode;
}

class CnpjExtractionResult {
  const CnpjExtractionResult({required this.candidates});

  final List<CnpjCandidate> candidates;

  CnpjCandidate get best => candidates.first;

  String get cnpj => best.cnpj;

  String? get accessKey => best.accessKey;

  String? get urlQrCode => best.urlQrCode;
}

class CnpjExtractor {
  const CnpjExtractor();

  CnpjExtractionResult? extract(
    String text, {
    List<String> codes = const [],
    CnpjDocumentContext context = CnpjDocumentContext.general,
  }) {
    final candidates = <CnpjCandidate>[
      ..._candidatesFromAccessKeys(text, codes, context),
      ..._candidatesFromText(text, context),
    ];
    if (candidates.isEmpty) {
      return null;
    }

    final byCnpj = <String, CnpjCandidate>{};
    for (final candidate in candidates) {
      final current = byCnpj[candidate.cnpj];
      if (current == null || candidate.score > current.score) {
        byCnpj[candidate.cnpj] = candidate;
      }
    }

    final ordered = byCnpj.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return _sourcePriority(b.source).compareTo(_sourcePriority(a.source));
      });
    return CnpjExtractionResult(candidates: ordered);
  }

  String? extractFirstValid(String text) {
    return extract(text)?.cnpj;
  }

  List<CnpjCandidate> _candidatesFromAccessKeys(
    String text,
    List<String> codes,
    CnpjDocumentContext context,
  ) {
    final candidates = <CnpjCandidate>[];
    final sources = <_TextSource>[
      _TextSource(text, _fiscalUrl(text)),
      for (final code in codes) _TextSource(code, _fiscalUrl(code)),
    ];

    for (final source in sources) {
      for (final accessKey in _extractAccessKeys(source.text)) {
        final cnpj = accessKey.substring(6, 20);
        if (!hasValidCnpjDigits(cnpj)) {
          continue;
        }
        final candidateSource = source.fiscalUrl == null
            ? CnpjSource.accessKey
            : CnpjSource.qrCode;
        candidates.add(
          CnpjCandidate(
            cnpj: cnpj,
            score: candidateSource == CnpjSource.qrCode ? 118 : 112,
            source: candidateSource,
            context: 'access key',
            accessKey: accessKey,
            urlQrCode: source.fiscalUrl,
          ),
        );
      }
    }
    return candidates;
  }

  Iterable<String> _extractAccessKeys(String text) sync* {
    final matches = RegExp(r'(?<!\d)(?:\d[ .-]?){44}(?!\d)').allMatches(text);
    for (final match in matches) {
      final accessKey = match.group(0)?.replaceAll(RegExp(r'\D'), '');
      if (accessKey != null && accessKey.length == 44) {
        yield accessKey;
      }
    }
  }

  List<CnpjCandidate> _candidatesFromText(
    String text,
    CnpjDocumentContext context,
  ) {
    final candidates = <CnpjCandidate>[];
    final matches = RegExp(
      r'(?<![A-Za-z0-9])([0-9OoQqIiLl|SsBb][0-9OoQqIiLl|SsBb\s.,;:/\\\-_]{12,48}[0-9OoQqIiLl|SsBb])(?![A-Za-z0-9])',
    ).allMatches(text);

    for (final match in matches) {
      final raw = match.group(1);
      if (raw == null) {
        continue;
      }
      final cnpj = normalizeCnpjOcrDigits(raw).replaceAll(RegExp(r'\D'), '');
      if (cnpj.length != 14 || !hasValidCnpjDigits(cnpj)) {
        continue;
      }
      final localContext = _contextWindow(text, match.start, match.end);
      final score = _scoreText(
        text: text,
        start: match.start,
        end: match.end,
        context: context,
      );
      candidates.add(
        CnpjCandidate(
          cnpj: cnpj,
          score: score,
          source: CnpjSource.text,
          context: localContext.trim(),
        ),
      );
    }
    return candidates;
  }

  double _scoreText({
    required String text,
    required int start,
    required int end,
    required CnpjDocumentContext context,
  }) {
    final before = _normalizeSearch(
      text.substring((start - 180).clamp(0, text.length), start),
    );
    final after = _normalizeSearch(
      text.substring(end, (end + 60).clamp(0, text.length)),
    );
    final normalized = '$before\n$after';
    var score = 45.0;

    if (context == CnpjDocumentContext.fiscal) {
      score += 10;
    }
    if (context == CnpjDocumentContext.transfer ||
        context == CnpjDocumentContext.payment) {
      score += 4;
    }

    final receiverMarker = _lastIndex(before, const [
      'quem recebeu',
      'recebedor',
      'favorecido',
      'beneficiario',
      'beneficiario final',
      'destino',
      'establishment',
      'lojista',
      'cedente',
      'fornecedor',
    ]);
    final fiscalMarker = _lastIndex(before, const [
      'emitente',
      'cnpj emitente',
      'nota fiscal',
      'nfc-e',
      'nf-e',
      'cupom fiscal',
      'documento auxiliar',
      'chave de acesso',
    ]);
    final payerMarker = _lastIndex(before, const [
      'quem pagou',
      'pagador',
      'origem',
      'remetente',
      'cliente',
      'comprador',
      'titular',
    ]);
    final intermediaryMarker = _lastIndex(before, const [
      'instituicao',
      'instituicao intermediaria',
      'banco',
      'agencia',
      'numero da account',
    ]);

    if (receiverMarker > payerMarker && receiverMarker > intermediaryMarker) {
      score += 34;
    }

    if (fiscalMarker > payerMarker && fiscalMarker > intermediaryMarker) {
      score += 24;
    }

    if (payerMarker > receiverMarker && payerMarker > fiscalMarker) {
      score -= 30;
    }

    if (intermediaryMarker > receiverMarker &&
        intermediaryMarker > fiscalMarker) {
      score -= 18;
    }

    if (_containsAny(normalized, const ['cpf/cnpj', 'cnpj'])) {
      score += 8;
    }

    return score.clamp(0, 100).toDouble();
  }

  String _contextWindow(String text, int start, int end) {
    final startIndex = (start - 140).clamp(0, text.length);
    final endIndex = (end + 80).clamp(0, text.length);
    return text.substring(startIndex, endIndex);
  }

  int _lastIndex(String text, List<String> terms) {
    var last = -1;
    for (final term in terms) {
      final index = text.lastIndexOf(_normalizeSearch(term));
      if (index > last) {
        last = index;
      }
    }
    return last;
  }

  String? _fiscalUrl(String text) {
    final url = RegExp(
      r'(https?://[^\s|]+|www\.[^\s|]+)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    if (url == null || url.isEmpty) {
      return null;
    }
    final normalized = RegExp(r'^https?://', caseSensitive: false).hasMatch(url)
        ? url
        : 'https://$url';
    if (_containsAny(_normalizeSearch(normalized), const [
      'sefaz',
      'nfce',
      'nfe',
      'qrcode',
      'consulta',
      'chnfe',
    ])) {
      return normalized;
    }
    return null;
  }
}

bool hasValidCnpjDigits(String cnpj) {
  if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
    return false;
  }
  if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
    return false;
  }
  final firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final secondWeights = [6, ...firstWeights];
  final digits = cnpj.split('').map(int.parse).toList();
  int calculate(List<int> weights) {
    final sum = List<int>.generate(
      weights.length,
      (index) => digits[index] * weights[index],
    ).reduce((a, b) => a + b);
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  return calculate(firstWeights) == digits[12] &&
      calculate(secondWeights) == digits[13];
}

String normalizeCnpjOcrDigits(String text) {
  return text
      .replaceAll(RegExp(r'[OoQq]'), '0')
      .replaceAll(RegExp(r'[IiLl|]'), '1')
      .replaceAll(RegExp(r'[Ss]'), '5')
      .replaceAll(RegExp(r'[Bb]'), '8');
}

int _sourcePriority(CnpjSource source) {
  return switch (source) {
    CnpjSource.qrCode => 3,
    CnpjSource.accessKey => 2,
    CnpjSource.text => 1,
  };
}

bool _containsAny(String text, List<String> terms) {
  return terms.any((term) => text.contains(_normalizeSearch(term)));
}

String _normalizeSearch(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

class _TextSource {
  const _TextSource(this.text, this.fiscalUrl);

  final String text;
  final String? fiscalUrl;
}
