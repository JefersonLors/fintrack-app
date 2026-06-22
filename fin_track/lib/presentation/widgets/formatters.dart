import 'package:flutter/material.dart';

String formatCurrency(double? amount) {
  if (amount == null) {
    return 'R\$ --';
  }
  final cents = (amount.abs() * 100).round();
  final reais = cents ~/ 100;
  final remainingCents = cents % 100;
  final sign = amount < 0 ? '-' : '';
  return '${sign}R\$ ${_formatThousands(reais)},'
      '${remainingCents.toString().padLeft(2, '0')}';
}

String formatCurrencyForSpeech(double? amount) {
  if (amount == null) {
    return 'valor não identificado';
  }
  final cents = (amount.abs() * 100).round();
  final reais = cents ~/ 100;
  final remainingCents = cents % 100;
  final sign = amount < 0 ? 'menos ' : '';
  final reaisLabel = reais == 1 ? 'real' : 'reais';
  if (remainingCents == 0) {
    return '$sign$reais $reaisLabel';
  }
  final centsLabel = remainingCents == 1 ? 'centavo' : 'centavos';
  return '$sign$reais $reaisLabel e $remainingCents $centsLabel';
}

String _formatThousands(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final remaining = raw.length - index;
    buffer.write(raw[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

String formatDate(DateTime? date) {
  if (date == null) {
    return '--/--/----';
  }
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatDateTime(DateTime date) {
  return '${formatDate(date)} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

Color confidenceColor(BuildContext context, double? confidence) {
  final scheme = Theme.of(context).colorScheme;
  if ((confidence ?? 0) < 0.74) {
    return scheme.error;
  }
  return scheme.primary;
}
