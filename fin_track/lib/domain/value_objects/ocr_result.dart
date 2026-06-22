class OcrResult {
  const OcrResult({
    required this.text,
    required this.confidence,
    required this.provider,
    this.blocks = const <OcrBlock>[],
    this.lines = const <OcrLine>[],
    this.elements = const <OcrElement>[],
  });

  static const double acceptableConfidenceThreshold = 0.74;

  final String text;
  final double confidence;
  final String provider;
  final List<OcrBlock> blocks;
  final List<OcrLine> lines;
  final List<OcrElement> elements;
}

class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.index,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int index;
}

class OcrLine {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.blockIndex,
    required this.lineIndex,
    this.confidence,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int blockIndex;
  final int lineIndex;
  final double? confidence;
}

class OcrElement {
  const OcrElement({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.blockIndex,
    required this.lineIndex,
    required this.elementIndex,
    this.confidence,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int blockIndex;
  final int lineIndex;
  final int elementIndex;
  final double? confidence;
}
