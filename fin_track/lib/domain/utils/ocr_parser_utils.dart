import '../value_objects/receipt_payment_method.dart';
import 'cnpj_extractor.dart';

String normalizeSearch(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

bool containsAny(String text, List<String> terms) {
  final normalized = normalizeSearch(text);
  return terms.any((term) => normalized.contains(normalizeSearch(term)));
}

int countOccurrences(String text, List<String> terms) {
  final normalized = normalizeSearch(text);
  var total = 0;
  for (final term in terms) {
    if (normalized.contains(normalizeSearch(term))) {
      total++;
    }
  }
  return total;
}

double scoreDocumentConfidence({
  required bool hasAmount,
  required bool hasDate,
  required bool hasStrongSignal,
  required bool hasParticipant,
  required bool hasPaymentMethod,
  required bool hasIdentifier,
}) {
  var score = 0.0;
  if (hasAmount) score += 0.25;
  if (hasDate) score += 0.20;
  if (hasStrongSignal) score += 0.20;
  if (hasParticipant) score += 0.15;
  if (hasPaymentMethod) score += 0.10;
  if (hasIdentifier) score += 0.10;
  return score.clamp(0, 1);
}

double? fieldConfidence(Object? amount, double score, double fieldWeight) {
  if (amount == null) {
    return null;
  }
  return (score + fieldWeight).clamp(0.35, 1).toDouble();
}

double? parseCurrency(String raw) {
  final match = RegExp(
    r'(\d{1,3}(?:[.\s]\d{3})*(?:,\d{2})?|\d+(?:,\d{2})?)',
  ).firstMatch(raw);
  if (match == null) {
    return null;
  }
  final clean = match
      .group(1)!
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll(RegExp(r'\.(?=\d{3})'), '')
      .replaceAll(',', '.');
  return double.tryParse(clean);
}

double? extractLargestAmount(String text) {
  final amounts =
      RegExp(
            r'(?:R\$\s*)?(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2})',
            caseSensitive: false,
          )
          .allMatches(text)
          .map((match) => parseCurrency(match.group(0)!))
          .whereType<double>()
          .where((amount) => amount > 0)
          .toList();
  if (amounts.isEmpty) {
    return null;
  }
  return amounts.reduce((a, b) => a > b ? a : b);
}

String? extractValidCnpj(String text) {
  return const CnpjExtractor().extractFirstValid(text);
}

DateTime? parseNumericDate(String text) {
  final createdAt = RegExp(
    r'(?:^|[^\d])([0-3]?\d)\s*[/\-.]\s*([01]?\d)\s*[/\-.]\s*(\d{2}|\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?',
  ).firstMatch(text);
  if (createdAt != null) {
    return _createValidatedDate(
      day: int.parse(createdAt.group(1)!),
      month: int.parse(createdAt.group(2)!),
      year: _fullYear(createdAt.group(3)!),
      hour: int.parse(createdAt.group(4)!),
      minute: int.parse(createdAt.group(5)!),
      second: int.tryParse(createdAt.group(6) ?? '0') ?? 0,
    );
  }

  final br = RegExp(
    r'(?:^|[^\d])([0-3]?\d)\s*[/\-.]\s*([01]?\d)\s*[/\-.]\s*(\d{2}|\d{4})(?!\d)',
  ).firstMatch(text);
  if (br != null) {
    return _createValidatedDate(
      day: int.parse(br.group(1)!),
      month: int.parse(br.group(2)!),
      year: _fullYear(br.group(3)!),
    );
  }

  final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (iso != null) {
    return DateTime.tryParse(iso.group(0)!);
  }

  return null;
}

DateTime? parseOcrDate(String text) {
  return parseNumericDate(text) ?? parseTextualDate(text);
}

DateTime? parseTextualDate(String text) {
  final normalized = normalizeSearch(
    text
        .replaceAll(RegExp(r'[,.]'), ' ')
        .replaceAll(RegExp(r'\b[aà]s\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bde\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' '),
  );

  final textual = RegExp(
    r'(?:^|[^\d])([0-3]?\d)\s+'
    r'(jan(?:eiro)?|fev(?:ereiro)?|mar(?:co|ço)?|abr(?:il)?|mai(?:o)?|'
    r'jun(?:ho)?|jul(?:ho)?|ago(?:sto)?|set(?:embro)?|out(?:ubro)?|'
    r'nov(?:embro)?|dez(?:embro)?)\s+'
    r'(\d{4}|\d{2})(?!\d)'
    r'(?:[\s-]+(?:[aà]s\s*)?(\d{1,2})[:h](\d{2})(?::(\d{2}))?)?',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (textual != null) {
    final month = _monthByName(textual.group(2)!);
    if (month == null) {
      return null;
    }
    return _createValidatedDate(
      day: int.parse(textual.group(1)!),
      month: month,
      year: _fullYear(textual.group(3)!),
      hour: int.tryParse(textual.group(4) ?? '0') ?? 0,
      minute: int.tryParse(textual.group(5) ?? '0') ?? 0,
      second: int.tryParse(textual.group(6) ?? '0') ?? 0,
    );
  }

  final textualComSeparador = RegExp(
    r'(?:^|[^\d])([0-3]?\d)\s*[/\-.]\s*'
    r'(jan(?:eiro)?|fev(?:ereiro)?|mar(?:co|ço)?|abr(?:il)?|mai(?:o)?|'
    r'jun(?:ho)?|jul(?:ho)?|ago(?:sto)?|set(?:embro)?|out(?:ubro)?|'
    r'nov(?:embro)?|dez(?:embro)?)\s*[/\-.]\s*'
    r'(\d{4}|\d{2})(?!\d)'
    r'(?:[\s-]+(\d{1,2})[:h](\d{2})(?::(\d{2}))?)?',
    caseSensitive: false,
  ).firstMatch(normalized);
  if (textualComSeparador == null) {
    return null;
  }
  final month = _monthByName(textualComSeparador.group(2)!);
  if (month == null) {
    return null;
  }
  return _createValidatedDate(
    day: int.parse(textualComSeparador.group(1)!),
    month: month,
    year: _fullYear(textualComSeparador.group(3)!),
    hour: int.tryParse(textualComSeparador.group(4) ?? '0') ?? 0,
    minute: int.tryParse(textualComSeparador.group(5) ?? '0') ?? 0,
    second: int.tryParse(textualComSeparador.group(6) ?? '0') ?? 0,
  );
}

DateTime? _createValidatedDate({
  required int day,
  required int month,
  required int year,
  int hour = 0,
  int minute = 0,
  int second = 0,
}) {
  if (year < 2000 || year > 2099) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second > 59) {
    return null;
  }
  final date = DateTime(year, month, day, hour, minute, second);
  if (date.year != year ||
      date.month != month ||
      date.day != day ||
      date.hour != hour ||
      date.minute != minute ||
      date.second != second) {
    return null;
  }
  return date;
}

DateTime? parseDateWithAbbreviatedMonth(String text) {
  return parseTextualDate(text);
}

String? firstMatchingLine(List<String> lines, RegExp regex) {
  for (final line in lines) {
    if (regex.hasMatch(line)) {
      return line;
    }
  }
  return null;
}

String? bestNameLine(List<String> lines) {
  final noise = RegExp(
    r'^(amount|total|data|hora|pagamento|receipt|nota fiscal|cupom|cnpj|cpf|doc|pos:|aut|nsu|terminal|via cliente|type|id da transa[cç][aã]o|e2e|origem|destino|name|institui[cç][aã]o|item|items|produto|produtos|pix|ted|debito|d[eé]bito|credito|cr[eé]dito)',
    caseSensitive: false,
  );
  final candidates = lines.where((line) {
    final text = line.trim();
    if (text.length < 3 || noise.hasMatch(normalizeSearch(text))) {
      return false;
    }
    if (RegExp(r'^[\d\s.,:/\-*|$]+$').hasMatch(text)) {
      return false;
    }
    if (_looksLikeFileName(text)) {
      return false;
    }
    if (text.contains('R\$')) {
      return false;
    }
    if (RegExp(
      r'^[A-Z]\d{10,}[A-Z0-9]*$',
      caseSensitive: false,
    ).hasMatch(text)) {
      return false;
    }
    final paymentMethod = ReceiptPaymentMethod.normalize(text);
    if (paymentMethod != null && paymentMethod != ReceiptPaymentMethod.other) {
      return false;
    }
    return RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(text);
  }).toList();
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((a, b) => _scoreName(b).compareTo(_scoreName(a)));
  return candidates.first;
}

double _scoreName(String line) {
  final uppercase = RegExp(r'[A-ZÀ-Ý]').allMatches(line).length;
  final letters = RegExp(r'[A-Za-zÀ-ÿ]').allMatches(line).length;
  final digits = RegExp(r'\d').allMatches(line).length;
  final separators = RegExp(r'[:;]').allMatches(line).length;
  return (letters == 0 ? 0 : uppercase / letters) * 2 +
      (line.length / 40).clamp(0, 1) -
      digits * 0.2 -
      separators * 0.5;
}

bool _looksLikeFileName(String text) {
  final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  return RegExp(
    r'^[a-z0-9_-]+\.(jpe?g|png|webp|heic|heif|pdf|txt)$',
  ).hasMatch(normalized);
}

int _fullYear(String raw) {
  final year = int.parse(raw);
  if (year < 100) {
    return 2000 + year;
  }
  return year;
}

int? _monthByName(String raw) {
  const months = {
    'jan': 1,
    'janeiro': 1,
    'fev': 2,
    'fevereiro': 2,
    'mar': 3,
    'marco': 3,
    'março': 3,
    'abr': 4,
    'abril': 4,
    'mai': 5,
    'maio': 5,
    'jun': 6,
    'junho': 6,
    'jul': 7,
    'julho': 7,
    'ago': 8,
    'agosto': 8,
    'set': 9,
    'setembro': 9,
    'out': 10,
    'outubro': 10,
    'nov': 11,
    'novembro': 11,
    'dez': 12,
    'dezembro': 12,
  };
  final normalized = normalizeSearch(
    raw,
  ).replaceAll(RegExp(r'[^a-z]'), '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return months[normalized] ??
      (normalized.length >= 3 ? months[normalized.substring(0, 3)] : null);
}
