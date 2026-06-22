String? normalizeEstablishmentName(String? value) {
  final text = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text == null) {
    return null;
  }
  if (text.isEmpty) {
    return '';
  }
  if (_hasLowercase(text)) {
    return text;
  }

  final buffer = StringBuffer();
  final word = StringBuffer();

  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (_isWordSeparator(char)) {
      _writeNormalizedWord(buffer, word.toString());
      word.clear();
      buffer.write(char);
    } else {
      word.write(char);
    }
  }
  _writeNormalizedWord(buffer, word.toString());

  return buffer.toString();
}

void _writeNormalizedWord(StringBuffer buffer, String word) {
  if (word.isEmpty) {
    return;
  }
  if (_isShortAcronym(word)) {
    buffer.write(word.toUpperCase());
    return;
  }

  final lower = word.toLowerCase();
  buffer.write(lower[0].toUpperCase());
  if (lower.length > 1) {
    buffer.write(lower.substring(1));
  }
}

bool _isWordSeparator(String char) {
  return char.trim().isEmpty || char == '-' || char == '/' || char == '.';
}

bool _isShortAcronym(String word) {
  const acronyms = {'API', 'PIX', 'CPF', 'CNPJ', 'MEI', 'ME', 'EPP', 'SA'};
  return acronyms.contains(word.toUpperCase());
}

bool _hasLowercase(String text) {
  return RegExp(r'[a-zà-ÿ]').hasMatch(text);
}
