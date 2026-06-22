import 'package:flutter/services.dart';

class CurrencyMaskInputFormatter extends TextInputFormatter {
  const CurrencyMaskInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text, maxLength: maxDigits);
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }

    final cents = int.parse(digits);
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    final formatted =
        '${_formatThousands(reais)},'
        '${centavos.toString().padLeft(2, '0')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _onlyDigits(String text, {required int maxLength}) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.length <= maxLength ? digits : digits.substring(0, maxLength);
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
