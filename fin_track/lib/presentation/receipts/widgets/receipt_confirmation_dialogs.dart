import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';
import '../receipt_form_helpers.dart';

Future<bool> showReceiptPendingFieldsDialog(
  BuildContext context,
  Receipt receipt,
) async {
  final pendingFields = receiptPendingFields(receipt);
  if (pendingFields.isEmpty) {
    return true;
  }
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(receiptsText.pendingFieldsTitle),
      content: Text(
        receiptsText.pendingFieldsMessageFor(
          formatPendingFieldsList(pendingFields),
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(receiptsText.review),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(commonText.save),
            ),
          ],
        ),
      ],
    ),
  );
  return confirm == true;
}

Future<bool> showDiscardReceiptPreviewDialog(BuildContext context) async {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(receiptsText.discardTitle),
      content: Text(receiptsText.discardMessage),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(commonText.edit),
            ),
            FilledButton.icon(
              style: destructiveFilledButtonStyle(context),
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(Icons.delete_outline),
              label: Text(receiptsText.discard),
            ),
          ],
        ),
      ],
    ),
  );
  return confirm == true;
}

Future<void> showReceiptOcrResultDialog(
  BuildContext context, {
  required String text,
  required String? structured,
}) async {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  var structuredMode = structured != null;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(receiptsText.ocrResultTitle),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            final content = structuredMode && structured != null
                ? structured
                : text.isEmpty
                ? receiptsText.emptyOcrText
                : text;
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (structured != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(receiptsText.ocrTextTab),
                            icon: Icon(Icons.notes_outlined),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(receiptsText.ocrStructuredTab),
                            icon: Icon(Icons.view_agenda_outlined),
                          ),
                        ],
                        selected: {structuredMode},
                        onSelectionChanged: (value) {
                          setDialogState(() => structuredMode = value.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.finTrackColors.surfaceAlt,
                        border: Border.all(
                          color: context.finTrackColors.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontFamily: 'monospace', height: 1.35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(commonText.close),
          ),
        ],
      );
    },
  );
}
