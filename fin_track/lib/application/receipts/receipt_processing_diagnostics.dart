part of 'receipt_processing_service.dart';

extension ReceiptProcessingDiagnostics on ReceiptProcessingService {
  double scoreOcrResult(String text, double confidence) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return confidence * 0.4;
    }
    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .length;
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
    final noise = RegExp(
      r'[^A-Za-zÀ-ÖØ-öø-ÿ0-9$%/:.,\-\s]',
    ).allMatches(normalized).length;

    var score = confidence * 55;
    score += (normalized.length / 18).clamp(0, 18);
    score += (lines / 2).clamp(0, 8);
    if (hasAmount) score += 8;
    if (hasDate) score += 7;
    if (hasCnpj) score += 8;
    if (hasFiscalKey) score += 10;
    score -= noise.clamp(0, 20) * 0.5;
    return score.clamp(0, 100).toDouble();
  }

  Map<String, Object?> ocrQualityMetadata(
    OcrImageQuality quality,
    OcrVariantResult bestOcr,
    List<OcrImageVariant> variants,
  ) {
    return <String, Object?>{
      ...quality.toJson(),
      'varianteEscolhida': bestOcr.variant.name,
      'scoreOcr': bestOcr.score,
      'ocrConfidence': bestOcr.result.confidence,
      'variantesTestadas': variants.map((variant) => variant.name).toList(),
      'textoHash': sha256.convert(utf8.encode(bestOcr.result.text)).toString(),
      'ocrEstruturadoLinhas': structuredOcrLines(bestOcr.result),
      'ocrEstruturadoResumo': structuredOcrSummary(bestOcr.result),
    };
  }

  List<String> structuredOcrLines(OcrResult result) {
    final lines = [...result.lines]
      ..sort((a, b) {
        final top = a.top.compareTo(b.top);
        if (top != 0) return top;
        return a.left.compareTo(b.left);
      });

    return lines
        .take(160)
        .map((line) {
          final text = line.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          return [
            'b${line.blockIndex}',
            'l${line.lineIndex}',
            'x${line.left.toStringAsFixed(0)}',
            'y${line.top.toStringAsFixed(0)}',
            'w${(line.right - line.left).toStringAsFixed(0)}',
            'h${(line.bottom - line.top).toStringAsFixed(0)}',
            text,
          ].join(' | ');
        })
        .toList(growable: false);
  }

  Map<String, Object?> structuredOcrSummary(OcrResult result) {
    return <String, Object?>{
      'blocos': result.blocks.length,
      'linhas': result.lines.length,
      'elementos': result.elements.length,
      'linhasPersistidas': result.lines.length.clamp(0, 160),
    };
  }

  Future<void> discardTemporaryVariants(List<OcrImageVariant> variants) async {
    for (final variant in variants) {
      if (!variant.temporary) {
        continue;
      }
      await ignoreCleanupFailure(() async {
        if (await variant.file.exists()) {
          await variant.file.delete();
        }
      });
    }
  }

  void validateFile(File file) {
    if (!file.existsSync()) {
      throw const FormatException('Arquivo não encontrado para importação.');
    }

    final size = file.lengthSync();
    const byteLimit = 15 * 1024 * 1024;
    if (size <= 0) {
      throw const FormatException('O arquivo selecionado está vazio.');
    }
    if (size > byteLimit) {
      throw const FormatException('O arquivo excede o limite de 15 MB.');
    }
  }
}
