import 'dart:async';
import 'dart:io';

import '../../../application/receipts/batch/batch_staging_service.dart';
import '../../../application/receipts/batch/receipt_batch_state.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/services/i_receipt_service.dart';

export '../../../application/receipts/batch/receipt_batch_state.dart';

class ReceiptBatchController {
  ReceiptBatchController({
    required this.items,
    BatchStagingService? stagingService,
  }) : _stagingService = stagingService ?? const BatchStagingService();

  factory ReceiptBatchController.fromFiles(List<File> files) {
    return ReceiptBatchController(
      items: files
          .asMap()
          .entries
          .map(
            (entry) => ReceiptBatchItem(
              file: entry.value,
              originalFile: entry.value,
              number: entry.key + 1,
            ),
          )
          .toList(),
    );
  }

  final List<ReceiptBatchItem> items;
  final BatchStagingService _stagingService;

  var processingStarted = false;
  var finishTransferred = false;
  var canceled = false;
  Directory? stagingDirectory;

  ReceiptBatchProgress get progress {
    final processed = items
        .where(
          (item) =>
              item.status == ReceiptBatchItemStatus.ready ||
              item.status == ReceiptBatchItemStatus.error ||
              item.status == ReceiptBatchItemStatus.saved,
        )
        .length;
    return ReceiptBatchProgress(
      total: items.length,
      processed: processed,
      pending: items
          .where((item) => item.status == ReceiptBatchItemStatus.pending)
          .length,
      errors: items
          .where((item) => item.status == ReceiptBatchItemStatus.error)
          .length,
    );
  }

  Future<void> prepareStaging() async {
    if (stagingDirectory != null) {
      return;
    }
    final originals = items.map((item) => item.file).toList(growable: false);
    final result = await _stagingService.stage(originals);
    stagingDirectory = result.directory;
    for (var index = 0; index < items.length; index++) {
      items[index].file = result.files[index];
    }
  }

  Future<void> discardStaging() async {
    final staging = stagingDirectory;
    stagingDirectory = null;
    if (staging != null) {
      await _stagingService.deleteDirectorySilently(staging);
    }
  }

  void markAllAsError(Object error) {
    for (final item in items) {
      item.error = error;
      item.status = ReceiptBatchItemStatus.error;
    }
  }

  void markProcessing(ReceiptBatchItem item) {
    item.status = ReceiptBatchItemStatus.processing;
    item.error = null;
  }

  void markReady(ReceiptBatchItem item, Receipt receipt) {
    item.receipt = receipt;
    item.status = ReceiptBatchItemStatus.ready;
  }

  void markError(ReceiptBatchItem item, Object error) {
    item.error = error;
    item.status = ReceiptBatchItemStatus.error;
  }

  void markSaved(ReceiptBatchItem item, Receipt receipt) {
    item.receipt = receipt;
    item.status = ReceiptBatchItemStatus.saved;
  }

  bool hasUnsavedItems() {
    return items.any((item) => item.status == ReceiptBatchItemStatus.ready);
  }

  bool hasErrorItems() {
    return items.any((item) => item.status == ReceiptBatchItemStatus.error);
  }

  List<Receipt> pendingReceipts() {
    return items
        .where(
          (item) =>
              item.status == ReceiptBatchItemStatus.ready &&
              item.receipt != null,
        )
        .map((item) => item.receipt!)
        .toList(growable: false);
  }

  void removeAt(int index, {required int currentIndex}) {
    items.removeAt(index);
  }

  Future<void> discardPreview(
    IReceiptService service,
    ReceiptBatchItem item,
  ) async {
    final receipt = item.receipt;
    if (receipt == null || receipt.id != 0) {
      return;
    }
    await service.discardPreview(receipt);
  }

  Future<void> discardPendingPreviews(IReceiptService service) async {
    for (final item in items) {
      await discardPreview(service, item);
    }
  }

  Future<void> finish(Future<void> Function()? onFinished) async {
    if (onFinished != null) {
      await onFinished();
    }
  }
}
