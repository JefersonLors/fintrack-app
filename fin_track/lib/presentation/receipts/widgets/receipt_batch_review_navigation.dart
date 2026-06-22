import 'package:flutter/material.dart';

import '../controllers/receipt_batch_controller.dart';

class ReceiptBatchReviewNavigation extends StatelessWidget {
  const ReceiptBatchReviewNavigation({
    super.key,
    required this.currentIndex,
    required this.totalItems,
    required this.currentStatus,
    required this.saving,
    required this.savingAll,
    required this.onPrevious,
    required this.onSaveCurrent,
    required this.onNext,
  });

  final int currentIndex;
  final int totalItems;
  final ReceiptBatchItemStatus currentStatus;
  final bool saving;
  final bool savingAll;
  final VoidCallback onPrevious;
  final VoidCallback onSaveCurrent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: 'Anterior',
            onPressed: saving || currentIndex == 0 ? null : onPrevious,
            icon: Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed:
                  currentStatus == ReceiptBatchItemStatus.ready && !saving
                  ? onSaveCurrent
                  : null,
              icon: saving && !savingAll
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.save_outlined),
              label: const Text('Salvar item'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Próximo',
            onPressed: saving || currentIndex >= totalItems - 1 ? null : onNext,
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
