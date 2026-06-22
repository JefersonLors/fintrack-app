part of 'categories_page.dart';

extension _CategoriesPageActions on CategoriesPageState {
  void _startSelection() {
    _controller.startSelection();
  }

  void _updateVisibleCategoryResults(bool hasVisibleCategories) {
    if (_hasVisibleCategoryResults == hasVisibleCategories || !mounted) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    setState(() => _hasVisibleCategoryResults = hasVisibleCategories);
  }

  void _cancelSelection() {
    _controller.cancelSelection();
  }

  void _toggleSelection(Category category) {
    _controller.startSelection();
    _controller.toggleSelection(category);
  }

  void _selectVisible(List<Category> categories) {
    _controller.startSelection();
    _controller.selectVisible(categories);
  }

  Future<void> _confirmSelectedDeletion(
    List<Category> categories,
    Map<int, CategoryStats> stats,
  ) async {
    if (_controller.selectedCategoryIds.isEmpty ||
        _controller.processingSelection) {
      return;
    }
    final deps = AppScope.of(context);
    final service = deps.categoryService;
    final commonText = deps.appConfig.ui.common;
    final categoriesText = deps.appConfig.ui.categories;
    final plan = await _controller.planSelectedDeletion(
      service,
      categories,
      stats,
    );
    final free = plan.free;
    final used = plan.used;
    if (!mounted) {
      return;
    }
    if (used.isNotEmpty) {
      await _showAssociatedCategories(context, used, plural: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          free.length == 1
              ? categoriesText.text('deleteOneTitle')
              : categoriesText.format('deleteManyTitle', {
                  'total': free.length,
                }),
        ),
        content: Text(
          free.length == 1
              ? categoriesText.text('deleteOneMessage')
              : categoriesText.text('deleteManyMessage'),
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(commonText.cancel),
              ),
              FilledButton.icon(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.delete_outline),
                label: Text(commonText.delete),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }

    await runWithBlockingProgress<void>(
      context: context,
      title: categoriesText.text('deletingSelection'),
      message: categoriesText.text('deletingSelectionMessage'),
      total: free.length,
      action: (progress) {
        return _controller.deleteCategories(
          service,
          free,
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
          free.length == 1
              ? categoriesText.text('deletedOne')
              : categoriesText.format('deletedMany', {'total': free.length}),
        ),
      ),
    );
  }

  Future<void> _confirmCurrentSelectedDeletion() async {
    if (_controller.selectedCategoryIds.isEmpty ||
        _controller.processingSelection) {
      return;
    }
    final deps = AppScope.of(context);
    var categories = _controller.currentCategories;
    var stats = _currentStats;
    if (categories.isEmpty) {
      categories = await deps.categoryService.list();
      final receipts = await deps.receiptService.watchAll().first;
      stats = _controller.calculateStats(receipts);
    }
    if (!mounted) {
      return;
    }
    await _confirmSelectedDeletion(categories, stats);
  }

  void _openCategoryReceipts(BuildContext context, Category category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptListPage(
          initialFilter: ReceiptFilter(categoryId: category.id),
          activeFilterLabel:
              '${AppScope.of(context).appConfig.ui.categories.text('filterLabelPrefix')}: ${category.name}',
        ),
      ),
    );
  }

  Future<void> _openDialog(BuildContext context, {Category? category}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CategoryDialog(category: category),
    );

    if (saved == true && context.mounted) {
      final categoriesText = AppScope.of(context).appConfig.ui.categories;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(categoriesText.text('saved'))));
    }
  }

  Future<void> _delete(BuildContext context, Category category) async {
    final deps = AppScope.of(context);
    final service = deps.categoryService;
    final hasAssociation = await _controller.categoryHasAssociations(
      categoryService: service,
      receiptService: deps.receiptService,
      category: category,
      stats: _currentStats,
    );
    if (!context.mounted) {
      return;
    }
    if (hasAssociation) {
      await _showAssociatedCategories(context, [category]);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deps.appConfig.ui.categories.text('deleteOneTitle')),
        content: Text(
          deps.appConfig.ui.categories.format('deleteNamedMessage', {
            'name': category.name,
          }),
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(deps.appConfig.ui.common.cancel),
              ),
              FilledButton.icon(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.delete_outline),
                label: Text(deps.appConfig.ui.common.delete),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) {
      return;
    }

    try {
      await service.delete(category.id);
    } on FormatException {
      if (context.mounted) {
        await _showAssociatedCategories(context, [category]);
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deps.appConfig.ui.categories.text('deletedOne')),
        ),
      );
    }
  }

  Future<void> _showAssociatedCategories(
    BuildContext context,
    List<Category> categories, {
    bool plural = false,
  }) {
    final names = categories.map((category) => category.name).join(', ');
    final single = categories.length == 1 && !plural;
    final texts = AppScope.of(context).appConfig.ui.categories;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.link_outlined, color: context.finTrackColors.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                single
                    ? texts.text('categoryInUse')
                    : texts.text('categoriesInUse'),
              ),
            ),
          ],
        ),
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: context.finTrackColors.surfaceAlt,
            border: Border.all(color: context.finTrackColors.borderStrong),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              single
                  ? texts.format('categoryInUseMessage', {'names': names})
                  : texts.format('categoriesInUseMessage', {'names': names}),
            ),
          ),
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              if (single)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openCategoryReceipts(context, categories.single);
                  },
                  icon: Icon(Icons.manage_search_outlined),
                  label: Text(texts.text('viewReceipts')),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(texts.text('understood')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
