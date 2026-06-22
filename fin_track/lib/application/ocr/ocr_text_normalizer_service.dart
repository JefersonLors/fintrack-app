import '../../domain/value_objects/ocr_result.dart';
import 'ocr_geometry_normalizer.dart';
import 'normalized_ocr_text.dart';

class OcrTextNormalizerService {
  OcrTextNormalizerService({
    OcrGeometryNormalizer geometryNormalizer = const OcrGeometryNormalizer(),
  }) : _geometryNormalizer = geometryNormalizer;

  final OcrGeometryNormalizer _geometryNormalizer;

  NormalizedOcrText normalize(String text) {
    return _normalizeText(text);
  }

  NormalizedOcrText normalizeResult(OcrResult result) {
    return _normalizeText(
      result.text,
      geometry: _geometryNormalizer.normalize(result),
    );
  }

  NormalizedOcrText _normalizeText(
    String text, {
    NormalizedOcrGeometry? geometry,
  }) {
    final original = text;
    var normalized = _normalizeBasicUnicode(text)
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[“”„]'), '"')
        .replaceAll(RegExp(r"[‘’`´]"), "'")
        .replaceAll(RegExp(r'[–—−]'), '-')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll('Instituiçáo', 'Instituição')
        .replaceAll('Instituiçăo', 'Instituição')
        .replaceAll('Instituicáo', 'Instituicao')
        .replaceAll('Instituicao', 'Instituição')
        .replaceAll('LỤCIA', 'LUCIA')
        .replaceAll('LúCIA', 'LUCIA')
        .replaceAll(RegExp(r'\bR\s*\$\s*', caseSensitive: false), 'R\$ ')
        .replaceAll(RegExp(r'\bR[S§]\s+', caseSensitive: false), 'R\$ ')
        .replaceAll(RegExp(r'\bR[S§](?=\d)', caseSensitive: false), 'R\$ ');

    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_isKnownNoise(line))
        .toList(growable: false);

    normalized = lines.join('\n');
    return NormalizedOcrText(
      original: original.trim(),
      normalized: normalized,
      lines: lines,
      geometry: geometry,
    );
  }

  bool _isKnownNoise(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('me ajuda') ||
        lower.startsWith('estamos aqui para ajudar') ||
        lower.startsWith('ouvidoria:') ||
        lower.contains('nubank.com.br/contatos');
  }

  String _normalizeBasicUnicode(String text) {
    const substitutions = <String, String>{
      'á': 'á',
      'à': 'à',
      'â': 'â',
      'ä': 'ã',
      'ă': 'ã',
      'Á': 'Á',
      'À': 'À',
      'Â': 'Â',
      'Ä': 'Ã',
      'Ă': 'Ã',
      'ẹ': 'e',
      'Ẹ': 'E',
      'ị': 'i',
      'Ị': 'I',
      'ọ': 'o',
      'Ọ': 'O',
      'ụ': 'u',
      'Ụ': 'U',
      'ç': 'ç',
      'Ç': 'Ç',
      'ſ': 's',
      '§': 'S',
      'º': 'o',
      'ª': 'a',
    };
    var result = text;
    for (final entry in substitutions.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
