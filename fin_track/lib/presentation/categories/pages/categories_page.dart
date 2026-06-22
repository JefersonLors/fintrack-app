import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../receipts/pages/receipt_list_page.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/blocking_progress_dialog.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/fin_track_page_header.dart';
import '../../widgets/state_views.dart';
import '../controllers/categories_controller.dart';

import '../widgets/category_dialog.dart';
import '../widgets/category_list_widgets.dart';
import '../widgets/category_style_widgets.dart';

part 'categories_page_actions.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  final _searchController = TextEditingController();
  late final CategoriesController _controller;
  Map<int, CategoryStats> _currentStats = const <int, CategoryStats>{};
  var _hasVisibleCategoryResults = false;

  @override
  void initState() {
    super.initState();
    _controller = CategoriesController()..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final categoriesText = deps.appConfig.ui.categories;
    return Scaffold(
      appBar: FinTrackPageHeader(
        title: Text(categoriesText.text('title')),
        actions: [
          if (_controller.selecting)
            IconButton(
              tooltip: categoriesText.text('deleteSelectedTooltip'),
              onPressed:
                  _controller.selectedCategoryIds.isEmpty ||
                      _controller.processingSelection
                  ? null
                  : _confirmCurrentSelectedDeletion,
              icon: _controller.processingSelection
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.delete_outline,
                      color: context.finTrackColors.danger,
                    ),
            )
          else if (_hasVisibleCategoryResults)
            IconButton(
              tooltip: categoriesText.text('selectCategoriesTooltip'),
              onPressed: _controller.processingSelection
                  ? null
                  : _startSelection,
              icon: Icon(Icons.checklist_outlined),
            ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: deps.categoryService.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return LoadingView(message: categoriesText.text('loading'));
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: categoriesText.text('loadError'),
              onRetry: () {},
            );
          }

          final databaseCategories = snapshot.data ?? const <Category>[];
          final categories = _controller.categoriesWithOptimisticOrder(
            databaseCategories,
          );
          return StreamBuilder<List<Receipt>>(
            stream: deps.receiptService.watchAll(),
            builder: (context, receiptsSnapshot) {
              if (receiptsSnapshot.connectionState == ConnectionState.waiting &&
                  !receiptsSnapshot.hasData) {
                return LoadingView(message: categoriesText.text('loading'));
              }
              if (receiptsSnapshot.hasError) {
                return ErrorStateView(
                  message: categoriesText.text('usageLoadError'),
                  onRetry: () => setState(() {}),
                );
              }

              final stats = _controller.calculateStats(
                receiptsSnapshot.data ?? const <Receipt>[],
              );
              _controller.updateCurrentCategories(categories);
              _currentStats = stats;
              final list = CategoryList(
                categories: categories,
                stats: stats,
                searchController: _searchController,
                selecting: _controller.selecting,
                selectedCategoryIds: _controller.selectedCategoryIds,
                onSearchChanged: () => setState(() {}),
                onOpen: (category) {
                  if (_controller.selecting) {
                    _toggleSelection(category);
                  } else {
                    _openCategoryReceipts(context, category);
                  }
                },
                onEdit: (category) => _openDialog(context, category: category),
                onDelete: (category) => _delete(context, category),
                onStartSelection: _startSelection,
                onToggleSelection: _toggleSelection,
                onSelectVisible: _selectVisible,
                onVisibleCategoriesChanged: _updateVisibleCategoryResults,
                onReorder: (orderedIds) async {
                  try {
                    await _controller.reorder(deps.categoryService, orderedIds);
                  } on Object {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(categoriesText.text('reorderFailed')),
                        ),
                      );
                    }
                  }
                },
              );
              return list;
            },
          );
        },
      ),
      floatingActionButton: _controller.selecting
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: FloatingActionButton.extended(
                onPressed: () => _openDialog(context),
                icon: Icon(Icons.add),
                label: Text(categoriesText.text('newAction')),
              ),
            ),
    );
  }

  bool get isSelecting => _controller.selecting;

  bool cancelSelectionMode() {
    if (!_controller.selecting) {
      return false;
    }
    _cancelSelection();
    return true;
  }

  bool get hasActiveSearchState => _searchController.text.trim().isNotEmpty;

  bool clearSearchStateIfNeeded() {
    if (!hasActiveSearchState) {
      return false;
    }
    setState(_searchController.clear);
    return true;
  }
}
