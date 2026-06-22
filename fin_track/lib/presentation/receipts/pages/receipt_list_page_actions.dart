part of 'receipt_list_page.dart';

extension _ReceiptListPageActions on ReceiptListPageState {
  ReceiptFilter _currentFilter() {
    final text = _searchController.text.trim();
    return ReceiptFilter(
      text: text.isEmpty ? null : text,
      categoryId: _controller.advancedFiltersActive
          ? _controller.categoryId
          : null,
      withoutCategory: _controller.advancedFiltersActive
          ? _controller.withoutCategory
          : false,
      startDate: _controller.advancedFiltersActive
          ? _controller.startDate
          : null,
      endDate: _controller.advancedFiltersActive ? _controller.endDate : null,
      type: _controller.advancedFiltersActive ? _controller.type : null,
      expense: _controller.advancedFiltersActive
          ? _controller.expenseFilter
          : null,
      sortOrder: _controller.sortOrder,
      sortDirection: _controller.sortDirection,
    );
  }

  void _changeSortOrder(ReceiptSort value) {
    _controller.changeSortOrder(value);
  }

  Future<void> _directImport() async {
    if (_controller.importing) {
      return;
    }
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;

    try {
      final service = AppScope.of(context).receiptService;
      final files = await _controller.importFiles(service);
      if (!mounted) {
        return;
      }
      if (files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(receiptsText.noImportFiles)));
        return;
      }
      final result = await Navigator.of(context).push<ReceiptFlowResult>(
        MaterialPageRoute<ReceiptFlowResult>(
          builder: (_) => files.length == 1
              ? ProcessingPage(file: files.first)
              : ReceiptBatchProcessingPage(files: files),
        ),
      );
      if (result == ReceiptFlowResult.saved && mounted) {
        resetSearchState();
      }
    } catch (error, stackTrace) {
      if (isOperationCancelled(error)) {
        return;
      }
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao importar comprovante pela lista',
      );
      if (mounted) {
        if (isStorageLimitError(error)) {
          showStorageLimitSnackBar(context, error, avoidScanButton: true);
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(receiptsText.importFailed)));
      }
    }
  }

  Future<void> _diagnoseSemanticSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _controller.diagnosingSearch) {
      return;
    }
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;

    try {
      final diagnostic = await _controller.diagnoseSemanticSearch(
        AppScope.of(context).receiptService,
        query,
      );
      if (!mounted) {
        return;
      }
      if (diagnostic == null) {
        return;
      }
      await showReceiptListDiagnosticDialog(context, diagnostic);
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao diagnosticar busca semântica',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(receiptsText.diagnoseFailed)));
    }
  }

  void _startSelection() {
    _controller.startSelection();
  }

  void _updateVisibleReceiptResults(bool hasVisibleReceipts) {
    if (_hasVisibleReceiptResults == hasVisibleReceipts || !mounted) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() => _hasVisibleReceiptResults = hasVisibleReceipts);
  }

  void _cancelSelection() {
    _controller.cancelSelection();
  }

  void _toggleSelection(Receipt receipt) {
    _controller.startSelection();
    _controller.toggleSelection(receipt);
  }

  void _selectVisible(List<Receipt> receipts) {
    _controller.startSelection();
    _controller.selectVisible(receipts);
  }

  Future<void> _shareSelected() async {
    if (_controller.selectedIds.isEmpty || _controller.processingSelection) {
      return;
    }
    final commonText = AppScope.of(context).appConfig.ui.common;
    try {
      await _controller.shareSelected(AppScope.of(context).receiptService);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(commonText.shareOpened)));
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao compartilhar comprovantes selecionados',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(commonText.shareFailed)));
    }
  }

  Future<void> _saveSelectedToDevice() async {
    if (_controller.selectedIds.isEmpty || _controller.processingSelection) {
      return;
    }
    final filesText = AppScope.of(context).appConfig.ui.receipts.files;
    try {
      final total = await _controller.saveSelectedToDevice(
        AppScope.of(context).receiptService,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total == 1 ? filesText.fileSaved : filesText.filesSaved,
          ),
        ),
      );
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext:
            'Falha ao salvar comprovantes selecionados no dispositivo',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(filesText.filesSaveFailed)));
    }
  }

  Future<void> _confirmSelectedDeletion() async {
    if (_controller.selectedIds.isEmpty || _controller.processingSelection) {
      return;
    }
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    final total = _controller.selectedIds.length;
    final confirm = await confirmReceiptListSelectionDeletion(context, total);
    if (!confirm || !mounted) {
      return;
    }

    final service = AppScope.of(context).receiptService;
    try {
      await runWithBlockingProgress<int>(
        context: context,
        title: receiptsText.deletingSelection,
        message: receiptsText.deletingSelectionMessage,
        total: total,
        action: (progress) {
          return _controller.deleteSelected(
            service,
            onProgress: (current) => progress.update(current: current),
          );
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total == 1
                ? receiptsText.deleted
                : receiptsText.deleteManyFor(total),
          ),
        ),
      );
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao excluir comprovantes selecionados',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(receiptsText.deleteFailed)));
    }
  }

  Future<void> _openFilters() async {
    final deps = AppScope.of(context);
    final categories = await deps.categoryService.list();
    if (!mounted) {
      return;
    }

    final selection = await showReceiptListFilterSheet(
      context,
      categories: categories,
      categoryId: _controller.categoryId,
      withoutCategory: _controller.withoutCategory,
      type: _controller.type,
      expense: _controller.expenseFilter,
      startDate: _controller.startDate,
      endDate: _controller.endDate,
    );
    if (selection == null || !mounted) {
      return;
    }
    _controller.applyFilters(
      selectedCategoryId: selection.categoryId,
      selectedType: selection.type,
      selectedExpense: selection.expense,
      selectedStart: selection.startDate,
      selectedEnd: selection.endDate,
      selectedCategoryName: selection.categoryName,
      activeLabel: selection.activeLabel,
    );
  }

  void _applyInitialFilter() {
    final filter = widget.initialFilter;
    _searchController.text = filter.text ?? '';
    _controller.applyInitialFilter(
      filter,
      activeLabel: widget.activeFilterLabel,
    );
  }

  void _clearActiveFilters() {
    _clearLocalFilters();
  }

  void _clearLocalFilters() {
    _controller.clearFilters();
  }
}
