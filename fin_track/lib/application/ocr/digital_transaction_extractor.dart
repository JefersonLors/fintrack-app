import '../../domain/utils/ocr_parser_utils.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import 'normalized_ocr_text.dart';

class DigitalTransactionParticipant {
  const DigitalTransactionParticipant({
    this.name,
    this.document,
    this.institution,
    this.institutionDocument,
  });

  final String? name;
  final String? document;
  final String? institution;
  final String? institutionDocument;

  String? get cnpj {
    return extractValidCnpj(document ?? '');
  }

  bool get hasData =>
      _hasText(name) ||
      _hasText(document) ||
      _hasText(institution) ||
      _hasText(institutionDocument);
}

class DigitalTransactionResult {
  const DigitalTransactionResult({
    this.destination,
    this.source,
    this.amount,
    this.date,
    this.paymentMethod,
    this.transactionId,
  });

  final DigitalTransactionParticipant? destination;
  final DigitalTransactionParticipant? source;
  final double? amount;
  final DateTime? date;
  final String? paymentMethod;
  final String? transactionId;

  bool get hasDestination => destination?.hasData ?? false;
}

class DigitalTransactionExtractor {
  const DigitalTransactionExtractor();

  DigitalTransactionResult extract(NormalizedOcrText text) {
    final lines = text.lines;
    final raw = text.normalized;
    return DigitalTransactionResult(
      destination: _participant(
        lines,
        start: _destinationLabels,
        end: _sourceLabels,
      ),
      source: _participant(
        lines,
        start: _sourceLabels,
        end: _destinationLabels,
      ),
      amount: extractLargestAmount(raw),
      date: parseOcrDate(raw),
      paymentMethod: _paymentMethod(raw),
      transactionId: _transactionId(lines),
    );
  }

  DigitalTransactionParticipant? _participant(
    List<String> lines, {
    required List<String> start,
    required List<String> end,
  }) {
    final startIndex = _sectionIndex(lines, start);
    if (startIndex < 0) {
      return null;
    }
    final section = lines.sublist(
      startIndex + 1,
      _sectionEnd(lines, startIndex, end),
    );
    if (section.isEmpty) {
      return null;
    }

    final ignoredBlockIndex = _ignoredBlockIndex(section);
    final participantData = ignoredBlockIndex < 0
        ? section
        : section.sublist(0, ignoredBlockIndex);
    final institutionData = ignoredBlockIndex < 0
        ? const <String>[]
        : section.sublist(ignoredBlockIndex + 1);

    final participant = DigitalTransactionParticipant(
      name: _participantName(participantData),
      document: _participantDocument(participantData),
      institution: _institution(institutionData),
      institutionDocument: _institutionDocument(institutionData),
    );
    return participant.hasData ? participant : null;
  }

  int _sectionIndex(List<String> lines, List<String> labels) {
    return lines.indexWhere((line) {
      final text = normalizeSearch(line);
      return labels.any((label) => text == label || text.startsWith('$label '));
    });
  }

  int _sectionEnd(List<String> lines, int startIndex, List<String> end) {
    final relative = lines.skip(startIndex + 1).toList().indexWhere((line) {
      final text = normalizeSearch(line);
      return end.any((label) => text == label || text.startsWith('$label '));
    });
    return relative < 0 ? lines.length : startIndex + 1 + relative;
  }

  int _ignoredBlockIndex(List<String> lines) {
    return lines.indexWhere((line) {
      final text = normalizeSearch(line);
      if (_institutionLabels.any((label) => text == label)) {
        return true;
      }
      return _bankDataLabels.any(
        (label) => text == label || text.startsWith('$label '),
      );
    });
  }

  String? _participantName(List<String> lines) {
    final byLabel = _valueAfterLabel(lines, const [
      'estabelecimento',
      'nome',
      'favorecido',
      'recebedor',
      'beneficiario',
    ]);
    if (byLabel != null) {
      return byLabel;
    }
    return bestNameLine(
      lines.where((line) => !_isParticipantLabelLine(line)).toList(),
    );
  }

  String? _participantDocument(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final text = normalizeSearch(lines[i]);
      if (!text.contains('cpf') && !text.contains('cnpj')) {
        continue;
      }
      final inline = _cleanLabelValue(lines[i], ['cpf/cnpj', 'cnpj', 'cpf']);
      if (_hasText(inline)) {
        return inline;
      }
      for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
        if (_isParticipantLabelLine(lines[j])) {
          continue;
        }
        return lines[j].trim();
      }
    }
    final cnpj = extractValidCnpj(lines.join('\n'));
    return cnpj;
  }

  String? _institution(List<String> lines) {
    final candidates = <String>[];
    for (final line in lines) {
      final text = line.trim();
      if (text.isEmpty ||
          _isParticipantLabelLine(text) ||
          normalizeSearch(text).contains('cnpj') ||
          normalizeSearch(text).contains('cpf') ||
          RegExp(r'^[\d\s./-]+$').hasMatch(text)) {
        continue;
      }
      candidates.add(text);
      if (candidates.length >= 2) {
        break;
      }
    }
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.join(' / ');
  }

  String? _institutionDocument(List<String> lines) {
    return extractValidCnpj(lines.join('\n'));
  }

  String? _valueAfterLabel(List<String> lines, List<String> labels) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = normalizeSearch(line);
      final label = labels.firstWhere(
        (label) =>
            normalizedLine == label || normalizedLine.startsWith('$label '),
        orElse: () => '',
      );
      if (label.isEmpty) {
        continue;
      }
      final inline = _cleanLabelValue(line, [label]);
      final inlineName = bestNameLine([inline ?? '']);
      if (inlineName != null) {
        return inlineName;
      }
      for (var j = i + 1; j < lines.length && j <= i + 5; j++) {
        if (_isParticipantLabelLine(lines[j])) {
          continue;
        }
        final candidate = bestNameLine([lines[j]]);
        if (candidate != null) {
          return candidate;
        }
      }
    }
    return null;
  }

  String? _cleanLabelValue(String line, List<String> labels) {
    var value = line.trim();
    for (final label in labels) {
      final regex = RegExp('^${RegExp.escape(label)}\\b', caseSensitive: false);
      value = value.replaceFirst(regex, '').trim();
    }
    value = value.replaceFirst(RegExp(r'^[:\-/\s]+'), '').trim();
    return value.isEmpty ? null : value;
  }

  String? _paymentMethod(String text) {
    if (containsAny(text, ['pix'])) return 'Pix';
    if (containsAny(text, ['ted'])) return 'TED';
    if (containsAny(text, ['doc'])) return 'DOC';
    if (containsAny(text, ['credito', 'crédito'])) return 'Credito';
    if (containsAny(text, ['debito', 'débito'])) return 'Debito';
    if (containsAny(text, ['cartao', 'cartão'])) return 'Cartao';
    if (containsAny(text, ['transferencia'])) return 'Transferência';
    return ReceiptPaymentMethod.normalize(text);
  }

  String? _transactionId(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final text = normalizeSearch(lines[i]);
      if (!text.contains('id da transacao') &&
          !text.contains('e2e') &&
          !text.contains('codigo de autorizacao')) {
        continue;
      }
      final inline = _cleanLabelValue(lines[i], const [
        'id da transacao',
        'e2e',
        'codigo de autorizacao',
      ]);
      if (_hasText(inline)) {
        return inline;
      }
      if (i + 1 < lines.length && !_isParticipantLabelLine(lines[i + 1])) {
        return lines[i + 1].trim();
      }
    }
    return null;
  }

  bool _isParticipantLabelLine(String line) {
    final text = normalizeSearch(line.trim());
    return const {
      'valor',
      'tipo de transferencia',
      'pagamento',
      'cartao',
      'codigo de autorizacao',
      'id da transacao',
      'e2e',
      'nsu',
      'destino',
      'origem',
      'nome',
      'cpf',
      'cpf/cnpj',
      'cnpj',
      'instituicao',
      'instituição',
      'banco',
      'agencia',
      'agência',
      'account',
      'numero da account',
      'ispb',
      'quem recebeu',
      'quem pagou',
      'estabelecimento',
      'favorecido',
      'recebedor',
      'beneficiario',
      'remetente',
      'pagador',
    }.contains(text);
  }

  static const _destinationLabels = [
    'destino',
    'quem recebeu',
    'favorecido',
    'recebedor',
    'beneficiario',
  ];

  static const _sourceLabels = ['origem', 'quem pagou', 'pagador', 'remetente'];

  static const _institutionLabels = ['instituicao', 'instituição', 'banco'];

  static const _bankDataLabels = [
    'agencia',
    'agência',
    'account',
    'numero da account',
    'ispb',
  ];
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
