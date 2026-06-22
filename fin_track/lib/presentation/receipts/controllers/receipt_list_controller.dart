import 'package:flutter/foundation.dart' hide Category;
import 'dart:io';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../../../domain/value_objects/receipt_filter.dart';

class ReceiptListController extends ChangeNotifier {
  ReceiptListController({
    ReceiptFilter initialFilter = const ReceiptFilter(),
    String? activeFilterLabel,
  }) : _activeFilterLabel = activeFilterLabel {
    applyInitialFilter(initialFilter);
  }

  var sortOrder = ReceiptSort.date;
  var sortDirection = SortDirection.descending;
  int? categoryId;
  var withoutCategory = false;
  ReceiptType? type;
  bool? expenseFilter;
  DateTime? startDate;
  DateTime? endDate;
  var advancedFiltersActive = false;
  var customSortEnabled = false;
  var importing = false;
  var diagnosingSearch = false;
  var selecting = false;
  var processingSelection = false;
  final selectedIds = <int>{};

  String? _activeFilterLabel;

  String? get activeFilterLabel => _activeFilterLabel;

  bool get hasSelection => selectedIds.isNotEmpty;

  void applyInitialFilter(ReceiptFilter filter, {String? activeLabel}) {
    sortOrder = filter.sortOrder;
    sortDirection = filter.sortDirection;
    final applyAdvancedFilters = activeLabel != null;
    categoryId = applyAdvancedFilters ? filter.categoryId : null;
    withoutCategory = applyAdvancedFilters ? filter.withoutCategory : false;
    if (withoutCategory) {
      categoryId = null;
    }
    type = applyAdvancedFilters ? filter.type : null;
    expenseFilter = applyAdvancedFilters ? filter.expense : null;
    startDate = applyAdvancedFilters ? filter.startDate : null;
    endDate = applyAdvancedFilters ? filter.endDate : null;
    _activeFilterLabel = activeLabel;
    advancedFiltersActive = applyAdvancedFilters && _hasAdvancedFilter;
    notifyListeners();
  }

  void changeSortOrder(ReceiptSort value) {
    if (customSortEnabled && sortOrder == value) {
      sortDirection = sortDirection.toggled;
    } else {
      sortOrder = value;
      sortDirection = SortDirection.ascending;
    }
    customSortEnabled = true;
    notifyListeners();
  }

  void startSelection() {
    selecting = true;
    notifyListeners();
  }

  void cancelSelection() {
    selecting = false;
    processingSelection = false;
    selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(Receipt receipt) {
    if (!selectedIds.add(receipt.id)) {
      selectedIds.remove(receipt.id);
    }
    selecting = true;
    notifyListeners();
  }

  void selectVisible(List<Receipt> receipts) {
    final visibleIds = receipts.map((receipt) => receipt.id).toList();
    final allSelected = visibleIds.every(selectedIds.contains);
    if (allSelected) {
      selectedIds.removeAll(visibleIds);
    } else {
      selectedIds.addAll(visibleIds);
    }
    selecting = true;
    notifyListeners();
  }

  void resetSearchState() {
    sortOrder = ReceiptSort.date;
    sortDirection = SortDirection.descending;
    clearFilters();
    customSortEnabled = false;
  }

  void clearFilters() {
    categoryId = null;
    withoutCategory = false;
    type = null;
    expenseFilter = null;
    startDate = null;
    endDate = null;
    advancedFiltersActive = false;
    _activeFilterLabel = null;
    notifyListeners();
  }

  void applyFilters({
    required int? selectedCategoryId,
    required ReceiptType? selectedType,
    required bool? selectedExpense,
    required DateTime? selectedStart,
    required DateTime? selectedEnd,
    required String? selectedCategoryName,
    String? activeLabel,
  }) {
    categoryId = selectedCategoryId;
    if (categoryId != null) {
      withoutCategory = false;
    }
    type = selectedType;
    expenseFilter = selectedExpense;
    startDate = selectedStart;
    endDate = selectedEnd;
    advancedFiltersActive = _hasAdvancedFilter;
    _activeFilterLabel =
        activeLabel ?? buildFilterLabel(categoryName: selectedCategoryName);
    notifyListeners();
  }

  void setImporting(bool value) {
    if (importing == value) {
      return;
    }
    importing = value;
    notifyListeners();
  }

  void setDiagnosingSearch(bool value) {
    if (diagnosingSearch == value) {
      return;
    }
    diagnosingSearch = value;
    notifyListeners();
  }

  void setProcessingSelection(bool value) {
    if (processingSelection == value) {
      return;
    }
    processingSelection = value;
    notifyListeners();
  }

  String? buildFilterLabel({String? categoryName}) {
    final parts = <String>[
      ?categoryName,
      if (withoutCategory) 'Sem categoria',
      if (type != null) type!.label,
      if (expenseFilter == true) 'Despesas',
      if (expenseFilter == false) 'Receitas',
      if (startDate != null || endDate != null) 'Período',
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String? selectedCategoryName(List<Category> categories, int? id) {
    if (id == null) {
      return null;
    }
    for (final category in categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return null;
  }

  Future<List<File>> importFiles(IReceiptService service) async {
    if (importing) {
      return const <File>[];
    }

    setImporting(true);
    try {
      final files = await service.importFiles();
      for (final file in files) {
        await service.validateSpaceForNewReceipt(file);
      }
      return files;
    } finally {
      setImporting(false);
    }
  }

  Future<String?> diagnoseSemanticSearch(
    IReceiptService service,
    String query,
  ) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || diagnosingSearch) {
      return null;
    }

    setDiagnosingSearch(true);
    try {
      return service.diagnoseSemanticSearch(trimmedQuery);
    } finally {
      setDiagnosingSearch(false);
    }
  }

  Future<void> shareSelected(IReceiptService service) async {
    if (selectedIds.isEmpty || processingSelection) {
      return;
    }

    setProcessingSelection(true);
    try {
      await service.shareImages(selectedIds.toList());
      cancelSelection();
    } finally {
      setProcessingSelection(false);
    }
  }

  Future<int> saveSelectedToDevice(IReceiptService service) async {
    if (selectedIds.isEmpty || processingSelection) {
      return 0;
    }

    final total = selectedIds.length;
    setProcessingSelection(true);
    try {
      await service.saveImagesToDevice(selectedIds.toList());
      cancelSelection();
      return total;
    } finally {
      setProcessingSelection(false);
    }
  }

  Future<int> deleteSelected(
    IReceiptService service, {
    ValueChanged<int>? onProgress,
  }) async {
    if (selectedIds.isEmpty || processingSelection) {
      return 0;
    }

    final ids = selectedIds.toList();
    setProcessingSelection(true);
    try {
      for (var index = 0; index < ids.length; index++) {
        final id = ids[index];
        await service.delete(id);
        onProgress?.call(index + 1);
      }
      cancelSelection();
      return ids.length;
    } finally {
      setProcessingSelection(false);
    }
  }

  bool get _hasAdvancedFilter {
    return categoryId != null ||
        withoutCategory ||
        type != null ||
        expenseFilter != null ||
        startDate != null ||
        endDate != null;
  }
}
