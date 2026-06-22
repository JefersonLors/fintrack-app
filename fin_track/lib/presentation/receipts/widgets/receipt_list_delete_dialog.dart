import 'package:flutter/material.dart';

import '../../widgets/app_scope.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';

Future<bool> confirmReceiptListSelectionDeletion(
  BuildContext context,
  int total,
) async {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(receiptsText.deleteSelectionTitleFor(total)),
      content: Text(receiptsText.deleteSelectionMessage),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(commonText.cancel),
            ),
            FilledButton.icon(
              style: destructiveFilledButtonStyle(context),
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(Icons.delete_outline),
              label: Text(commonText.delete),
            ),
          ],
        ),
      ],
    ),
  );
  return confirm == true;
}
