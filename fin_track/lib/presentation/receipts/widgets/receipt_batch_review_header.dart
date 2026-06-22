import 'package:flutter/material.dart';

import '../../widgets/fin_track_page_header.dart';

class ReceiptBatchReviewHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ReceiptBatchReviewHeader({
    super.key,
    required this.currentIndex,
    required this.totalItems,
    required this.canSaveAll,
    required this.onSaveAll,
  });

  final int currentIndex;
  final int totalItems;
  final bool canSaveAll;
  final VoidCallback onSaveAll;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return FinTrackPageHeader(
      automaticallyImplyLeading: true,
      title: Text('Revisar ${currentIndex + 1}/$totalItems'),
      actions: [
        TextButton(
          onPressed: canSaveAll ? onSaveAll : null,
          child: const Text('Salvar todos'),
        ),
      ],
    );
  }
}

class EmptyReceiptBatchReview extends StatelessWidget {
  const EmptyReceiptBatchReview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: FinTrackPageHeader(
        title: Text('Revisar lote'),
        automaticallyImplyLeading: true,
      ),
      body: Center(child: Text('Nenhum comprovante para revisar.')),
    );
  }
}
