import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/state_views.dart';
import '../receipt_list_logic.dart';
import 'receipt_result_list.dart';

export 'receipt_sort_bar.dart';

const _receiptPageSize = 30;

class ReceiptResults extends StatefulWidget {
  const ReceiptResults({
    super.key,
    required this.filter,
    required this.customSort,
    required this.deferReloads,
    required this.onRetry,
    required this.selecting,
    required this.selectedCount,
    required this.onToggleSelection,
    required this.onSelectVisible,
    this.onVisibleReceiptsChanged,
  });

  final ReceiptFilter filter;
  final bool customSort;
  final bool deferReloads;
  final VoidCallback onRetry;
  final bool selecting;
  final Set<int> selectedCount;
  final ValueChanged<Receipt> onToggleSelection;
  final ValueChanged<List<Receipt>> onSelectVisible;
  final ValueChanged<bool>? onVisibleReceiptsChanged;

  @override
  State<ReceiptResults> createState() => _ReceiptResultsState();
}

class _ReceiptResultsState extends State<ReceiptResults> {
  final _scrollController = ScrollController();
  final _receipts = <Receipt>[];
  StreamSubscription<List<Receipt>>? _changesSubscription;
  Object? _initialError;
  Object? _loadMoreError;
  var _loadingInitial = true;
  var _loadingMore = false;
  var _hasMore = true;
  var _requestVersion = 0;
  var _reloadPending = false;
  bool? _lastVisibleReceipts;
  late _ReceiptResultSignature _signature;

  @override
  void initState() {
    super.initState();
    _signature = _ReceiptResultSignature.from(widget.filter, widget.customSort);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _changesSubscription ??= AppScope.of(context).receiptService
        .watchAll()
        .listen((_) {
          if (widget.deferReloads) {
            _reloadPending = true;
            return;
          }
          _reloadFirstPage(preserveExisting: true);
        });
    if (_loadingInitial && _receipts.isEmpty) {
      _reloadFirstPage();
    }
  }

  @override
  void didUpdateWidget(covariant ReceiptResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _ReceiptResultSignature.from(
      widget.filter,
      widget.customSort,
    );
    if (nextSignature != _signature) {
      final preserveExisting = _signature.hasSameResultSet(nextSignature);
      _signature = nextSignature;
      _reloadPending = false;
      _reloadFirstPage(preserveExisting: preserveExisting);
      return;
    }
    if (oldWidget.deferReloads && !widget.deferReloads && _reloadPending) {
      _reloadPending = false;
      _reloadFirstPage(preserveExisting: true);
    }
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter < 420) {
      _loadNextPage();
    }
  }

  Future<void> _reloadFirstPage({bool preserveExisting = false}) async {
    final request = ++_requestVersion;
    setState(() {
      _loadingInitial = !preserveExisting;
      _loadingMore = false;
      _initialError = null;
      _loadMoreError = null;
      _hasMore = true;
      if (!preserveExisting) {
        _receipts.clear();
      }
    });
    if (!preserveExisting) {
      _notifyVisibleReceiptsChanged(false);
    }

    try {
      final page = await _loadPage(offset: 0);
      if (!mounted || request != _requestVersion) {
        return;
      }
      setState(() {
        _receipts
          ..clear()
          ..addAll(page);
        _hasMore = page.length == _receiptPageSize;
        _loadingInitial = false;
      });
      _notifyVisibleReceiptsChanged(_receipts.isNotEmpty);
    } catch (error) {
      if (!mounted || request != _requestVersion) {
        return;
      }
      setState(() {
        _initialError = error;
        _loadingInitial = false;
      });
      _notifyVisibleReceiptsChanged(_receipts.isNotEmpty);
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingInitial || _loadingMore || !_hasMore) {
      return;
    }
    final request = _requestVersion;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await _loadPage(offset: _receipts.length);
      if (!mounted || request != _requestVersion) {
        return;
      }
      setState(() {
        _receipts.addAll(page);
        _hasMore = page.length == _receiptPageSize;
        _loadingMore = false;
      });
      _notifyVisibleReceiptsChanged(_receipts.isNotEmpty);
    } catch (error) {
      if (!mounted || request != _requestVersion) {
        return;
      }
      setState(() {
        _loadMoreError = error;
        _loadingMore = false;
      });
    }
  }

  Future<List<Receipt>> _loadPage({required int offset}) async {
    final service = AppScope.of(context).receiptService;
    final query = widget.filter.text?.trim() ?? '';
    if (query.isEmpty) {
      return service.findByFilters(
        widget.filter.copyWith(limit: _receiptPageSize, offset: offset),
      );
    }

    final allMatches = await service.search(query);
    final filtered = applyAdvancedReceiptFilters(allMatches, widget.filter);
    final ordered = widget.customSort
        ? sortReceipts(
            filtered,
            widget.filter.sortOrder,
            widget.filter.sortDirection,
          )
        : filtered;
    return ordered.skip(offset).take(_receiptPageSize).toList();
  }

  void _notifyVisibleReceiptsChanged(bool hasVisibleReceipts) {
    if (_lastVisibleReceipts == hasVisibleReceipts) {
      return;
    }
    _lastVisibleReceipts = hasVisibleReceipts;
    final onChanged = widget.onVisibleReceiptsChanged;
    if (onChanged == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        onChanged(hasVisibleReceipts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    final query = widget.filter.text?.trim() ?? '';

    if (_loadingInitial) {
      return LoadingView(
        message: query.isEmpty
            ? receiptsText.loadingReceipts
            : receiptsText.searchingReceipts,
      );
    }

    if (_initialError != null) {
      return ErrorStateView(
        message: query.isEmpty
            ? receiptsText.loadReceiptsFailed
            : receiptsText.searchFailed,
        onRetry: widget.onRetry,
      );
    }

    return ReceiptResultList(
      receipts: _receipts,
      filter: widget.filter,
      hasMore: _hasMore,
      loadingMore: _loadingMore,
      loadMoreError: _loadMoreError,
      onRetryLoadMore: _loadNextPage,
      scrollController: _scrollController,
      selecting: widget.selecting,
      selectedCount: widget.selectedCount,
      onToggleSelection: widget.onToggleSelection,
      onSelectVisible: widget.onSelectVisible,
      query: query,
    );
  }
}

class _ReceiptResultSignature {
  const _ReceiptResultSignature({
    required this.text,
    required this.categoryId,
    required this.withoutCategory,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.expense,
    required this.sortOrder,
    required this.sortDirection,
    required this.customSort,
  });

  factory _ReceiptResultSignature.from(ReceiptFilter filter, bool customSort) {
    return _ReceiptResultSignature(
      text: filter.text?.trim(),
      categoryId: filter.categoryId,
      withoutCategory: filter.withoutCategory,
      startDate: filter.startDate,
      endDate: filter.endDate,
      type: filter.type,
      expense: filter.expense,
      sortOrder: filter.sortOrder,
      sortDirection: filter.sortDirection,
      customSort: customSort,
    );
  }

  final String? text;
  final int? categoryId;
  final bool withoutCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final ReceiptType? type;
  final bool? expense;
  final ReceiptSort sortOrder;
  final SortDirection sortDirection;
  final bool customSort;

  @override
  bool operator ==(Object other) {
    return other is _ReceiptResultSignature &&
        other.text == text &&
        other.categoryId == categoryId &&
        other.withoutCategory == withoutCategory &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.type == type &&
        other.expense == expense &&
        other.sortOrder == sortOrder &&
        other.sortDirection == sortDirection &&
        other.customSort == customSort;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      categoryId,
      withoutCategory,
      startDate,
      endDate,
      type,
      expense,
      sortOrder,
      sortDirection,
      customSort,
    );
  }

  bool hasSameResultSet(_ReceiptResultSignature other) {
    return other.text == text &&
        other.categoryId == categoryId &&
        other.withoutCategory == withoutCategory &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.type == type &&
        other.expense == expense;
  }
}
