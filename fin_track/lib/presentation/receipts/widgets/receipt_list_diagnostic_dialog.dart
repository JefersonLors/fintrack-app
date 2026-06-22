import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';

Future<void> showReceiptListDiagnosticDialog(
  BuildContext context,
  String diagnostic,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Diagnóstico semântico'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surfaceAlt,
              border: Border.all(color: context.finTrackColors.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                diagnostic,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
