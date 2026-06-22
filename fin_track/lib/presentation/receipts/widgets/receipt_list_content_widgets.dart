import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import 'receipt_list_toolbar_widgets.dart';
import 'receipt_list_result_widgets.dart';

class SearchContent extends StatelessWidget {
  const SearchContent({
    super.key,
    required this.filter,
    required this.searchController,
    required this.searchFocus,
    required this.sortOrder,
    required this.sortDirection,
    required this.customSort,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onOpenFilters,
    required this.onClearActiveFilter,
    required this.onDiagnoseSearch,
    required this.onImport,
    required this.importBusy,
    required this.diagnoseBusy,
    required this.debugMode,
    required this.selecting,
    required this.processingSelection,
    required this.selectedCount,
    required this.onStartSelection,
    required this.onToggleSelection,
    required this.onSelectVisible,
    required this.onVisibleReceiptsChanged,
    required this.onShareSelected,
    required this.onSaveSelected,
    required this.onDeleteSelected,
    this.activeFilterLabel,
    this.automaticallyImplyLeading = false,
    this.showSelectionAction = true,
  });

  final ReceiptFilter filter;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ReceiptSort sortOrder;
  final SortDirection sortDirection;
  final bool customSort;
  final String? activeFilterLabel;
  final VoidCallback onSearchChanged;
  final ValueChanged<ReceiptSort> onSortChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearActiveFilter;
  final VoidCallback onDiagnoseSearch;
  final VoidCallback onImport;
  final bool importBusy;
  final bool diagnoseBusy;
  final bool debugMode;
  final bool selecting;
  final bool processingSelection;
  final Set<int> selectedCount;
  final VoidCallback onStartSelection;
  final ValueChanged<Receipt> onToggleSelection;
  final ValueChanged<List<Receipt>> onSelectVisible;
  final ValueChanged<bool> onVisibleReceiptsChanged;
  final VoidCallback onShareSelected;
  final VoidCallback onSaveSelected;
  final VoidCallback onDeleteSelected;
  final bool automaticallyImplyLeading;
  final bool showSelectionAction;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim();
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    return Column(
      children: [
        DefaultListToolbar(
          automaticallyImplyLeading: automaticallyImplyLeading,
          showSelectionAction: showSelectionAction,
          importBusy: importBusy,
          selecting: selecting,
          processingSelection: processingSelection,
          selectedCount: selectedCount.length,
          onImport: onImport,
          onOpenFilters: onOpenFilters,
          onStartSelection: onStartSelection,
          onShareSelected: onShareSelected,
          onSaveSelected: onSaveSelected,
          onDeleteSelected: onDeleteSelected,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                color: context.finTrackColors.info,
              ),
              hintText: receiptsText.searchHint,
              helperText: selecting ? null : receiptsText.searchHelper,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (debugMode && query.isNotEmpty)
                    IconButton(
                      tooltip: receiptsText.diagnoseSemanticSearch,
                      onPressed: diagnoseBusy ? null : onDiagnoseSearch,
                      icon: diagnoseBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.science_outlined,
                              color: context.finTrackColors.info,
                            ),
                    ),
                  if (query.isNotEmpty)
                    IconButton(
                      tooltip: receiptsText.clearSearch,
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged();
                      },
                      icon: Icon(
                        Icons.close,
                        color: context.finTrackColors.info,
                      ),
                    ),
                ],
              ),
            ),
            onChanged: (_) => onSearchChanged(),
          ),
        ),
        if (!selecting) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SortBar(
                sortOrder: sortOrder,
                sortDirection: sortDirection,
                onChanged: onSortChanged,
              ),
            ),
          ),
          if (activeFilterLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: InputChip(
                  avatar: Icon(
                    Icons.filter_alt_outlined,
                    size: 18,
                    color: context.finTrackColors.info,
                  ),
                  label: Text(
                    activeFilterLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                  backgroundColor: context.finTrackColors.info.withValues(
                    alpha: 0.10,
                  ),
                  side: BorderSide(
                    color: context.finTrackColors.info.withValues(alpha: 0.34),
                  ),
                  onDeleted: onClearActiveFilter,
                ),
              ),
            ),
        ],
        Expanded(
          child: ReceiptResults(
            filter: filter,
            customSort: customSort,
            deferReloads: processingSelection,
            onRetry: onSearchChanged,
            selecting: selecting,
            selectedCount: selectedCount,
            onToggleSelection: onToggleSelection,
            onSelectVisible: onSelectVisible,
            onVisibleReceiptsChanged: onVisibleReceiptsChanged,
          ),
        ),
      ],
    );
  }
}
