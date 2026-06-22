import 'package:flutter/foundation.dart' hide Category;

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/services/i_category_service.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../widgets/category_style_widgets.dart';

class CategoriesController extends ChangeNotifier {
  final selectedCategoryIds = <int>{};
  List<int>? optimisticOrderIds;
  List<Category> currentCategories = const <Category>[];
  var selecting = false;
  var processingSelection = false;

  bool get hasSelection => selectedCategoryIds.isNotEmpty;

  void updateCurrentCategories(List<Category> categories) {
    currentCategories = categories;
  }

  List<Category> categoriesWithOptimisticOrder(List<Category> categories) {
    final order = optimisticOrderIds;
    if (order == null || categories.isEmpty) {
      return categories;
    }

    final currentIds = categories.map((category) => category.id).toList();
    if (_sameOrder(currentIds, order)) {
      optimisticOrderIds = null;
      return categories;
    }

    final orderableIds = currentIds.toSet();
    if (orderableIds.length != order.length ||
        !orderableIds.containsAll(order)) {
      return categories;
    }

    final byId = {for (final category in categories) category.id: category};
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> reorder(ICategoryService service, List<int> orderedIds) async {
    applyOptimisticOrder(orderedIds);
    try {
      await service.reorder(orderedIds);
    } catch (error, stackTrace) {
      clearOptimisticOrder();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Map<int, CategoryStats> calculateStats(List<Receipt> receipts) {
    final stats = <int, CategoryStats>{};
    for (final receipt in receipts) {
      final amount = receipt.extractedData?.amount ?? 0;
      final category = receipt.category;
      if (category != null) {
        final current = stats[category.id] ?? const CategoryStats();
        stats[category.id] = current.add(receipt, amount);
      }
    }
    return stats;
  }

  Future<CategoryDeletionPlan> planSelectedDeletion(
    ICategoryService service,
    List<Category> categories,
    Map<int, CategoryStats> stats,
  ) async {
    if (selectedCategoryIds.isEmpty || processingSelection) {
      return const CategoryDeletionPlan();
    }

    setProcessingSelection(true);
    final selectedCategories = categories
        .where((category) => selectedCategoryIds.contains(category.id))
        .toList();
    final free = <Category>[];
    final used = <Category>[];
    try {
      for (final category in selectedCategories) {
        final associatedTotal = stats[category.id]?.totalReceipts ?? 0;
        if (associatedTotal > 0 ||
            await service.hasAssociatedReceipts(category.id)) {
          used.add(category);
        } else {
          free.add(category);
        }
      }
      return CategoryDeletionPlan(free: free, used: used);
    } finally {
      setProcessingSelection(false);
    }
  }

  Future<void> deleteCategories(
    ICategoryService service,
    List<Category> categories, {
    ValueChanged<int>? onProgress,
  }) async {
    setProcessingSelection(true);
    try {
      for (var index = 0; index < categories.length; index++) {
        final category = categories[index];
        await service.delete(category.id);
        onProgress?.call(index + 1);
      }
      cancelSelection();
    } finally {
      setProcessingSelection(false);
    }
  }

  Future<bool> categoryHasAssociations({
    required ICategoryService categoryService,
    required IReceiptService receiptService,
    required Category category,
    required Map<int, CategoryStats> stats,
  }) async {
    final associatedTotal = stats[category.id]?.totalReceipts ?? 0;
    return associatedTotal > 0 ||
        await categoryService.hasAssociatedReceipts(category.id) ||
        (await receiptService.watchAll().first).any(
          (receipt) => receipt.category?.id == category.id,
        );
  }

  void applyOptimisticOrder(List<int> orderedIds) {
    optimisticOrderIds = orderedIds;
    notifyListeners();
  }

  void clearOptimisticOrder() {
    optimisticOrderIds = null;
    notifyListeners();
  }

  void setProcessingSelection(bool value) {
    if (processingSelection == value) {
      return;
    }
    processingSelection = value;
    notifyListeners();
  }

  void startSelection() {
    selecting = true;
    notifyListeners();
  }

  void cancelSelection() {
    selecting = false;
    processingSelection = false;
    selectedCategoryIds.clear();
    notifyListeners();
  }

  void toggleSelection(Category category) {
    if (!selectedCategoryIds.add(category.id)) {
      selectedCategoryIds.remove(category.id);
    }
    selecting = true;
    notifyListeners();
  }

  void selectVisible(List<Category> categories) {
    final visibleIds = categories.map((category) => category.id).toList();
    final allSelected = visibleIds.every(selectedCategoryIds.contains);
    selectedCategoryIds
      ..removeAll(allSelected ? visibleIds : const <int>[])
      ..addAll(allSelected ? const <int>[] : visibleIds);
    selecting = true;
    notifyListeners();
  }

  bool _sameOrder(List<int>? a, List<int> b) {
    if (a == null || a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

class CategoryDeletionPlan {
  const CategoryDeletionPlan({
    this.free = const <Category>[],
    this.used = const <Category>[],
  });

  final List<Category> free;
  final List<Category> used;
}
