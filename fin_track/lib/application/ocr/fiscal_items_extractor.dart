import '../../domain/utils/ocr_parser_utils.dart';
import 'normalized_ocr_text.dart';

class FiscalItemsExtractor {
  const FiscalItemsExtractor();

  List<String> extractFromGeometry(NormalizedOcrGeometry? geometry) {
    if (geometry == null || geometry.isEmpty) {
      return const <String>[];
    }
    final start = geometry.bands.indexWhere((band) {
      final text = normalizeSearch(band.text);
      return text.contains('descricao') || text.contains('itens');
    });
    if (start < 0) {
      return const <String>[];
    }

    final items = <String>[];
    for (var i = start + 1; i < geometry.bands.length; i++) {
      final bandText = geometry.bands[i].text.trim();
      final normalizedLine = normalizeSearch(bandText);
      if (_itemsBlockEnd(normalizedLine)) {
        break;
      }
      final item = _cleanItem(bandText);
      if (item != null) {
        items.add(item);
      }
    }
    return items.toSet().take(12).toList();
  }

  List<String> extractFromLines(List<String> lines) {
    final start = lines.indexWhere((line) {
      final text = normalizeSearch(line);
      return text.contains('descricao') || text.contains('itens');
    });
    if (start < 0) {
      return const <String>[];
    }

    final items = <String>[];
    final initialLine = lines[start];
    if (normalizeSearch(initialLine).contains('itens') &&
        initialLine.contains(':')) {
      final inline = initialLine.split(':').skip(1).join(':');
      items.addAll(_inlineItems(inline));
    }
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      final normalizedLine = normalizeSearch(line);
      if (_itemsBlockEnd(normalizedLine)) {
        break;
      }
      final item = _cleanItem(line);
      if (item != null) {
        items.add(item);
      }
    }
    return items.toSet().take(12).toList();
  }

  List<String> _inlineItems(String text) {
    return text
        .split(RegExp(r'[,;]'))
        .map(_cleanItem)
        .whereType<String>()
        .toList();
  }

  bool _itemsBlockEnd(String line) {
    return containsAny(line, [
      'qtd total',
      'qtde total',
      'valor total',
      'valor final',
      'valor pago',
      'forma pagamento',
      'pagamento',
      'consulte',
      'chave de acesso',
      'protocolo',
      'emissao',
      'tributos',
      'fonte',
    ]);
  }

  String? _cleanItem(String line) {
    var text = line.trim();
    if (text.length < 3) return null;
    final normalized = normalizeSearch(text);
    if (RegExp(r'^[\d\s.,:/\-*|$x]+$', caseSensitive: false).hasMatch(text)) {
      return null;
    }
    if (containsAny(normalized, [
          'codigo',
          'cod ',
          'descricao',
          'vl.unit',
          'vl unit',
          'qtd',
          'total',
          'un x',
        ]) &&
        !RegExp(r'[a-zA-ZÀ-ÿ]{4,}').hasMatch(text)) {
      return null;
    }

    text = text
        .replaceFirst(RegExp(r'^\d{1,14}\s+'), '')
        .replaceAll(RegExp(r'\b\d+[,.]\d{2}\b.*$'), '')
        .replaceAll(
          RegExp(r'\b\d+(?:[,.]\d+)?\s*(kg|un|x)\b.*$', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\b(t\d{2}|st|f)\b$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    text = text.replaceAll(RegExp(r'\bUN\b$', caseSensitive: false), '').trim();
    if (text.length < 3 || !RegExp(r'[a-zA-ZÀ-ÿ]{3,}').hasMatch(text)) {
      return null;
    }
    return text;
  }
}
