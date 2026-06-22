import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/state_views.dart';
import 'category_card_widgets.dart';
import 'category_style_widgets.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({
    super.key,
    required this.categories,
    required this.stats,
    required this.searchController,
    required this.selecting,
    required this.selectedCategoryIds,
    required this.onSearchChanged,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onStartSelection,
    required this.onToggleSelection,
    required this.onSelectVisible,
    required this.onVisibleCategoriesChanged,
    required this.onReorder,
  });

  final List<Category> categories;
  final Map<int, CategoryStats> stats;
  final TextEditingController searchController;
  final bool selecting;
  final Set<int> selectedCategoryIds;
  final VoidCallback onSearchChanged;
  final ValueChanged<Category> onOpen;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;
  final VoidCallback onStartSelection;
  final ValueChanged<Category> onToggleSelection;
  final ValueChanged<List<Category>> onSelectVisible;
  final ValueChanged<bool> onVisibleCategoriesChanged;
  final ValueChanged<List<int>> onReorder;

  @override
  Widget build(BuildContext context) {
    final categoriesText = AppScope.of(context).appConfig.ui.categories;
    final query = searchController.text.trim();
    final filtered = query.isEmpty
        ? categories
        : categories
              .where((category) => _categoryMatches(category, query))
              .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onVisibleCategoriesChanged(filtered.isNotEmpty);
    });

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategorySearchHeader(
          searchController: searchController,
          query: query,
          onSearchChanged: onSearchChanged,
          total: categories.length,
          visible: filtered.length,
          selecting: selecting,
          selectedCategoryIds: selectedCategoryIds.length,
          allSelected:
              filtered.isNotEmpty &&
              filtered.every(
                (category) => selectedCategoryIds.contains(category.id),
              ),
          onSelectVisible: filtered.isEmpty
              ? null
              : () => onSelectVisible(filtered),
        ),
        if (categories.isNotEmpty && filtered.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 48),
            child: EmptyView(
              title: categoriesText.text('emptySearchTitle'),
              message: categoriesText.text('emptySearchMessage'),
              icon: Icons.manage_search_outlined,
            ),
          ),
      ],
    );

    if (categories.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: header,
          ),
          Expanded(
            child: EmptyView(
              title: categoriesText.text('emptyTitle'),
              message: categoriesText.text('emptyMessage'),
              icon: Icons.category_outlined,
            ),
          ),
          const SizedBox(height: 88),
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      buildDefaultDragHandles: false,
      header: Column(mainAxisSize: MainAxisSize.min, children: [header]),
      itemCount: filtered.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(
              begin: 0,
              end: 6,
            ).evaluate(animation);
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: child,
            );
          },
          child: child,
        );
      },
      onReorderItem: (oldIndex, newIndex) {
        final reordered = List<Category>.of(filtered);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        onReorder(reordered.map((category) => category.id).toList());
      },
      itemBuilder: (context, index) {
        final category = filtered[index];
        return CategoryCard(
          key: ValueKey(category.id),
          category: category,
          stats: stats[category.id] ?? const CategoryStats(),
          selecting: selecting,
          selected: selectedCategoryIds.contains(category.id),
          onOpen: () => onOpen(category),
          onEdit: () => onEdit(category),
          onDelete: () => onDelete(category),
          onLongPress: () {
            onStartSelection();
            onToggleSelection(category);
          },
          dragHandle: selecting
              ? null
              : query.isNotEmpty
              ? null
              : ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: categoriesText.text('dragToReorder'),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(child: Icon(Icons.drag_handle)),
                    ),
                  ),
                ),
        );
      },
    );
  }

  bool _categoryMatches(Category category, String query) {
    final normalized = normalizeCategoryText(query);
    return normalizeCategoryText(
      '${category.name} ${category.description ?? ''}',
    ).contains(normalized);
  }
}

class _CategorySearchHeader extends StatelessWidget {
  const _CategorySearchHeader({
    required this.searchController,
    required this.query,
    required this.onSearchChanged,
    required this.total,
    required this.visible,
    required this.selecting,
    required this.selectedCategoryIds,
    required this.allSelected,
    required this.onSelectVisible,
  });

  final TextEditingController searchController;
  final String query;
  final VoidCallback onSearchChanged;
  final int total;
  final int visible;
  final bool selecting;
  final int selectedCategoryIds;
  final bool allSelected;
  final VoidCallback? onSelectVisible;

  @override
  Widget build(BuildContext context) {
    final categoriesText = AppScope.of(context).appConfig.ui.categories;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: categoriesText.text('searchHint'),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: categoriesText.text('clearSearch'),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged();
                      },
                      icon: Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => onSearchChanged(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: _CategorySummary(
            total: total,
            visible: visible,
            selecting: selecting,
            selectedCategoryIds: selectedCategoryIds,
            allSelected: allSelected,
            onSelectVisible: onSelectVisible,
          ),
        ),
      ],
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({
    required this.total,
    required this.visible,
    required this.selecting,
    required this.selectedCategoryIds,
    required this.allSelected,
    required this.onSelectVisible,
  });

  final int total;
  final int visible;
  final bool selecting;
  final int selectedCategoryIds;
  final bool allSelected;
  final VoidCallback? onSelectVisible;

  @override
  Widget build(BuildContext context) {
    final categoriesText = AppScope.of(context).appConfig.ui.categories;
    final label = selecting
        ? '$selectedCategoryIds ${selectedCategoryIds == 1 ? categoriesText.text('selectedSingular') : categoriesText.text('selectedPlural')}'
        : total == visible
        ? '$total ${total == 1 ? categoriesText.text('countSingular') : categoriesText.text('countPlural')}'
        : '$visible de $total ${categoriesText.text('countPlural')}';
    return Row(
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (selecting) ...[
          const Spacer(),
          _SelectAllVisibleControl(
            selected: allSelected,
            onPressed: onSelectVisible,
          ),
        ],
      ],
    );
  }
}

class _SelectAllVisibleControl extends StatelessWidget {
  const _SelectAllVisibleControl({required this.selected, this.onPressed});

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final categoriesText = AppScope.of(context).appConfig.ui.categories;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              categoriesText.text('all'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              selected
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
