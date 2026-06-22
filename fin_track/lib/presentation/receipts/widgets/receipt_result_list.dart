import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/state_views.dart';
import '../receipt_detail_page.dart';
import '../receipt_list_logic.dart';
import 'receipt_tile_widgets.dart';

class ReceiptResultList extends StatelessWidget {
  const ReceiptResultList({
    super.key,
    required this.receipts,
    required this.filter,
    required this.hasMore,
    required this.loadingMore,
    required this.loadMoreError,
    required this.onRetryLoadMore,
    required this.scrollController,
    required this.selecting,
    required this.selectedCount,
    required this.onToggleSelection,
    required this.onSelectVisible,
    this.query,
  });

  final List<Receipt> receipts;
  final ReceiptFilter filter;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;
  final VoidCallback onRetryLoadMore;
  final ScrollController scrollController;
  final bool selecting;
  final Set<int> selectedCount;
  final ValueChanged<Receipt> onToggleSelection;
  final ValueChanged<List<Receipt>> onSelectVisible;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final debugMode = AppScope.maybeOf(context)?.appConfig.debugMode ?? false;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    final results = receipts;
    final searching = query?.trim().isNotEmpty ?? false;

    if (results.isEmpty) {
      return EmptyView(
        title: searching
            ? receiptsText.noSearchResults
            : receiptsText.noReceipts,
        message: searching
            ? receiptsText.noSearchResultsMessage
            : receiptsText.noReceiptsMessage,
        icon: searching
            ? Icons.manage_search_outlined
            : Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: results.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          final allSelected =
              results.isNotEmpty &&
              results.every((receipt) => selectedCount.contains(receipt.id));
          return _ResultCountHeader(
            label: selecting
                ? '${selectedCount.length} ${selectedCount.length == 1 ? receiptsText.selectedSingular : receiptsText.selectedPlural}'
                : receiptResultCountLabel(
                    total: results.length,
                    filter: filter,
                    searching: searching,
                    hasMore: hasMore,
                  ),
            selecting: selecting,
            allSelected: allSelected,
            onSelectVisible: () => onSelectVisible(results),
          );
        }

        if (index == results.length + 1) {
          return _PaginationFooter(
            hasMore: hasMore,
            loading: loadingMore,
            error: loadMoreError,
            onRetry: onRetryLoadMore,
          );
        }

        final receipt = results[index - 1];
        return ReceiptTile(
          receipt: receipt,
          selecting: selecting,
          selected: selectedCount.contains(receipt.id),
          matchType: debugMode && searching
              ? receiptSearchMatch(receipt, query!)
              : SearchMatch.none,
          showMatchType: debugMode,
          onTap: selecting
              ? () => onToggleSelection(receipt)
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReceiptDetailPage(receiptId: receipt.id),
                  ),
                ),
          onLongPress: () => onToggleSelection(receipt),
        );
      },
    );
  }
}

class _ResultCountHeader extends StatelessWidget {
  const _ResultCountHeader({
    required this.label,
    required this.selecting,
    required this.allSelected,
    required this.onSelectVisible,
  });

  final String label;
  final bool selecting;
  final bool allSelected;
  final VoidCallback onSelectVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          if (selecting)
            _SelectAllVisibleControl(
              selected: allSelected,
              onPressed: onSelectVisible,
            ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.hasMore,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool hasMore;
  final bool loading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      final commonText = AppScope.of(context).appConfig.ui.common;
      final receiptsText = AppScope.of(context).appConfig.ui.receipts;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                receiptsText.loadMoreReceiptsFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text(commonText.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (!hasMore) {
      return const SizedBox(height: 24);
    }
    return const SizedBox(height: 56);
  }
}

class _SelectAllVisibleControl extends StatelessWidget {
  const _SelectAllVisibleControl({required this.selected, this.onPressed});

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurfaceVariant;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              receiptsText.all,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: foreground),
            ),
            const SizedBox(width: 4),
            Icon(
              selected
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 20,
              color: foreground,
            ),
          ],
        ),
      ),
    );
  }
}
