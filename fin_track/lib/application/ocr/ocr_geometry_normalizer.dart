import '../../domain/value_objects/ocr_result.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'normalized_ocr_text.dart';

class OcrGeometryNormalizer {
  const OcrGeometryNormalizer();

  NormalizedOcrGeometry? normalize(OcrResult result) {
    if (result.lines.isEmpty) {
      return null;
    }

    final lines =
        result.lines
            .where((line) => line.text.trim().isNotEmpty)
            .map(
              (line) => VisualOcrLine(
                text: line.text.trim(),
                left: line.left,
                top: line.top,
                right: line.right,
                bottom: line.bottom,
                blockIndex: line.blockIndex,
                lineIndex: line.lineIndex,
                inInstitutionBlock: _isInstitutionLine(line.text),
              ),
            )
            .toList()
          ..sort(_compararPosicao);

    if (lines.isEmpty) {
      return null;
    }

    return NormalizedOcrGeometry(
      lines: List.unmodifiable(lines),
      bands: List.unmodifiable(_groupBands(lines)),
    );
  }

  List<VisualOcrBand> _groupBands(List<VisualOcrLine> lines) {
    final bands = <List<VisualOcrLine>>[];
    for (final line in lines) {
      final band = bands.cast<List<VisualOcrLine>?>().firstWhere(
        (band) => band != null && _sameVisualBand(band, line),
        orElse: () => null,
      );
      if (band == null) {
        bands.add([line]);
      } else {
        band.add(line);
        band.sort((a, b) => a.left.compareTo(b.left));
      }
    }

    return bands.map((lines) => VisualOcrBand(lines: lines)).toList();
  }

  bool _sameVisualBand(List<VisualOcrLine> band, VisualOcrLine line) {
    final averageCenter =
        band.map((item) => item.centerY).reduce((a, b) => a + b) / band.length;
    final averageHeight =
        band.map((item) => item.bottom - item.top).reduce((a, b) => a + b) /
        band.length;
    final tolerance = (averageHeight * 0.70).clamp(6.0, 18.0);
    return (line.centerY - averageCenter).abs() <= tolerance;
  }

  int _compararPosicao(VisualOcrLine a, VisualOcrLine b) {
    final deltaTop = a.top - b.top;
    if (deltaTop.abs() > 6) {
      return deltaTop.sign.toInt();
    }
    return a.left.compareTo(b.left);
  }

  bool _isInstitutionLine(String text) {
    final normalized = normalizeSearch(text);
    return normalized.contains('instituicao') ||
        normalized.contains('banco') ||
        normalized.contains('agencia') ||
        normalized.contains('account') ||
        normalized.contains('ispb');
  }
}
