import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'receipt_ocr_parser.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';

class FallbackReceiptParser implements ReceiptOcrParser {
  @override
  String get name => 'fallback';

  @override
  ReceiptType get targetType => ReceiptType.other;

  @override
  int get priority => -1;

  @override
  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final raw = text.normalized;
    final receiptType = _inferType(raw);
    final value = _extractAmount(raw);
    final date = parseOcrDate(raw);
    final establishment = bestNameLine(text.lines);
    final method = _extractPaymentMethod(raw);
    var score = scoreDocumentConfidence(
      hasAmount: value != null,
      hasDate: date != null,
      hasStrongSignal: receiptType != ReceiptType.other,
      hasParticipant: establishment != null,
      hasPaymentMethod: method != null,
      hasIdentifier: containsAny(raw, ['cpf', 'cnpj', 'doc', 'id']),
    );
    score = score.clamp(0.10, 0.55);

    return OcrParserResult(
      success: true,
      confidence: score,
      type: receiptType,
      parser: 'fallback',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        amount: value,
        transactionDate: date,
        establishment: establishment,
        paymentMethod: method,
        ocrConfidence: ocrConfidence.clamp(0, 1),
        valueConfidence: fieldConfidence(value, score, 0.25),
        dateConfidence: fieldConfidence(date, score, 0.20),
        establishmentConfidence: fieldConfidence(establishment, score, 0.15),
        paymentMethodConfidence: fieldConfidence(method, score, 0.10),
      ),
    );
  }

  double? _extractAmount(String text) {
    final labeled = RegExp(
      r'(?:amount(?:\s+da\s+transfer[eê]ncia)?|total(?:\s+pago)?|amount\s+cobrado|quantia)\s*:?\s*R?\$?\s*(\d{1,3}(?:[.\s]\d{3})*(?:,\d{2})?|\d+(?:,\d{2})?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) {
      final value = parseCurrency(labeled.group(1)!);
      if (value != null && value > 0) {
        return value;
      }
    }
    return extractLargestAmount(text);
  }

  String? _extractPaymentMethod(String text) {
    if (containsAny(text, ['pix'])) return 'Pix';
    return ReceiptPaymentMethod.normalize(text);
  }

  ReceiptType _inferType(String text) {
    if (containsAny(text, [
      'comprovante pix',
      'transferencia pix',
      'pix enviado',
      'pix recebido',
      'key pix',
    ])) {
      return ReceiptType.pixReceipt;
    }
    if (containsAny(text, [
      'nf-e',
      'nfe',
      'nota fiscal eletronica',
      'nota fiscal',
      'cupom fiscal',
      'danfe',
    ])) {
      return ReceiptType.invoice;
    }
    if (containsAny(text, ['pix'])) {
      return ReceiptType.pixReceipt;
    }
    if (containsAny(text, [
      'recibo',
      'recebemos',
      'comprovante de pagamento',
      'documento de pagamento',
    ])) {
      return ReceiptType.receipt;
    }
    return ReceiptType.other;
  }
}
