part of 'data_extractor_service_test.dart';

Future<String> _fixture(String name) {
  return File('test/fixtures/ocr/$name').readAsString();
}

OcrResult _positionedOcrResult(List<_OcrLineFixture> lines) {
  return OcrResult(
    text: lines.map((line) => line.text).join('\n'),
    confidence: 0.90,
    provider: 'fixture_geometrico',
    lines: [
      for (var i = 0; i < lines.length; i++)
        OcrLine(
          text: lines[i].text,
          left: lines[i].left,
          top: lines[i].top,
          right: lines[i].left + lines[i].width,
          bottom: lines[i].top + 18,
          blockIndex: 0,
          lineIndex: i,
        ),
    ],
  );
}

_OcrLineFixture _line(
  String text,
  double left,
  double top, {
  double width = 180,
}) {
  return _OcrLineFixture(text, left, top, width);
}

class _OcrLineFixture {
  const _OcrLineFixture(this.text, this.left, this.top, this.width);

  final String text;
  final double left;
  final double top;
  final double width;
}
