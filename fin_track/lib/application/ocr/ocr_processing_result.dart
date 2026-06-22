import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';

class OcrProcessingResult {
  const OcrProcessingResult({
    required this.originalText,
    required this.normalizedText,
    required this.type,
    required this.extractedData,
    required this.ocrConfidence,
    required this.extractionConfidence,
    required this.parser,
  });

  final String originalText;
  final String normalizedText;
  final ReceiptType type;
  final ExtractedData extractedData;
  final double ocrConfidence;
  final double extractionConfidence;
  final String parser;
}
