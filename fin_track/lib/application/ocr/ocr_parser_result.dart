import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';

class OcrParserResult {
  const OcrParserResult({
    required this.success,
    required this.confidence,
    required this.type,
    required this.data,
    required this.parser,
  });

  final bool success;
  final double confidence;
  final ReceiptType type;
  final ExtractedData data;
  final String parser;
}
