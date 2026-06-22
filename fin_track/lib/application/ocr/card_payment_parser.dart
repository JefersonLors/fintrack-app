import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import '../../domain/utils/cnpj_extractor.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'receipt_ocr_parser.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';

class CardPaymentParser implements ReceiptOcrParser {
  @override
  String get name => 'card_payment';

  @override
  ReceiptType get targetType => ReceiptType.receipt;

  @override
  int get priority => 90;

  @override
  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final raw = text.normalized;
    final looksLikeFiscalDocument = containsAny(raw, [
      'nf-e',
      'nfe',
      'nfc-e',
      'nota fiscal',
      'cupom fiscal',
      'danfe',
    ]);
    final hasCardStructure = containsAny(raw, [
      'via cliente',
      'via estabelecimento',
      'doc:',
      'aut:',
      'autorizacao',
      'nsu',
      'pos:',
      'terminal',
      'debito',
      'credito a vista',
      'mastercard',
      'visa',
      'elo',
      'amex',
    ]);
    if (looksLikeFiscalDocument && !hasCardStructure) {
      return _failure(ocrConfidence);
    }
    final signals = countOccurrences(raw, [
      'debito',
      'credito',
      'via cliente',
      'via estabelecimento',
      'doc:',
      'aut:',
      'autorizacao',
      'nsu',
      'pos:',
      'terminal',
      'cartao',
      'mastercard',
      'visa',
      'elo',
      'amex',
      'cnpj',
    ]);
    if (signals < 2) {
      return _failure(ocrConfidence);
    }

    final geometry = text.geometry;
    final value = _amountByGeometry(geometry) ?? extractLargestAmount(raw);
    final date = _dateByGeometry(geometry) ?? parseOcrDate(raw);
    final method = _paymentMethod(raw);
    final establishment =
        _establishmentByGeometry(geometry) ?? _establishment(text.lines);
    final cnpj = _cnpjByGeometry(geometry) ?? _merchantCnpj(text.lines, raw);
    final identifier = _identifierByGeometry(geometry);
    final hasIdentifier = containsAny(raw, [
      'doc:',
      'aut:',
      'autorizacao',
      'nsu',
      'pos:',
      'terminal',
      'cnpj',
    ]);
    var score = scoreDocumentConfidence(
      hasAmount: value != null,
      hasDate: date != null,
      hasStrongSignal: signals >= 2,
      hasParticipant: establishment != null,
      hasPaymentMethod: method != null,
      hasIdentifier: hasIdentifier,
    );
    if (containsAny(raw, ['cielo', 'stone', 'rede', 'getnet', 'pagseguro'])) {
      score += 0.05;
    }
    score = score.clamp(0, 1);

    return OcrParserResult(
      success: score >= 0.35,
      confidence: score,
      type: ReceiptType.receipt,
      parser: 'card_payment',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        amount: value,
        transactionDate: date,
        establishment: establishment,
        issuerCnpj: cnpj,
        documentNumber: identifier,
        paymentMethod: method,
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
      parser: 'card_payment',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        ocrConfidence: ocrConfidence.clamp(0, 1),
      ),
    );
  }

  String? _paymentMethod(String text) {
    if (containsAny(text, ['debito', 'débito'])) return 'Debito';
    if (containsAny(text, ['credito', 'crédito'])) return 'Credito';
    if (containsAny(text, ['prepago'])) return 'Prepago';
    return ReceiptPaymentMethod.normalize(text);
  }

  double? _amountByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'valor',
      'total',
      'valor pago',
      'valor da compra',
    ], ignoreInstitutionBlocks: true);
    return value == null ? null : parseCurrency(value);
  }

  DateTime? _dateByGeometry(NormalizedOcrGeometry? geometry) {
    final date = geometry?.nearbyValue(const [
      'data',
      'data/hora',
      'data da transacao',
      'data da compra',
    ], ignoreInstitutionBlocks: true);
    return date == null ? null : parseOcrDate(date);
  }

  String? _establishmentByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'estabelecimento',
      'lojista',
      'merchant',
      'nome fantasia',
    ], ignoreInstitutionBlocks: true);
    if (value == null || _isTechnicalOrIntermediaryLine(value)) {
      return null;
    }
    return bestNameLine([value]);
  }

  String? _cnpjByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'cnpj',
      'cpf/cnpj',
    ], ignoreInstitutionBlocks: true);
    return value == null ? null : extractValidCnpj(value);
  }

  String? _identifierByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'aut',
      'autorizacao',
      'codigo de autorizacao',
      'nsu',
      'doc',
    ], ignoreInstitutionBlocks: true);
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'[A-Z0-9]{4,}',
      caseSensitive: false,
    ).firstMatch(value);
    return match?.group(0);
  }

  String? _establishment(List<String> lines) {
    final byLabel = _valueAfterLabel(lines, const [
      'estabelecimento',
      'lojista',
      'merchant',
      'nome fantasia',
    ]);
    if (byLabel != null) {
      return byLabel;
    }

    final filtered = lines
        .where((line) {
          return !_isTechnicalOrIntermediaryLine(line);
        })
        .take(8)
        .toList();
    return bestNameLine(filtered);
  }

  String? _merchantCnpj(List<String> lines, String raw) {
    final merchantSection = _sectionAfterLabel(lines, const [
      'estabelecimento',
      'lojista',
      'merchant',
    ]);
    if (merchantSection != null) {
      final cnpj = extractValidCnpj(merchantSection);
      if (cnpj != null) {
        return cnpj;
      }
    }

    final result = const CnpjExtractor().extract(
      raw,
      context: CnpjDocumentContext.payment,
    );
    final best = result?.best;
    if (best == null) {
      return null;
    }
    if (best.source != CnpjSource.text || best.score >= 50) {
      return best.cnpj;
    }
    return null;
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
      final inline = line
          .replaceFirst(RegExp(label, caseSensitive: false), '')
          .replaceFirst(RegExp(r'[:\-]+'), '')
          .trim();
      final inlineName = bestNameLine([inline]);
      if (inlineName != null && !_isTechnicalOrIntermediaryLine(inlineName)) {
        return inlineName;
      }
      for (var j = i + 1; j < lines.length && j <= i + 5; j++) {
        if (_isTechnicalOrIntermediaryLine(lines[j])) {
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

  String? _sectionAfterLabel(List<String> lines, List<String> labels) {
    for (var i = 0; i < lines.length; i++) {
      final normalizedLine = normalizeSearch(lines[i]);
      if (!labels.any(
        (label) =>
            normalizedLine == label || normalizedLine.startsWith('$label '),
      )) {
        continue;
      }
      final end = (i + 7).clamp(0, lines.length);
      return lines.sublist(i, end).join('\n');
    }
    return null;
  }

  bool _isTechnicalOrIntermediaryLine(String line) {
    return containsAny(line, [
      'cielo',
      'stone',
      'rede',
      'getnet',
      'pagseguro',
      'adquirente',
      'instituicao',
      'banco emissor',
      'cnpj',
      'salvador',
      'via cliente',
      'debito',
      'credito',
      'doc:',
      'aut:',
      'autorizacao',
      'nsu',
      'pos:',
      'terminal',
    ]);
  }
}
