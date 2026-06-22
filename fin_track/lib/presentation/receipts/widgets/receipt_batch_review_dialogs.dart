import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';
import '../receipt_form_helpers.dart';

Future<bool> confirmDiscardBatch(BuildContext context) async {
  final exit = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar lote?'),
      content: const Text(
        'Os comprovantes ainda não confirmados serão perdidos.',
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Revisar'),
            ),
            FilledButton(
              style: destructiveFilledButtonStyle(context),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      ],
    ),
  );
  return exit == true;
}

Future<bool> confirmSaveWithPendingFields(
  BuildContext context,
  List<Receipt> receipts,
) async {
  final pendingFields = <String>{};
  for (final receipt in receipts) {
    pendingFields.addAll(receiptPendingFields(receipt));
  }
  if (pendingFields.isEmpty) {
    return true;
  }
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Salvar com campos incompletos?'),
      content: Text(
        'Os campos ${formatPendingFieldsList(pendingFields.toList())} estão vazios ou com valor padrão. Isso pode dificultar encontrar os comprovantes posteriormente.',
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Revisar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    ),
  );
  return confirm == true;
}
