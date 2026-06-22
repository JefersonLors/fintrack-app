import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';
import '../../widgets/fin_track_chip.dart';
import '../../widgets/fin_track_panel.dart';
import '../../widgets/image_viewer_page.dart';
import '../receipt_form_helpers.dart';
import '../controllers/receipt_batch_controller.dart';

class BatchItemCard extends StatelessWidget {
  const BatchItemCard({super.key, required this.item});

  final ReceiptBatchItem item;

  @override
  Widget build(BuildContext context) {
    final fileName = batchItemFileName(item);
    return ListTile(
      leading: _statusIcon(context, item.status),
      title: Text(item.label),
      subtitle: Text(
        fileName.isEmpty
            ? batchStatusLabel(item.status)
            : '${batchStatusLabel(item.status)} - $fileName',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.image_outlined),
      onTap: () => _openItemFile(context),
    );
  }

  void _openItemFile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerPage(file: item.file, title: item.label),
      ),
    );
  }

  Widget _statusIcon(BuildContext context, ReceiptBatchItemStatus status) {
    return switch (status) {
      ReceiptBatchItemStatus.pending => Icon(
        Icons.schedule_outlined,
        color: context.finTrackColors.textMuted,
      ),
      ReceiptBatchItemStatus.processing => const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      ReceiptBatchItemStatus.ready => Icon(
        Icons.check_circle_outline,
        color: context.finTrackColors.income,
      ),
      ReceiptBatchItemStatus.error => Icon(
        Icons.error_outline,
        color: context.finTrackColors.danger,
      ),
      ReceiptBatchItemStatus.saved => Icon(
        Icons.save_outlined,
        color: context.finTrackColors.income,
      ),
    };
  }
}

String batchItemFileName(ReceiptBatchItem item) {
  final file = item.originalFile ?? item.file;
  if (file.path.isEmpty) {
    return '';
  }
  return file.uri.pathSegments.isEmpty ? file.path : file.uri.pathSegments.last;
}

String batchStatusLabel(ReceiptBatchItemStatus status) {
  return switch (status) {
    ReceiptBatchItemStatus.pending => 'Pendente',
    ReceiptBatchItemStatus.processing => 'Processando OCR e dados',
    ReceiptBatchItemStatus.ready => 'Pronto para revisão',
    ReceiptBatchItemStatus.error => 'Falha no processamento',
    ReceiptBatchItemStatus.saved => 'Salvo',
  };
}

class ConfirmationPanel extends StatelessWidget {
  const ConfirmationPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FinTrackPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class BatchReviewSummary extends StatelessWidget {
  const BatchReviewSummary({super.key, required this.items});

  final List<ReceiptBatchItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final saved = items
        .where((item) => item.status == ReceiptBatchItemStatus.saved)
        .length;
    final ready = items
        .where((item) => item.status == ReceiptBatchItemStatus.ready)
        .length;
    final errors = items
        .where((item) => item.status == ReceiptBatchItemStatus.error)
        .length;
    return _StatusChipGroup(
      topChildren: [
        _StatusChip(
          label: 'Total',
          value: total,
          color: context.finTrackColors.textSecondary,
        ),
        _StatusChip(
          label: 'A revisar',
          value: ready,
          color: context.finTrackColors.textSecondary,
        ),
      ],
      bottomChildren: [
        _StatusChip(
          label: 'Salvos',
          value: saved,
          color: context.finTrackColors.income,
        ),
        _StatusChip(
          label: 'Erros',
          value: errors,
          color: context.finTrackColors.danger,
        ),
      ],
    );
  }
}

class _StatusChipGroup extends StatelessWidget {
  const _StatusChipGroup({
    required this.topChildren,
    required this.bottomChildren,
  });

  final List<Widget> topChildren;
  final List<Widget> bottomChildren;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatusChipRow(children: topChildren),
          const SizedBox(height: 8),
          _StatusChipRow(children: bottomChildren),
        ],
      ),
    );
  }
}

class _StatusChipRow extends StatelessWidget {
  const _StatusChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FinTrackMetricChip(label: label, value: value, color: color);
  }
}

class BatchItemErrorView extends StatelessWidget {
  const BatchItemErrorView({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onRetry,
    required this.busy,
  });

  final ReceiptBatchItem item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Falha ao processar ${item.label}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              receiptBatchUserErrorMessage(item.error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.finTrackColors.danger,
                  ),
                  label: const Text('Excluir item'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onRetry,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh),
                  label: const Text('Reprocessar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialTypeSelector extends StatelessWidget {
  const FinancialTypeSelector({
    super.key,
    required this.expense,
    required this.onChanged,
  });

  final bool expense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedColor = expense
        ? context.finTrackColors.expense
        : context.finTrackColors.income;
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Natureza',
        prefixIcon: Icon(Icons.swap_vert_circle_outlined),
        helperText: 'Revise se o valor representa saída ou recebimento.',
      ),
      child: SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: selectedColor.withValues(alpha: 0.10),
          selectedForegroundColor: selectedColor,
          side: BorderSide(color: context.finTrackColors.borderStrong),
        ),
        segments: [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.remove_circle_outline),
            label: const Text('Despesa'),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.add_circle_outline),
            label: const Text('Receita'),
          ),
        ],
        selected: {expense},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class ReceiptFilePreview extends StatelessWidget {
  const ReceiptFilePreview({
    super.key,
    required this.file,
    required this.fileName,
    required this.fileType,
  });

  final File? file;
  final String fileName;
  final String fileType;

  @override
  Widget build(BuildContext context) {
    final isImage = looksLikeReceiptImage(fileType, fileName);
    final preview = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.finTrackColors.borderStrong),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: file == null
                      ? const CircularProgressIndicator()
                      : isImage
                      ? Image.file(
                          file!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const _FileFallback(),
                        )
                      : const _FileFallback(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (file == null || !isImage) {
      return preview;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ImageViewerPage(file: file!, title: 'Imagem do comprovante'),
        ),
      ),
      child: preview,
    );
  }
}

class _FileFallback extends StatelessWidget {
  const _FileFallback();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 56),
          const SizedBox(height: 12),
          Text(
            'Pré-visualização indisponível',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
