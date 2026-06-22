import '../../domain/entities/receipt.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';

abstract class ReceiptExtractionStrategy {
  String get name;
  ReceiptType get targetType;
  int get priority;

  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  });
}

abstract class ReceiptOcrParser implements ReceiptExtractionStrategy {}
