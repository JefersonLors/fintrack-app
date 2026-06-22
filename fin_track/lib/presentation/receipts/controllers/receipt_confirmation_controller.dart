import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/entities/extracted_data.dart';
import '../../../domain/services/i_category_service.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../../../domain/value_objects/receipt_payment_method.dart';
import '../receipt_form_helpers.dart';

class ReceiptConfirmationController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final establishmentController = TextEditingController();

  Receipt? receipt;
  List<Category> categories = const <Category>[];
  int? categoryId;
  var type = ReceiptType.other;
  var expense = true;
  String? paymentMethod;
  DateTime? transactionDate;
  var loading = true;
  var loadRequested = false;
  var saving = false;
  var previewSaved = false;
  var exitConfirmed = false;
  IReceiptService? _receiptService;

  @override
  void dispose() {
    amountController.dispose();
    dateController.dispose();
    establishmentController.dispose();
    super.dispose();
  }

  bool requestLoad() {
    if (loadRequested) {
      return false;
    }
    loadRequested = true;
    return true;
  }

  void markLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  void markSaving(bool value) {
    saving = value;
    notifyListeners();
  }

  void setType(ReceiptType value) {
    type = value;
    notifyListeners();
  }

  void setExpense(bool value) {
    expense = value;
    notifyListeners();
  }

  void setPaymentMethod(String? value) {
    paymentMethod = value;
    notifyListeners();
  }

  void setCategoryId(int? value) {
    categoryId = value;
    notifyListeners();
  }

  void setTransactionDate(DateTime? value) {
    transactionDate = value == null
        ? null
        : DateTime(value.year, value.month, value.day);
    dateController.text = formatDateField(transactionDate);
    notifyListeners();
  }

  void clearDate() {
    setTransactionDate(null);
  }

  void markPreviewSaved() {
    previewSaved = true;
    notifyListeners();
  }

  void markExitConfirmed() {
    exitConfirmed = true;
    notifyListeners();
  }

  void applyReceipt(Receipt receipt, List<Category> loadedCategories) {
    this.receipt = receipt;
    categories = loadedCategories;
    type = receipt.type;
    expense = receipt.expense;
    paymentMethod = receipt.extractedData?.paymentMethod;
    transactionDate = receipt.extractedData?.transactionDate;
    categoryId = receipt.category?.id;
    loadReceiptInForm(receipt);
    loading = false;
    notifyListeners();
  }

  void loadReceiptInForm(Receipt receipt) {
    final receiptData = receipt.extractedData;
    amountController.text = formatEditableCurrencyValue(receiptData?.amount);
    dateController.text = formatDateField(receiptData?.transactionDate);
    establishmentController.text = receiptData?.establishment ?? '';
  }

  Future<Receipt> loadInitial({
    required IReceiptService receiptService,
    required ICategoryService categoryService,
    required Receipt? initialReceipt,
    required int? receiptId,
  }) async {
    _receiptService = receiptService;
    markLoading(true);
    final receipt = initialReceipt ?? await receiptService.findById(receiptId!);
    final categories = await categoryService.list();
    final receiptData = receipt.extractedData;
    final normalizedReceipt = receiptData == null
        ? receipt
        : receipt.copyWith(
            extractedData: receiptData.copyWith(
              paymentMethod: ReceiptPaymentMethod.normalize(
                receiptData.paymentMethod,
              ),
            ),
          );
    applyReceipt(normalizedReceipt, categories);
    return normalizedReceipt;
  }

  bool validateForm() => formKey.currentState?.validate() ?? true;

  Receipt buildUpdatedReceipt() {
    final receipt = this.receipt!;
    final category = selectedCategory(receipt);
    final currentData = receipt.extractedData;
    return receipt.copyWith(
      type: type,
      expense: expense,
      extractedData: ExtractedData(
        id: currentData?.id ?? 0,
        receiptId: receipt.id,
        amount: parseEditableCurrencyValue(amountController.text),
        transactionDate: transactionDate,
        establishment: establishmentController.text.trim(),
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
      category: category,
    );
  }

  Future<void> saveReceipt(Receipt updatedReceipt) async {
    final service = _receiptService!;
    final originalReceipt = receipt!;
    markSaving(true);
    try {
      if (originalReceipt.id == 0) {
        receipt = await service.saveConfirmed(updatedReceipt);
        markPreviewSaved();
      } else {
        await service.update(updatedReceipt);
        receipt = updatedReceipt;
        markExitConfirmed();
      }
    } finally {
      markSaving(false);
    }
  }

  Future<void> discardPreviewIfNeeded() async {
    final service = _receiptService;
    final receipt = this.receipt;
    if (receipt != null && receipt.id == 0) {
      await service?.discardPreview(receipt);
    }
  }

  String rawOcrText() => receipt?.extractedContent.trim() ?? '';

  String? structuredOcrText() {
    final metadata = receipt?.extractedData?.qualityMetadata;
    final lines = metadata?['ocrEstruturadoLinhas'];
    if (lines is! List || lines.isEmpty) {
      return null;
    }
    final summary = metadata?['ocrEstruturadoResumo'];
    final buffer = StringBuffer();
    if (summary is Map) {
      buffer.writeln(
        'blocos=${summary['blocos'] ?? '-'} '
        'linhas=${summary['linhas'] ?? '-'} '
        'elementos=${summary['elementos'] ?? '-'}',
      );
      buffer.writeln('');
    }
    for (final line in lines) {
      final text = line?.toString().trim();
      if (text != null && text.isNotEmpty) {
        buffer.writeln(text);
      }
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  Category? selectedCategory(Receipt receipt) {
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
