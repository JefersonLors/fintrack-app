import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'receipt_ocr_parser.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';
import 'fiscal_document_models.dart';
import 'fiscal_items_extractor.dart';

class FiscalDocumentParser implements ReceiptOcrParser {
  static final _nfceStrategy = NfceFiscalStrategy();
  static const _itemsExtractor = FiscalItemsExtractor();

  @override
  String get name => 'fiscal_document';

  @override
  ReceiptType get targetType => ReceiptType.invoice;

  @override
  int get priority => 95;

  @override
  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final raw = text.normalized;
    final codesText = codes.join('\n');
    final rawWithCodes = [raw, codesText].where((e) => e.isNotEmpty).join('\n');
    final accessKey = _accessKey(rawWithCodes);
    final keyData = accessKey == null ? null : _accessKeyData(accessKey);
    final geometry = text.geometry;
    final issuerCnpj =
        _issuerCnpjByGeometry(geometry) ?? _issuerCnpj(raw) ?? keyData?.cnpj;
    final urlQrCode = _urlQrCode(codes) ?? _fiscalUrlFromText(raw);
    final hasFiscalQr = _hasFiscalQr(codes);
    final signals = _nfceStrategy.scoreSignals(raw);
    final looksLikeNfce = _nfceStrategy.recognizes(
      text: raw,
      hasFiscalQr: hasFiscalQr,
      accessKey: accessKey,
    );
    if (!looksLikeNfce) {
      return _failure(ocrConfidence);
    }

    final value =
        _totalAmountByGeometry(geometry) ??
        _totalAmount(text.lines, raw) ??
        extractLargestAmount(raw);
    final date = _dateByGeometry(geometry) ?? parseOcrDate(raw);
    final establishment = _issuerByGeometry(geometry) ?? _issuer(text.lines);
    final items = _itemsExtractor.extractFromGeometry(geometry);
    final finalItems = items.isEmpty
        ? _itemsExtractor.extractFromLines(text.lines)
        : items;
    final method = ReceiptPaymentMethod.normalize(raw);
    final hasIdentifier =
        accessKey != null || containsAny(raw, ['cnpj', 'chave de acesso']);
    final score = scoreDocumentConfidence(
      hasAmount: value != null,
      hasDate: date != null,
      hasStrongSignal: signals >= 1 || hasFiscalQr || accessKey != null,
      hasParticipant: establishment != null,
      hasPaymentMethod: method != null,
      hasIdentifier: hasIdentifier,
    );

    return OcrParserResult(
      success: score >= 0.30,
      confidence: score,
      type: ReceiptType.invoice,
      parser: 'fiscal_document',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        amount: value,
        transactionDate: date,
        establishment: establishment,
        items: finalItems,
        paymentMethod: method,
        issuerCnpj: issuerCnpj,
        accessKey: accessKey,
        urlQrCode: urlQrCode,
        documentNumber: keyData?.number,
        documentSeries: keyData?.series,
        documentState: keyData?.state,
        ocrConfidence: ocrConfidence.clamp(0, 1),
        valueConfidence: fieldConfidence(value, score, 0.25),
        dateConfidence: fieldConfidence(date, score, 0.20),
        establishmentConfidence: fieldConfidence(establishment, score, 0.15),
        paymentMethodConfidence: fieldConfidence(method, score, 0.10),
      ),
    );
  }

  OcrParserResult _failure(double ocrConfidence) {
    return OcrParserResult(
      success: false,
      confidence: 0,
      type: ReceiptType.other,
      parser: 'fiscal_document',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        ocrConfidence: ocrConfidence.clamp(0, 1),
      ),
    );
  }

  double? _totalAmount(List<String> lines, String text) {
    final candidates = <FiscalAmount>[];
    final currencyPattern = RegExp(
      r'(?:R\s*\$?\s*)?(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2})',
      caseSensitive: false,
    );
    final strongLabel = RegExp(
      r'valor\s+(?:total|final|pago)|total\s+(?:r?\$|pago|da\s+nota)|vl\.?\s*total',
      caseSensitive: false,
    );
    final negativeLabel = RegExp(
      r'unit|unita|vl\.?\s*unit|trib|aprox|troco|desc|desconto|subtotal',
      caseSensitive: false,
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = normalizeSearch(line);
      final hasStrongLabel = strongLabel.hasMatch(normalizedLine);
      final hasNegativeLabel = negativeLabel.hasMatch(normalizedLine);

      for (final match in currencyPattern.allMatches(line)) {
        final value = parseCurrency(match.group(0)!);
        if (value == null || value <= 0) continue;
        var score = 0.0;
        if (hasStrongLabel) score += 8;
        if (normalizedLine.contains('valor pago')) score += 6;
        if (normalizedLine.contains('valor final')) score += 5;
        if (normalizedLine.contains('valor total')) score += 5;
        if (normalizedLine.contains('total')) score += 3;
        if (hasNegativeLabel) score -= 5;
        score += (i / lines.length).clamp(0, 1) * 0.5;
        candidates.add(FiscalAmount(value, score));
      }

      if (hasStrongLabel && i + 1 < lines.length) {
        for (final match in currencyPattern.allMatches(lines[i + 1])) {
          final value = parseCurrency(match.group(0)!);
          if (value != null && value > 0) {
            candidates.add(FiscalAmount(value, 7));
          }
        }
      }
    }

    if (candidates.isEmpty) {
      final match = RegExp(
        r'(?:amount\s+(?:total|final|pago)|total\s+pago|total)\s*'
        r'(?:\(?r?\$?\)?\s*){0,2}'
        r'(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2})',
        caseSensitive: false,
      ).firstMatch(text);
      return match == null ? null : parseCurrency(match.group(1)!);
    }

    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.amount.compareTo(a.amount);
    });
    if (candidates.first.score > 0) {
      return candidates.first.amount;
    }
    return extractLargestAmount(text);
  }

  double? _totalAmountByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'valor total',
      'total',
      'total pago',
      'valor final',
      'valor pago',
      'vl total',
    ], ignoreInstitutionBlocks: false);
    return value == null ? null : parseCurrency(value);
  }

  DateTime? _dateByGeometry(NormalizedOcrGeometry? geometry) {
    final date = geometry?.nearbyValue(const [
      'emissao',
      'data de emissao',
      'data',
      'data/hora',
    ], ignoreInstitutionBlocks: false);
    return date == null ? null : parseOcrDate(date);
  }

  String? _issuerCnpjByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'cnpj',
      'cnpj emitente',
    ], ignoreInstitutionBlocks: false);
    return value == null ? null : extractValidCnpj(value);
  }

  String? _issuerByGeometry(NormalizedOcrGeometry? geometry) {
    final issuer = geometry?.nearbyValue(const [
      'emitente',
      'razao social',
      'nome fantasia',
    ], ignoreInstitutionBlocks: false);
    if (issuer != null) {
      return bestNameLine([issuer]);
    }

    final cnpjIndex =
        geometry?.lines.indexWhere(
          (line) => extractValidCnpj(line.text) != null,
        ) ??
        -1;
    if (geometry == null || cnpjIndex <= 0) {
      return null;
    }
    final candidates = geometry.lines
        .take(cnpjIndex)
        .map((line) => line.text)
        .where(_looksLikeIssuerName)
        .toList();
    return bestNameLine(candidates);
  }

  String? _issuer(List<String> lines) {
    final cnpjIndex = lines.indexWhere(
      (line) => RegExp(
        r'cnpj|cnp3|\d{2}\.?\s*\d{3}\.?\s*\d{3}/?\s*\d{4}-?\s*\d{2}',
        caseSensitive: false,
      ).hasMatch(line),
    );
    if (cnpjIndex >= 0) {
      final nameOnSameLine = _nameBeforeCnpj(lines[cnpjIndex]);
      if (nameOnSameLine != null) {
        return nameOnSameLine;
      }
    }
    if (cnpjIndex > 0) {
      final beforeCnpj = lines
          .take(cnpjIndex)
          .where(_looksLikeIssuerName)
          .toList();
      final candidate = bestNameLine(beforeCnpj);
      if (candidate != null) {
        return candidate;
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = normalizeSearch(lines[i]);
      if (line.contains('emitente')) {
        for (var j = i + 1; j < lines.length && j <= i + 4; j++) {
          final candidate = bestNameLine([lines[j]]);
          if (candidate != null) {
            return candidate;
          }
        }
      }
    }
    return bestNameLine(lines.take(10).toList());
  }

  String? _nameBeforeCnpj(String line) {
    final parts = line.split(RegExp(r'cnpj|cnp3', caseSensitive: false));
    if (parts.isEmpty) {
      return null;
    }
    final text = parts.first
        .replaceAll(RegExp(r'[-:]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!_looksLikeIssuerName(text)) {
      return null;
    }
    return bestNameLine([text]);
  }

  bool _looksLikeIssuerName(String line) {
    final text = normalizeSearch(line.trim());
    if (text.length < 3) return false;
    if (RegExp(r'^[\d\s.,:/\-*|$]+$').hasMatch(text)) return false;
    if (containsAny(text, [
      'emitida',
      'contingencia',
      'nfc-e',
      'nf-e',
      'documento auxiliar',
      'nota fiscal',
      'consumidor',
      'avenida',
      'av.',
      ' rua ',
      'fone',
      'telefone',
      'cnpj',
      'inscricao estadual',
      ' i.e',
      'salvador',
      'brotas',
    ])) {
      return false;
    }
    return RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(line);
  }

  bool _hasFiscalQr(List<String> codes) {
    return codes.any(
      (code) => containsAny(code, [
        'nfce',
        'nfe',
        'sefaz',
        'chave',
        'chNFe',
        'consulta',
      ]),
    );
  }

  String? _accessKey(String text) {
    final match = RegExp(r'(?<!\d)(?:\d[ .-]?){44}(?!\d)').firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'\D'), '');
  }

  String? _issuerCnpj(String text) {
    return extractValidCnpj(text);
  }

  String? _urlQrCode(List<String> codes) {
    for (final code in codes) {
      final text = code.trim();
      final url = RegExp(
        r'(https?://[^\s|]+|www\.[^\s|]+)',
        caseSensitive: false,
      ).firstMatch(text)?.group(1);
      if (url == null || url.isEmpty) {
        continue;
      }
      final normalizedLine =
          RegExp(r'^https?://', caseSensitive: false).hasMatch(url)
          ? url
          : 'https://$url';
      if (containsAny(normalizedLine, ['sefaz', 'nfce', 'nfe', 'qrcode'])) {
        return normalizedLine;
      }
    }
    return null;
  }

  String? _fiscalUrlFromText(String text) {
    final matches = RegExp(
      r'(https?://[^\s|]+|www\.[^\s|]+)',
      caseSensitive: false,
    ).allMatches(text);
    for (final match in matches) {
      final raw = match.group(1);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final normalizedLine =
          RegExp(r'^https?://', caseSensitive: false).hasMatch(raw)
          ? raw
          : 'https://$raw';
      if (containsAny(normalizedLine, ['sefaz', 'nfce', 'nfe', 'qrcode'])) {
        return normalizedLine;
      }
    }
    return null;
  }

  AccessKeyData? _accessKeyData(String key) {
    if (!RegExp(r'^\d{44}$').hasMatch(key)) {
      return null;
    }
    return AccessKeyData.fromKey(key);
  }
}
