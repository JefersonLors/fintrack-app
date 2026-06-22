import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/ocr_result.dart';
import '../../../infrastructure/diagnostics/error_handling.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/fin_track_page_header.dart';
import '../../widgets/keyboard_back_dismissal.dart';
import '../../widgets/state_views.dart';
import '../../widgets/storage_limit_feedback.dart';
import '../controllers/receipt_confirmation_controller.dart';

import '../widgets/receipt_confirmation_dialogs.dart';
import '../widgets/receipt_confirmation_form_widgets.dart';
import '../widgets/receipt_confirmation_preview_widgets.dart';

const EdgeInsets _fieldScrollPadding = EdgeInsets.only(bottom: 120);

class ReceiptConfirmationPage extends StatefulWidget {
  const ReceiptConfirmationPage({
    super.key,
    this.receiptId,
    this.receipt,
    this.onFinished,
  }) : assert(
         receiptId != null || receipt != null,
         'Informe um comprovante salvo ou uma prévia para confirmação.',
       );

  final int? receiptId;
  final Receipt? receipt;
  final Future<void> Function()? onFinished;

  @override
  State<ReceiptConfirmationPage> createState() =>
      _ReceiptConfirmationPageState();
}

class _ReceiptConfirmationPageState extends State<ReceiptConfirmationPage> {
  late final ReceiptConfirmationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReceiptConfirmationController()
      ..addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.requestLoad()) {
      _load();
    }
  }

  @override
  void dispose() {
    if (!_controller.previewSaved) {
      unawaited(_controller.discardPreviewIfNeeded());
    }
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      unawaited(onFinished());
    }
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    if (_controller.loading) {
      return Scaffold(
        body: LoadingView(message: receiptsText.confirmationLoading),
      );
    }

    final receipt = _controller.receipt;
    if (receipt == null) {
      return Scaffold(
        appBar: const FinTrackPageHeader(
          title: SizedBox.shrink(),
          automaticallyImplyLeading: true,
        ),
        body: ErrorStateView(
          message: receiptsText.confirmationNotFound,
          onRetry: _load,
        ),
      );
    }

    final receiptData = receipt.extractedData;
    final confidence = receiptData?.ocrConfidence ?? 0;
    final extractionConfidence = receiptData?.extractionConfidence;
    final debugMode = AppScope.maybeOf(context)?.appConfig.debugMode ?? false;
    final lowConfidence = confidence < OcrResult.acceptableConfidenceThreshold;
    final lowExtractionConfidence =
        extractionConfidence != null && extractionConfidence < 0.65;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: _controller.exitConfirmed || _controller.previewSaved,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _controller.saving) {
          return;
        }
        if (dismissKeyboardForBack(context)) {
          return;
        }
        unawaited(_confirmExitWithoutSaving());
      },
      child: Scaffold(
        appBar: FinTrackPageHeader(
          title: Text(receiptsText.confirmationTitle),
          automaticallyImplyLeading: true,
        ),
        body: SafeArea(
          child: Form(
            key: _controller.formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardInset),
              children: [
                FutureBuilder<File>(
                  future: AppScope.of(
                    context,
                  ).receiptService.localFile(receipt),
                  builder: (context, snapshot) {
                    return ReceiptConfirmationImagePreview(
                      file: snapshot.data,
                      fileName: receipt.fileName,
                      fileType: receipt.fileType,
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (lowConfidence || lowExtractionConfidence)
                  MaterialBanner(
                    leading: Icon(
                      Icons.warning_amber_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    content: Text(
                      lowExtractionConfidence
                          ? receiptsText.lowExtractionConfidence
                          : receiptsText.lowOcrConfidence,
                    ),
                    actions: const [SizedBox.shrink()],
                  ),
                const SizedBox(height: 12),
                ReceiptConfirmationFormFields(
                  receipt: receipt,
                  categories: _controller.categories,
                  amountController: _controller.amountController,
                  dateController: _controller.dateController,
                  establishmentController: _controller.establishmentController,
                  type: _controller.type,
                  expense: _controller.expense,
                  paymentMethod: _controller.paymentMethod,
                  categoryId: _controller.categoryId,
                  transactionDate: _controller.transactionDate,
                  fieldScrollPadding: _fieldScrollPadding,
                  onClearDate: _controller.clearDate,
                  onSelectDate: _selectDate,
                  onTypeChanged: _controller.setType,
                  onExpenseChanged: _controller.setExpense,
                  onPaymentMethodChanged: _controller.setPaymentMethod,
                  onCategoryChanged: _controller.setCategoryId,
                ),
                const SizedBox(height: 16),
                ReceiptConfirmationConfidenceTile(
                  confidence: confidence,
                  extractionConfidence: extractionConfidence,
                  extractionParser: receiptData?.extractionParser,
                  debugMode: debugMode,
                  onTap: _showOcrResult,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _controller.saving
                            ? null
                            : _confirmExitWithoutSaving,
                        icon: Icon(Icons.close),
                        label: Text(commonText.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _controller.saving ? null : _save,
                        icon: _controller.saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.save_outlined),
                        label: Text(commonText.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    final deps = AppScope.of(context);
    await _controller.loadInitial(
      receiptService: deps.receiptService,
      categoryService: deps.categoryService,
      initialReceipt: widget.receipt,
      receiptId: widget.receiptId,
    );

    if (!mounted) {
      return;
    }
  }

  Future<void> _save() async {
    if (_controller.saving) {
      return;
    }
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    if (!_controller.validateForm()) {
      return;
    }

    final updated = _controller.buildUpdatedReceipt();
    if (!await showReceiptPendingFieldsDialog(context, updated)) {
      return;
    }
    if (!mounted) {
      return;
    }
    try {
      await _controller.saveReceipt(updated);
    } on FormatException catch (error) {
      if (mounted) {
        if (isStorageLimitError(error)) {
          showStorageLimitSnackBar(context, error);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userFriendlyErrorMessage(
                  error,
                  fallback: receiptsText.saveFailed,
                ),
              ),
            ),
          );
        }
      }
      return;
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao salvar confirmação do comprovante',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(receiptsText.saveFailed)));
      }
      return;
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(receiptsText.saved)));
    Navigator.of(context).pop(true);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initial = _controller.transactionDate ?? now;
    final commonText = AppScope.of(context).appConfig.ui.common;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: receiptsText.selectTransactionDate,
      cancelText: commonText.cancel,
      confirmText: receiptsText.confirm,
      errorFormatText: receiptsText.invalidDate,
      errorInvalidText: receiptsText.dateOutOfRange,
    );

    if (selected == null || !mounted) {
      return;
    }

    final date = DateTime(selected.year, selected.month, selected.day);
    _controller.setTransactionDate(date);
  }

  Future<void> _confirmExitWithoutSaving() async {
    if (_controller.saving) {
      return;
    }

    final confirm = await showDiscardReceiptPreviewDialog(context);
    if (!confirm || !mounted) {
      return;
    }

    await _controller.discardPreviewIfNeeded();
    if (!mounted) {
      return;
    }
    _controller.markExitConfirmed();
    Navigator.of(context).pop();
  }

  Future<void> _showOcrResult() async {
    await showReceiptOcrResultDialog(
      context,
      text: _controller.rawOcrText(),
      structured: _controller.structuredOcrText(),
    );
  }
}
