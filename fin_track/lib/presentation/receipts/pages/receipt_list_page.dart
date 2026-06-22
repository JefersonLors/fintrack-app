import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/exceptions/operation_cancelled_exception.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../../infrastructure/diagnostics/error_handling.dart';
import '../../camera/processing_page.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/blocking_progress_dialog.dart';
import '../../widgets/storage_limit_feedback.dart';
import '../controllers/receipt_list_controller.dart';
import '../receipt_flow_result.dart';
import 'receipt_batch_processing_page.dart';

import '../widgets/receipt_list_content_widgets.dart';
import '../widgets/receipt_list_delete_dialog.dart';
import '../widgets/receipt_list_diagnostic_dialog.dart';
import '../widgets/receipt_list_filter_sheet.dart';

part 'receipt_list_page_actions.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({
    super.key,
    this.initialFilter = const ReceiptFilter(),
    this.activeFilterLabel,
    this.autoFocusSearch = false,
    this.showScaffold = true,
  });

  final ReceiptFilter initialFilter;
  final String? activeFilterLabel;
  final bool autoFocusSearch;
  final bool showScaffold;

  @override
  State<ReceiptListPage> createState() => ReceiptListPageState();
}

class ReceiptListPageState extends State<ReceiptListPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  late final ReceiptListController _controller;
  var _hasVisibleReceiptResults = false;

  @override
  void initState() {
    super.initState();
    _controller = ReceiptListController()..addListener(_onControllerChanged);
    _applyInitialFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.autoFocusSearch) {
        focusSearch();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReceiptListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.activeFilterLabel != widget.activeFilterLabel) {
      _applyInitialFilter();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void focusSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      FocusScope.of(context).requestFocus(_searchFocus);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) {
        return;
      }

      if (!_searchFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_searchFocus);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      await ignoreCleanupFailure(() async {
        await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      });
    });
  }

  void resetSearchState() {
    if (!mounted) {
      return;
    }

    _searchController.clear();
    _controller.resetSearchState();
    _searchFocus.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  bool get isSelecting => _controller.selecting;

  bool get hasActiveSearchState {
    return _searchController.text.trim().isNotEmpty ||
        _controller.advancedFiltersActive ||
        _controller.activeFilterLabel != null ||
        _controller.customSortEnabled;
  }

  bool clearSearchStateIfNeeded() {
    if (!hasActiveSearchState) {
      return false;
    }
    resetSearchState();
    return true;
  }

  bool cancelSelectionMode() {
    if (!_controller.selecting) {
      return false;
    }
    _cancelSelection();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final debugMode = AppScope.maybeOf(context)?.appConfig.debugMode ?? false;
    final content = SearchContent(
      filter: _currentFilter(),
      searchController: _searchController,
      searchFocus: _searchFocus,
      sortOrder: _controller.sortOrder,
      sortDirection: _controller.sortDirection,
      customSort: _controller.customSortEnabled,
      activeFilterLabel: _controller.activeFilterLabel,
      onSearchChanged: () => setState(() {}),
      onSortChanged: _changeSortOrder,
      onOpenFilters: _openFilters,
      onClearActiveFilter: _clearActiveFilters,
      onDiagnoseSearch: _diagnoseSemanticSearch,
      onImport: _directImport,
      importBusy: _controller.importing,
      diagnoseBusy: _controller.diagnosingSearch,
      debugMode: debugMode,
      selecting: _controller.selecting,
      processingSelection: _controller.processingSelection,
      selectedCount: _controller.selectedIds,
      onStartSelection: _startSelection,
      onToggleSelection: _toggleSelection,
      onSelectVisible: _selectVisible,
      onVisibleReceiptsChanged: _updateVisibleReceiptResults,
      onShareSelected: _shareSelected,
      onSaveSelected: _saveSelectedToDevice,
      onDeleteSelected: _confirmSelectedDeletion,
      automaticallyImplyLeading: widget.showScaffold,
      showSelectionAction: _hasVisibleReceiptResults,
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(body: SafeArea(bottom: false, child: content));
  }
}
