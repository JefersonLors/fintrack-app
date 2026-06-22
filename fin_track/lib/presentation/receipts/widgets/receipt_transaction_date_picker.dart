import 'package:flutter/material.dart';

Future<DateTime?> selectReceiptTransactionDate(
  BuildContext context, {
  DateTime? initialDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 5, 12, 31),
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    helpText: 'Selecionar data da transação',
    cancelText: 'Cancelar',
    confirmText: 'Confirmar',
    errorFormatText: 'Data inválida',
    errorInvalidText: 'Data fora do intervalo permitido',
  );
}
