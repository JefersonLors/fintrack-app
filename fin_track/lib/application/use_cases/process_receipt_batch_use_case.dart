import 'dart:async';
import 'dart:io';

import '../receipts/batch/batch_staging_service.dart';
import '../receipts/batch/receipt_batch_state.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/services/i_receipt_service.dart';

typedef ReceiptBatchChanged = void Function();
typedef ReceiptBatchError = void Function(Object error);
typedef ReceiptBatchCanceled = bool Function();

class ProcessReceiptBatchResult {
  const ProcessReceiptBatchResult({this.stagingDirectory});

  final Directory? stagingDirectory;
}

class ProcessReceiptBatchUseCase {
  const ProcessReceiptBatchUseCase({
    this.concurrency = 2,
    this.stagingService = const BatchStagingService(),
  });

  final int concurrency;
  final BatchStagingService stagingService;

  Future<ProcessReceiptBatchResult> call({
    required List<ReceiptBatchItem> items,
    required IReceiptService service,
    required ReceiptBatchChanged onChanged,
    required ReceiptBatchCanceled isCanceled,
    ReceiptBatchError? onStorageLimit,
  }) async {
    Directory? stagingDirectory;
    try {
      final originals = items.map((item) => item.file).toList(growable: false);
      final result = await stagingService.stage(originals);
      stagingDirectory = result.directory;
      for (var index = 0; index < items.length; index++) {
        items[index].file = result.files[index];
      }
    } catch (error) {
      for (final item in items) {
        item.error = error;
        item.status = ReceiptBatchItemStatus.error;
      }
      onChanged();
      return ProcessReceiptBatchResult(stagingDirectory: stagingDirectory);
    }
    if (isCanceled()) {
      return ProcessReceiptBatchResult(stagingDirectory: stagingDirectory);
    }

    try {
      for (final item in items) {
        await service.validateSpaceForNewReceipt(item.file);
      }
    } catch (error) {
      onStorageLimit?.call(error);
      for (final item in items) {
        item.error = error;
        item.status = ReceiptBatchItemStatus.error;
      }
      onChanged();
      return ProcessReceiptBatchResult(stagingDirectory: stagingDirectory);
    }

    var nextIndex = 0;

    Future<void> processQueue() async {
      while (!isCanceled()) {
        final index = nextIndex;
        if (index >= items.length) {
          return;
        }
        nextIndex++;
        await _processItem(
          service: service,
          item: items[index],
          onChanged: onChanged,
          isCanceled: isCanceled,
          onStorageLimit: onStorageLimit,
        );
      }
    }

    final workers = List<Future<void>>.generate(
      items.length < concurrency ? items.length : concurrency,
      (_) => processQueue(),
    );
    await Future.wait(workers);
    return ProcessReceiptBatchResult(stagingDirectory: stagingDirectory);
  }

  Future<void> _processItem({
    required IReceiptService service,
    required ReceiptBatchItem item,
    required ReceiptBatchChanged onChanged,
    required ReceiptBatchCanceled isCanceled,
    ReceiptBatchError? onStorageLimit,
  }) async {
    if (isCanceled()) {
      return;
    }
    item.status = ReceiptBatchItemStatus.processing;
    item.error = null;
    onChanged();

    try {
      await service.validateSpaceForNewReceipt(item.file);
      if (isCanceled()) {
        return;
      }
      final receipt = await service.processPreview(item.file);
      if (isCanceled()) {
        await _discardCanceledPreview(service, receipt);
        return;
      }
      item.receipt = receipt;
      item.status = ReceiptBatchItemStatus.ready;
      onChanged();
    } catch (error) {
      if (isCanceled()) {
        return;
      }
      onStorageLimit?.call(error);
      item.error = error;
      item.status = ReceiptBatchItemStatus.error;
      onChanged();
    }
  }

  Future<void> _discardCanceledPreview(
    IReceiptService service,
    Receipt receipt,
  ) async {
    if (receipt.id == 0) {
      await service.discardPreview(receipt);
    }
  }
}
