import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'receipt_ocr_parser.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';

class GenericReceiptParser implements ReceiptOcrParser {
  @override
  String get name => 'generic_receipt';

  @override
  ReceiptType get targetType => ReceiptType.receipt;

  @override
  int get priority => 10;

  @override
  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final raw = text.normalized;
    final signals = countOccurrences(raw, [
      'recibo',
      'comprovante de pagamento',
      'recebido de',
      'pago a',
      'referente a',
      'assinatura',
    ]);
    if (signals == 0) {
      return _failure(ocrConfidence);
    }

    final value = extractLargestAmount(raw);
    final date = parseOcrDate(raw);
    final establishment = bestNameLine(text.lines);
    final method = ReceiptPaymentMethod.normalize(raw);
    final score = scoreDocumentConfidence(
      hasAmount: value != null,
      hasDate: date != null,
      hasStrongSignal: signals > 0,
      hasParticipant: establishment != null,
      hasPaymentMethod: method != null,
      hasIdentifier: containsAny(raw, ['cpf', 'cnpj', 'assinatura']),
    );

    return OcrParserResult(
      success: score >= 0.30,
      confidence: score,
      type: ReceiptType.receipt,
      parser: 'generic_receipt',
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

  OcrParserResult _failure(double ocrConfidence) {
    return OcrParserResult(
      success: false,
      confidence: 0,
      type: ReceiptType.other,
      parser: 'generic_receipt',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        ocrConfidence: ocrConfidence.clamp(0, 1),
      ),
    );
  }
}
