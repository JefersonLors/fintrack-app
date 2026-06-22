import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/infrastructure/i_ocr_service.dart';
import '../../domain/value_objects/ocr_result.dart';
import '../diagnostics/error_handling.dart';

class GoogleMLKitService implements IOCRService {
  @override
  Future<OcrResult> process(File file) async {
    if (_isTextFile(file)) {
      final text = (await file.readAsString()).trim();
      return OcrResult(
        text: text,
        confidence: _calculateConfidence(text),
        provider: 'text_plain',
      );
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(file);
      final recognized = await recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      final geometry = _extractGeometry(recognized);

      return OcrResult(
        text: text,
        confidence: _calculateConfidence(text),
        provider: 'google_mlkit_text_recognition:on_device',
        blocks: geometry.blocks,
        lines: geometry.lines,
        elements: geometry.elements,
      );
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha no OCR nativo ML Kit',
      );
      return const OcrResult(
        text: '',
        confidence: 0.0,
        provider: 'google_mlkit_text_recognition:on_device',
      );
    } finally {
      await recognizer.close();
    }
  }

  double _calculateConfidence(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return 0.0;

    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final totalCharacters = normalized.length;
    final usefulCharacters = RegExp(
      r'[A-Za-zÀ-ÖØ-öø-ÿ0-9$%/:.,\-\s]',
    ).allMatches(normalized).length;
    final alphanumericCharacters = RegExp(
      r'[A-Za-zÀ-ÖØ-öø-ÿ0-9]',
    ).allMatches(normalized).length;
    final noiseCharacters = RegExp(
      r'[^A-Za-zÀ-ÖØ-öø-ÿ0-9$%/:.,\-\s]',
    ).allMatches(normalized).length;
    final usefulRatio = usefulCharacters / totalCharacters;
    final alphanumericRatio = alphanumericCharacters / totalCharacters;
    final noiseRatio = noiseCharacters / totalCharacters;

    final hasAmount = RegExp(
      r'(r\$\s*)?\d+[,.]\d{2}',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasDate = RegExp(
      r'\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2}',
    ).hasMatch(normalized);
    final hasCnpj = RegExp(
      r'\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}',
    ).hasMatch(normalized);
    final hasFiscalKey = RegExp(
      r'\d{44}',
    ).hasMatch(normalized.replaceAll(RegExp(r'\D'), ''));
    final hasFiscalMarker = RegExp(
      r'\b(nf-?c?e|cupom|nota fiscal|danfe|sat|emitente|cnpj)\b',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasPaymentMethod = RegExp(
      r'\b(pix|cart[aã]o|d[eé]bito|cr[eé]dito|cash|ted|doc|boleto)\b',
      caseSensitive: false,
    ).hasMatch(normalized);

    final lengthScore = (totalCharacters / 240).clamp(0.0, 1.0);
    final linesScore = (lines.length / 8).clamp(0.0, 1.0);
    final fragmentation = lines.isEmpty
        ? 1.0
        : lines.where((line) => line.length <= 3).length / lines.length;

    var score = 0.18;
    score += usefulRatio * 0.20;
    score += alphanumericRatio * 0.14;
    score += lengthScore * 0.10;
    score += linesScore * 0.08;

    if (hasAmount) score += 0.12;
    if (hasDate) score += 0.11;
    if (hasCnpj) score += 0.09;
    if (hasFiscalKey) score += 0.08;
    if (hasFiscalMarker) score += 0.08;
    if (hasPaymentMethod) score += 0.06;

    score -= noiseRatio * 0.45;
    score -= fragmentation * 0.10;
    if (totalCharacters < 24) score -= 0.18;
    if (lines.length <= 1 && totalCharacters < 80) score -= 0.08;

    return score.clamp(0.05, 0.95);
  }

  bool _isTextFile(File file) {
    return file.path.toLowerCase().endsWith('.txt');
  }

  _OcrGeometry _extractGeometry(RecognizedText recognized) {
    final blocks = <OcrBlock>[];
    final lines = <OcrLine>[];
    final elements = <OcrElement>[];

    for (
      var blockIndex = 0;
      blockIndex < recognized.blocks.length;
      blockIndex++
    ) {
      final block = recognized.blocks[blockIndex];
      final blockRect = block.boundingBox;
      blocks.add(
        OcrBlock(
          text: block.text.trim(),
          left: blockRect.left,
          top: blockRect.top,
          right: blockRect.right,
          bottom: blockRect.bottom,
          index: blockIndex,
        ),
      );

      for (var lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];
        final lineRect = line.boundingBox;
        lines.add(
          OcrLine(
            text: line.text.trim(),
            left: lineRect.left,
            top: lineRect.top,
            right: lineRect.right,
            bottom: lineRect.bottom,
            blockIndex: blockIndex,
            lineIndex: lineIndex,
            confidence: line.confidence,
          ),
        );

        for (
          var elementIndex = 0;
          elementIndex < line.elements.length;
          elementIndex++
        ) {
          final element = line.elements[elementIndex];
          final elementRect = element.boundingBox;
          elements.add(
            OcrElement(
              text: element.text.trim(),
              left: elementRect.left,
              top: elementRect.top,
              right: elementRect.right,
              bottom: elementRect.bottom,
              blockIndex: blockIndex,
              lineIndex: lineIndex,
              elementIndex: elementIndex,
              confidence: element.confidence,
            ),
          );
        }
      }
    }

    return _OcrGeometry(
      blocks: List.unmodifiable(blocks),
      lines: List.unmodifiable(lines),
      elements: List.unmodifiable(elements),
    );
  }
}

class _OcrGeometry {
  const _OcrGeometry({
    required this.blocks,
    required this.lines,
    required this.elements,
  });

  final List<OcrBlock> blocks;
  final List<OcrLine> lines;
  final List<OcrElement> elements;
}
