import 'dart:async';
import 'dart:io';

import '../../../domain/entities/receipt_batch_import.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/infrastructure/i_receipt_batch_scheduler.dart';
import '../../../domain/repositories/i_receipt_batch_import_repository.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../../../infrastructure/diagnostics/error_handling.dart';
import 'batch_staging_service.dart';

class ReceiptBatchImportService {
  static const _defaultConcurrency = 2;
  static const _defaultItemProcessingTimeout = Duration(minutes: 8);
  static const _processingRecoveryAge = _defaultItemProcessingTimeout;

  ReceiptBatchImportService({
    required IReceiptBatchImportRepository repository,
    required IReceiptService receiptService,
    IReceiptBatchScheduler scheduler = const NoopReceiptBatchScheduler(),
    BatchStagingService stagingService = const BatchStagingService(),
    int concurrency = _defaultConcurrency,
    Duration itemProcessingTimeout = _defaultItemProcessingTimeout,
  }) : _repository = repository,
       _receiptService = receiptService,
       _scheduler = scheduler,
       _stagingService = stagingService,
       _concurrency = concurrency < 1 ? 1 : concurrency,
       _itemProcessingTimeout = itemProcessingTimeout;

  final IReceiptBatchImportRepository _repository;
  final IReceiptService _receiptService;
  final IReceiptBatchScheduler _scheduler;
  final BatchStagingService _stagingService;
  final int _concurrency;
  final Duration _itemProcessingTimeout;
  final _canceledSessionIds = <int>{};

  Future<int> createSession(List<File> files) async {
    final staged = await _stagingService.stage(files);
    final sessionId = await _repository.createSession(
      stagingDirectory: staged.directory,
      originalFiles: files,
      stagedFiles: staged.files,
    );
    await _scheduler.schedulePendingBatchImports();
    return sessionId;
  }

  Stream<ReceiptBatchImportSnapshot?> watchSnapshot(int sessionId) {
    return _repository.watchSnapshot(sessionId);
  }

  Future<ReceiptBatchImportSnapshot?> findSnapshot(int sessionId) {
    return _repository.findSnapshot(sessionId);
  }

  Future<ReceiptBatchImportSnapshot?> findLatestOpenSnapshot() {
    return _repository.findLatestOpenSnapshot();
  }

  Future<void> processSession(int sessionId) async {
    if (_canceledSessionIds.contains(sessionId)) {
      return;
    }
    await _repository.resetStaleProcessingItems(
      sessionId,
      _processingRecoveryAge,
    );
    await _repository.markSessionStatus(
      sessionId,
      ReceiptBatchImportStatus.processing,
    );

    Future<void> processQueue() async {
      while (true) {
        if (_canceledSessionIds.contains(sessionId)) {
          break;
        }
        final item = await _repository.claimNextPendingItem(sessionId);
        if (item == null) {
          break;
        }
        await _processClaimedItem(sessionId, item);
      }
    }

    final workers = List<Future<void>>.generate(
      _concurrency,
      (_) => processQueue(),
    );
    await Future.wait(workers);

    if (_canceledSessionIds.contains(sessionId)) {
      return;
    }
    await _repository.refreshSessionStatus(sessionId);
  }

  Future<void> _processClaimedItem(
    int sessionId,
    ReceiptBatchImportItem item,
  ) async {
    try {
      final receipt = await _processItem(item).timeout(
        _itemProcessingTimeout,
        onTimeout: () => throw TimeoutException(
          'Tempo limite excedido ao processar o item ${item.number}.',
          _itemProcessingTimeout,
        ),
      );
      if (_canceledSessionIds.contains(sessionId)) {
        await _receiptService.discardPreview(receipt);
        return;
      }
      await _repository.markItemReady(item.id, receipt);
    } catch (error, stackTrace) {
      if (_canceledSessionIds.contains(sessionId)) {
        return;
      }
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext:
            'Falha ao processar item ${item.number} da importação em lote',
      );
      await _repository.markItemError(item.id, error);
    }
  }

  Future<Receipt> _processItem(ReceiptBatchImportItem item) async {
    await _receiptService.validateSpaceForNewReceipt(item.file);
    return _receiptService.processPreview(item.file);
  }

  Future<void> processPendingSessions() async {
    final sessions = await _repository.findRunnableSessions();
    for (final session in sessions) {
      await processSession(session.id);
    }
  }

  Future<void> pauseScheduledProcessing() {
    return _scheduler.cancelPendingBatchImports();
  }

  Future<void> markSaved(int itemId, Receipt receipt) {
    return _repository.markItemSaved(itemId, receipt);
  }

  Future<void> completeSession(int sessionId) async {
    await _repository.markSessionStatus(
      sessionId,
      ReceiptBatchImportStatus.completed,
    );
    await _repository.deleteSession(sessionId);
  }

  Future<void> cancelSession(int sessionId) async {
    _canceledSessionIds.add(sessionId);
    await _scheduler.cancelPendingBatchImports();
    final snapshot = await _repository.findSnapshot(sessionId);
    if (snapshot != null) {
      for (final item in snapshot.items) {
        final receipt = item.receipt;
        if (receipt != null) {
          await _receiptService.discardPreview(receipt);
        }
      }
    }
    await _repository.markSessionStatus(
      sessionId,
      ReceiptBatchImportStatus.canceled,
    );
    await _repository.deleteSession(sessionId);
  }
}
