import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../application/use_cases/process_receipt_batch_use_case.dart';
import '../../../domain/entities/receipt_batch_import.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/fin_track_page_header.dart';
import '../receipt_flow_result.dart';
import '../controllers/receipt_batch_controller.dart';
import '../widgets/batch_item_card.dart';
import 'receipt_batch_review_page.dart' show ReceiptBatchReviewPage;

class ReceiptBatchProcessingPage extends StatefulWidget {
  const ReceiptBatchProcessingPage({
    super.key,
    required this.files,
    this.onFinished,
    this.controller,
    this.processUseCase = const ProcessReceiptBatchUseCase(),
    this.sessionId,
  });

  final List<File> files;
  final Future<void> Function()? onFinished;
  final ReceiptBatchController? controller;
  final ProcessReceiptBatchUseCase processUseCase;
  final int? sessionId;

  @override
  State<ReceiptBatchProcessingPage> createState() =>
      _ReceiptBatchProcessingPageState();
}

class _ReceiptBatchProcessingPageState
    extends State<ReceiptBatchProcessingPage> {
  int? _sessionId;
  var _creatingSession = false;
  var _processingStarted = false;
  var _reviewOpened = false;
  Object? _initialError;
  ReceiptBatchImportSnapshot? _snapshot;
  late final ReceiptBatchController _initialController =
      widget.controller ?? ReceiptBatchController.fromFiles(widget.files);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return _buildInitialScaffold();
    }
    return StreamBuilder<ReceiptBatchImportSnapshot?>(
      stream: AppScope.of(
        context,
      ).receiptBatchImportService.watchSnapshot(sessionId),
      initialData: _snapshot,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final progress = _progressFromSnapshot(data);
        if (data.isProcessComplete && _hasReviewItem(data) && !_reviewOpened) {
          _reviewOpened = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(_openReview(data));
            }
          });
        }
        return _buildProcessingScaffold(data, progress);
      },
    );
  }

  Widget _buildInitialScaffold() {
    final initialError = _initialError;
    if (initialError != null) {
      _initialController.markAllAsError(initialError);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(_cancelProcessing());
      },
      child: Scaffold(
        appBar: const FinTrackPageHeader(
          title: Text('Processando lote'),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 0),
              const SizedBox(height: 12),
              _BatchSummary(progress: _initialController.progress),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _initialController.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      BatchItemCard(item: _initialController.items[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingScaffold(
    ReceiptBatchImportSnapshot snapshot,
    ReceiptBatchProgress progress,
  ) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(_cancelProcessing());
      },
      child: Scaffold(
        appBar: const FinTrackPageHeader(
          title: Text('Processando lote'),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress.progress),
              const SizedBox(height: 12),
              _BatchSummary(progress: progress),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: snapshot.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => BatchItemCard(
                    item: _itemFromImport(snapshot.items[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ensureSession() async {
    if (!mounted) {
      return;
    }
    if (_creatingSession || _sessionId != null) {
      return;
    }
    _creatingSession = true;
    final importService = AppScope.of(context).receiptBatchImportService;
    int sessionId;
    try {
      sessionId =
          widget.sessionId ?? await importService.createSession(widget.files);
    } catch (error) {
      if (mounted) {
        setState(() => _initialError = error);
      }
      return;
    }
    final initialSnapshot = await importService.findSnapshot(sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionId = sessionId;
      _snapshot = initialSnapshot;
    });
    _processForeground(sessionId);
  }

  void _processForeground(int sessionId) {
    if (_processingStarted) {
      return;
    }
    _processingStarted = true;
    final importService = AppScope.of(context).receiptBatchImportService;
    unawaited(() async {
      await importService.pauseScheduledProcessing();
      await importService.processSession(sessionId);
      final snapshot = await importService.findSnapshot(sessionId);
      if (mounted) {
        setState(() => _snapshot = snapshot);
      }
    }());
  }

  Future<void> _openReview(ReceiptBatchImportSnapshot snapshot) async {
    final importService = AppScope.of(context).receiptBatchImportService;
    final items = snapshot.items.map(_itemFromImport).toList(growable: false);
    final reviewSaved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReceiptBatchReviewPage(
          items: items,
          onItemSaved: (item) async {
            final receipt = item.receipt;
            final persistedItemId = item.persistedItemId;
            if (receipt != null && persistedItemId != null) {
              await importService.markSaved(persistedItemId, receipt);
            }
          },
          onFinished: () async {
            await importService.completeSession(snapshot.session.id);
            await widget.onFinished?.call();
          },
        ),
      ),
    );
    if (mounted) {
      Navigator.of(
        context,
      ).pop(reviewSaved == true ? ReceiptFlowResult.saved : null);
    }
  }

  ReceiptBatchProgress _progressFromSnapshot(ReceiptBatchImportSnapshot data) {
    final processed = data.items
        .where(
          (item) =>
              item.status == ReceiptBatchImportItemStatus.ready ||
              item.status == ReceiptBatchImportItemStatus.error ||
              item.status == ReceiptBatchImportItemStatus.saved,
        )
        .length;
    return ReceiptBatchProgress(
      total: data.items.length,
      processed: processed,
      pending: data.items
          .where((item) => item.status == ReceiptBatchImportItemStatus.pending)
          .length,
      errors: data.items
          .where((item) => item.status == ReceiptBatchImportItemStatus.error)
          .length,
    );
  }

  bool _hasReviewItem(ReceiptBatchImportSnapshot data) {
    return data.items.any(
      (item) =>
          item.status == ReceiptBatchImportItemStatus.ready ||
          item.status == ReceiptBatchImportItemStatus.error,
    );
  }

  ReceiptBatchItem _itemFromImport(ReceiptBatchImportItem importItem) {
    final item = ReceiptBatchItem(
      file: importItem.file,
      number: importItem.number,
      originalFile: File(importItem.originalPath),
      persistedItemId: importItem.id,
    );
    item.status = switch (importItem.status) {
      ReceiptBatchImportItemStatus.pending => ReceiptBatchItemStatus.pending,
      ReceiptBatchImportItemStatus.processing =>
        ReceiptBatchItemStatus.processing,
      ReceiptBatchImportItemStatus.ready => ReceiptBatchItemStatus.ready,
      ReceiptBatchImportItemStatus.error => ReceiptBatchItemStatus.error,
      ReceiptBatchImportItemStatus.saved => ReceiptBatchItemStatus.saved,
    };
    item.error = importItem.errorDescription;
    item.receipt = importItem.receipt;
    return item;
  }

  Future<void> _cancelProcessing() async {
    final sessionId = _sessionId;
    if (sessionId == null) {
      return;
    }
    if (!await _confirmBatchCancel()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final importService = AppScope.of(context).receiptBatchImportService;
    await importService.cancelSession(sessionId);
    await widget.onFinished?.call();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _confirmBatchCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar processamento em lote?'),
        content: const Text(
          'Os itens já processados serão descartados e os itens pendentes não serão adicionados.',
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar'),
              ),
              FilledButton(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
    return confirm == true;
  }
}

class _BatchSummary extends StatelessWidget {
  const _BatchSummary({required this.progress});

  final ReceiptBatchProgress progress;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusChip(
          label: 'Total',
          value: progress.total,
          color: context.finTrackColors.textSecondary,
        ),
        _StatusChip(
          label: 'Pendentes',
          value: progress.pending,
          color: context.finTrackColors.textSecondary,
        ),
        _StatusChip(
          label: 'Processados',
          value: progress.processed,
          color: context.finTrackColors.income,
        ),
        _StatusChip(
          label: 'Erros',
          value: progress.errors,
          color: context.finTrackColors.danger,
        ),
      ],
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
    return SizedBox(
      width: 136,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  value.toString(),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
