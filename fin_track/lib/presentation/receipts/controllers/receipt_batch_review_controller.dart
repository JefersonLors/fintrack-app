import 'package:flutter/material.dart';

import '../../../application/receipts/batch/receipt_batch_state.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/extracted_data.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../../../domain/value_objects/receipt_payment_method.dart';
import '../../../infrastructure/diagnostics/fin_track_error_log.dart';
import '../receipt_form_helpers.dart';

class ReceiptBatchReviewSaveAllResult {
  const ReceiptBatchReviewSaveAllResult({required this.errors});

  final List<Object> errors;

  bool get hasErrors => errors.isNotEmpty;
}

class ReceiptBatchReviewController {
  ReceiptBatchReviewController({
    required this.items,
    required this.formKey,
    required this.amountController,
    required this.dateController,
    required this.merchantController,
  });

  final List<ReceiptBatchItem> items;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController dateController;
  final TextEditingController merchantController;

  List<Category> categories = const <Category>[];
  var currentIndex = 0;
  var saving = false;
  var reprocessing = false;
  int? categoryId;
  ReceiptType receiptType = ReceiptType.other;
  var expense = true;
  String? paymentMethod;
  DateTime? transactionDate;

  ReceiptBatchItem? get currentItem {
    if (items.isEmpty) {
      return null;
    }
    return items[currentIndex];
  }

  void loadCategories(List<Category> loadedCategories) {
    categories = loadedCategories;
    loadCurrentItem();
  }

  void changeItem(int index) {
    persistCurrentItemEdits(validate: false);
    currentIndex = index;
    loadCurrentItem();
  }

  void loadCurrentItem() {
    if (items.isEmpty) {
      return;
    }
    final receipt = items[currentIndex].receipt;
    if (receipt == null) {
      amountController.clear();
      dateController.clear();
      merchantController.clear();
      categoryId = null;
      receiptType = ReceiptType.other;
      expense = true;
      paymentMethod = null;
      transactionDate = null;
      return;
    }

    final receiptData = receipt.extractedData;
    amountController.text = formatEditableCurrencyValue(receiptData?.amount);
    transactionDate = receiptData?.transactionDate;
    dateController.text = formatDateField(transactionDate);
    merchantController.text = receiptData?.establishment ?? '';
    categoryId = receipt.category?.id;
    receiptType = receipt.type;
    expense = receipt.expense;
    paymentMethod = ReceiptPaymentMethod.normalize(receiptData?.paymentMethod);
  }

  void setTransactionDate(DateTime? value) {
    transactionDate = value == null
        ? null
        : DateTime(value.year, value.month, value.day);
    dateController.text = formatDateField(transactionDate);
  }

  bool persistCurrentItemEdits({required bool validate}) {
    if (items.isEmpty) {
      return true;
    }
    final item = items[currentIndex];
    final receipt = item.receipt;
    if (receipt == null || item.status != ReceiptBatchItemStatus.ready) {
      return true;
    }
    if (validate && !(formKey.currentState?.validate() ?? true)) {
      return false;
    }

    item.receipt = buildUpdatedReceipt(receipt);
    return true;
  }

  Receipt buildUpdatedReceipt(Receipt receipt) {
    final currentData = receipt.extractedData;
    return receipt.copyWith(
      type: receiptType,
      expense: expense,
      extractedData: ExtractedData(
        id: currentData?.id ?? 0,
        receiptId: receipt.id,
        amount: parseEditableCurrencyValue(amountController.text),
        transactionDate: transactionDate,
        establishment: merchantController.text.trim(),
        items: currentData?.items ?? const <String>[],
        paymentMethod: paymentMethod,
        issuerCnpj: currentData?.issuerCnpj,
        accessKey: currentData?.accessKey,
        urlQrCode: currentData?.urlQrCode,
        documentNumber: currentData?.documentNumber,
        documentSeries: currentData?.documentSeries,
        documentState: currentData?.documentState,
        issuerLegalName: currentData?.issuerLegalName,
        issuerTradeName: currentData?.issuerTradeName,
        fiscalCnaeDescription: currentData?.fiscalCnaeDescription,
        issuerCity: currentData?.issuerCity,
        issuerState: currentData?.issuerState,
        ocrConfidence: currentData?.ocrConfidence,
        extractionParser: currentData?.extractionParser,
        extractionConfidence: currentData?.extractionConfidence,
        valueConfidence: currentData?.valueConfidence,
        dateConfidence: currentData?.dateConfidence,
        establishmentConfidence: currentData?.establishmentConfidence,
        paymentMethodConfidence: currentData?.paymentMethodConfidence,
        qualityMetadata: currentData?.qualityMetadata,
      ),
      category: _selectedCategory(receipt),
    );
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

  Future<bool> saveCurrent(IReceiptService service) async {
    if (!persistCurrentItemEdits(validate: true)) {
      return false;
    }
    final item = currentItem;
    final receipt = item?.receipt;
    if (item == null || receipt == null) {
      return false;
    }

    saving = true;
    try {
      final savedReceipt = await service.saveConfirmed(receipt);
      removeSavedItemFromReview(item, savedReceipt);
      return true;
    } catch (error, stackTrace) {
      FinTrackErrorLog.record(error, stackTrace);
      item.error = error;
      item.status = ReceiptBatchItemStatus.error;
      return false;
    } finally {
      saving = false;
    }
  }

  Future<ReceiptBatchReviewSaveAllResult> saveAll(
    IReceiptService service, {
    ValueChanged<int>? onProgress,
  }) async {
    final errors = <Object>[];
    if (!persistCurrentItemEdits(validate: true)) {
      return const ReceiptBatchReviewSaveAllResult(errors: <Object>[]);
    }

    var processed = 0;
    saving = true;
    try {
      for (final item in items) {
        if (item.status != ReceiptBatchItemStatus.ready ||
            item.receipt == null) {
          continue;
        }
        try {
          final savedReceipt = await service.saveConfirmed(item.receipt!);
          item.receipt = savedReceipt;
          item.status = ReceiptBatchItemStatus.saved;
        } catch (error, stackTrace) {
          FinTrackErrorLog.record(error, stackTrace);
          errors.add(error);
          item.error = error;
          item.status = ReceiptBatchItemStatus.error;
        }
        processed += 1;
        onProgress?.call(processed);
      }
    } finally {
      saving = false;
    }
    return ReceiptBatchReviewSaveAllResult(errors: errors);
  }

  void removeSavedItemFromReview(ReceiptBatchItem item, Receipt savedReceipt) {
    final removedIndex = items.indexOf(item);
    if (removedIndex < 0) {
      return;
    }

    item.receipt = savedReceipt;
    item.status = ReceiptBatchItemStatus.saved;
    items.removeAt(removedIndex);
    if (items.isEmpty) {
      currentIndex = 0;
    } else if (removedIndex >= items.length) {
      currentIndex = items.length - 1;
    } else {
      currentIndex = removedIndex;
    }
  }

  Future<Object?> reprocessItem(IReceiptService service, int index) async {
    final item = items[index];
    reprocessing = true;
    item.status = ReceiptBatchItemStatus.processing;
    item.error = null;
    try {
      await service.validateSpaceForNewReceipt(item.file);
      final receipt = await service.processPreview(item.file);
      item.receipt = receipt;
      item.status = ReceiptBatchItemStatus.ready;
      loadCurrentItem();
      return null;
    } catch (error, stackTrace) {
      FinTrackErrorLog.record(error, stackTrace);
      item.error = error;
      item.status = ReceiptBatchItemStatus.error;
      return error;
    } finally {
      reprocessing = false;
    }
  }

  Future<void> removeItem(IReceiptService service, int index) async {
    await discardItemPreview(service, items[index]);
    items.removeAt(index);
    if (items.isEmpty) {
      currentIndex = 0;
      return;
    }
    if (currentIndex >= items.length) {
      currentIndex = items.length - 1;
    }
    loadCurrentItem();
  }

  Future<void> discardPendingPreviews(IReceiptService service) async {
    for (final item in items) {
      await discardItemPreview(service, item);
    }
  }

  Future<void> discardItemPreview(
    IReceiptService service,
    ReceiptBatchItem item,
  ) async {
    final receipt = item.receipt;
    if (receipt == null || receipt.id != 0) {
      return;
    }
    await service.discardPreview(receipt);
  }

  bool hasUnsavedItems() {
    return items.any((item) => item.status == ReceiptBatchItemStatus.ready);
  }

  bool hasErrorItems() {
    return items.any((item) => item.status == ReceiptBatchItemStatus.error);
  }

  Category? _selectedCategory(Receipt receipt) {
    if (categoryId == null) {
      return null;
    }
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    final receiptCategory = receipt.category;
    if (receiptCategory?.id == categoryId) {
      return receiptCategory;
    }
    return null;
  }
}
