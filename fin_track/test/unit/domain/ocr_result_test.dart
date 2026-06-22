import 'package:fin_track/domain/value_objects/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OCR result preserves block line and element geometry', () {
    const block = OcrBlock(
      text: 'Bloco',
      left: 1,
      top: 2,
      right: 3,
      bottom: 4,
      index: 5,
    );
    const line = OcrLine(
      text: 'Linha',
      left: 6,
      top: 7,
      right: 8,
      bottom: 9,
      blockIndex: 10,
      lineIndex: 11,
      confidence: 0.8,
    );
    const element = OcrElement(
      text: 'Elemento',
      left: 12,
      top: 13,
      right: 14,
      bottom: 15,
      blockIndex: 16,
      lineIndex: 17,
      elementIndex: 18,
      confidence: 0.9,
    );
    const result = OcrResult(
      text: 'text',
      confidence: OcrResult.acceptableConfidenceThreshold,
      provider: 'test',
      blocks: [block],
      lines: [line],
      elements: [element],
    );

    expect(result.text, 'text');
    expect(result.confidence, 0.74);
    expect(result.provider, 'test');
    expect(result.blocks.single.bottom, 4);
    expect(result.lines.single.confidence, 0.8);
    expect(result.elements.single.elementIndex, 18);
  });
}
