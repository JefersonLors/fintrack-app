import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../application/receipts/batch/batch_staging_service.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/blocking_progress_dialog.dart';
import '../../widgets/keyboard_back_dismissal.dart';
import '../../widgets/storage_limit_feedback.dart';
import '../controllers/receipt_batch_controller.dart';
import '../controllers/receipt_batch_review_controller.dart';
import '../widgets/batch_item_card.dart';
import '../widgets/receipt_batch_item_form.dart';
import '../widgets/receipt_batch_review_dialogs.dart';
import '../widgets/receipt_batch_review_header.dart';
import '../widgets/receipt_batch_review_navigation.dart';
import '../widgets/receipt_transaction_date_picker.dart';

export '../controllers/receipt_batch_controller.dart';

class ReceiptBatchReviewPage extends StatefulWidget {
  const ReceiptBatchReviewPage({
    super.key,
    required this.items,
    this.stagingDirectory,
    this.onFinished,
    this.onItemSaved,
  });

  final List<ReceiptBatchItem> items;
  final Directory? stagingDirectory;
  final Future<void> Function()? onFinished;
  final Future<void> Function(ReceiptBatchItem item)? onItemSaved;

  @override
  State<ReceiptBatchReviewPage> createState() => _ReceiptBatchReviewPageState();
}

class _ReceiptBatchReviewPageState extends State<ReceiptBatchReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _merchantController = TextEditingController();
  final _pageController = PageController();

  late ReceiptBatchReviewController _controller;
  var _savingAll = false;
  var _ignoreNextPageChange = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.items);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void didUpdateWidget(covariant ReceiptBatchReviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.items, oldWidget.items)) {
      final categories = _controller.categories;
      _controller = _createController(widget.items)..loadCategories(categories);
    }
  }

  ReceiptBatchReviewController _createController(List<ReceiptBatchItem> items) {
    return ReceiptBatchReviewController(
      items: List<ReceiptBatchItem>.of(items),
      formKey: _formKey,
      amountController: _amountController,
      dateController: _dateController,
      merchantController: _merchantController,
    );
  }

  @override
  void dispose() {
    final stagingDir = widget.stagingDirectory;
    if (stagingDir != null) {
      unawaited(
        const BatchStagingService().deleteDirectorySilently(stagingDir),
      );
    }
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      unawaited(onFinished());
    }
    _amountController.dispose();
    _dateController.dispose();
    _merchantController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _controller.items;
    if (items.isEmpty) {
      return const EmptyReceiptBatchReview();
    }

    final currentIndex = _controller.currentIndex;
    final item = _controller.currentItem!;
    return PopScope(
      canPop:
          !_controller.saving &&
          !_controller.reprocessing &&
          !_controller.hasUnsavedItems(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _controller.saving || _controller.reprocessing) {
          return;
        }
        if (dismissKeyboardForBack(context)) {
          return;
        }
        unawaited(_confirmExitWithoutSaving());
      },
      child: Scaffold(
        appBar: ReceiptBatchReviewHeader(
          currentIndex: currentIndex,
          totalItems: items.length,
          canSaveAll: !_controller.saving && _controller.hasUnsavedItems(),
          onSaveAll: _confirmAll,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: BatchReviewSummary(items: items),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: _controller.saving
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: items.length,
                  onPageChanged: _changeItem,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (index != currentIndex) {
                      return const _InactiveBatchReviewPage();
                    }
                    if (item.status == ReceiptBatchItemStatus.error) {
                      return BatchItemErrorView(
                        item: item,
                        onRemove: () => unawaited(_removeItem(index)),
                        onRetry: () => _reprocessItem(index),
                        busy: _controller.reprocessing,
                      );
                    }
                    return ReceiptBatchItemForm(
                      item: item,
                      formKey: _formKey,
                      currentIndex: currentIndex,
                      categories: _controller.categories,
                      amountController: _amountController,
                      dateController: _dateController,
                      merchantController: _merchantController,
                      categoryId: _controller.categoryId,
                      receiptType: _controller.receiptType,
                      expense: _controller.expense,
                      paymentMethod: _controller.paymentMethod,
                      transactionDate: _controller.transactionDate,
                      onClearDate: _clearDate,
                      onSelectDate: () => unawaited(_selectDate()),
                      onReceiptTypeChanged: (value) =>
                          setState(() => _controller.receiptType = value),
                      onExpenseChanged: (value) =>
                          setState(() => _controller.expense = value),
                      onPaymentMethodChanged: (value) =>
                          setState(() => _controller.paymentMethod = value),
                      onCategoryChanged: (value) =>
                          setState(() => _controller.categoryId = value),
                    );
                  },
                ),
              ),
              ReceiptBatchReviewNavigation(
                currentIndex: currentIndex,
                totalItems: items.length,
                currentStatus: item.status,
                saving: _controller.saving,
                savingAll: _savingAll,
                onPrevious: _previous,
                onSaveCurrent: _confirmCurrent,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    final categories = await AppScope.of(context).categoryService.list();
    if (!mounted) {
      return;
    }
    _controller.loadCategories(categories);
    setState(() {});
  }

  void _changeItem(int index) {
    setState(() {
      if (_ignoreNextPageChange && index == _controller.currentIndex) {
        _ignoreNextPageChange = false;
        _controller.loadCurrentItem();
        return;
      }
      _ignoreNextPageChange = false;
      _controller.changeItem(index);
    });
  }

  Future<void> _confirmCurrent() async {
    if (_controller.saving ||
        !_controller.persistCurrentItemEdits(validate: true)) {
      return;
    }

    final item = _controller.currentItem;
    final receipt = item?.receipt;
    if (item == null || receipt == null) {
      return;
    }
    if (!await confirmSaveWithPendingFields(context, [receipt])) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _controller.saving = true);
    final saved = await _controller.saveCurrent(
      AppScope.of(context).receiptService,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      final onItemSaved = widget.onItemSaved;
      if (onItemSaved != null) {
        await onItemSaved(item);
        if (!mounted) {
          return;
        }
      }
    }
    if (_controller.items.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.loadCurrentItem();
    _ignoreNextPageChange = true;
    _pageController.jumpToPage(_controller.currentIndex);
    setState(() {});
  }

  Future<void> _selectDate() async {
    final selectedDate = await selectReceiptTransactionDate(
      context,
      initialDate: _controller.transactionDate,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _controller.setTransactionDate(selectedDate);
    });
  }

  void _clearDate() {
    setState(() {
      _controller.setTransactionDate(null);
    });
  }

  Future<void> _confirmAll() async {
    if (_controller.saving) {
      return;
    }
    if (!_controller.persistCurrentItemEdits(validate: true)) {
      return;
    }
    if (!await confirmSaveWithPendingFields(
      context,
      _controller.pendingReceipts(),
    )) {
      return;
    }
    if (!mounted) {
      return;
    }

    final total = _controller.pendingReceipts().length;
    setState(() {
      _savingAll = true;
      _controller.saving = true;
    });
    final ReceiptBatchReviewSaveAllResult result;
    try {
      result = await runWithBlockingProgress<ReceiptBatchReviewSaveAllResult>(
        context: context,
        title: 'Salvando comprovantes',
        message: 'Aguarde enquanto os comprovantes são salvos.',
        total: total,
        action: (progress) => _controller.saveAll(
          AppScope.of(context).receiptService,
          onProgress: (current) => progress.update(current: current),
        ),
      );
    } finally {
      _savingAll = false;
    }
    final onItemSaved = widget.onItemSaved;
    if (onItemSaved != null) {
      for (final item in _controller.items) {
        if (item.status == ReceiptBatchItemStatus.saved) {
          await onItemSaved(item);
        }
      }
    }
    if (!mounted) {
      return;
    }
    for (final error in result.errors) {
      if (isStorageLimitError(error)) {
        showStorageLimitSnackBar(context, error);
      }
    }
    setState(() {});
    if (!_controller.hasUnsavedItems() && !_controller.hasErrorItems()) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Itens com erro continuam disponíveis para revisão.'),
        ),
      );
    }
  }

  Future<void> _reprocessItem(int index) async {
    if (_controller.reprocessing) {
      return;
    }

    setState(() => _controller.reprocessing = true);
    final error = await _controller.reprocessItem(
      AppScope.of(context).receiptService,
      index,
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      if (isStorageLimitError(error)) {
        showStorageLimitSnackBar(context, error);
      }
    }
    setState(() {});
  }

  Future<void> _removeItem(int index) async {
    await _controller.removeItem(AppScope.of(context).receiptService, index);
    if (!mounted) {
      return;
    }
    if (_controller.items.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.jumpToPage(_controller.currentIndex);
    setState(() {});
  }

  void _previous() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmExitWithoutSaving() async {
    if (await confirmDiscardBatch(context) && mounted) {
      await _controller.discardPendingPreviews(
        AppScope.of(context).receiptService,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  }
}

class _InactiveBatchReviewPage extends StatelessWidget {
  const _InactiveBatchReviewPage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
