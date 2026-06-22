import 'package:flutter/material.dart';

import '../../../application/config/app_config.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/formatters.dart';
import '../receipt_list_logic.dart';
import 'receipt_list_filter_widgets.dart';

const double _dropdownMenuMaxHeight = 280;

class ReceiptListFilterSelection {
  const ReceiptListFilterSelection({
    required this.categoryId,
    required this.type,
    required this.expense,
    required this.startDate,
    required this.endDate,
    required this.categoryName,
    required this.activeLabel,
  });

  final int? categoryId;
  final ReceiptType? type;
  final bool? expense;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryName;
  final String? activeLabel;
}

Future<ReceiptListFilterSelection?> showReceiptListFilterSheet(
  BuildContext context, {
  required List<Category> categories,
  required int? categoryId,
  required bool withoutCategory,
  required ReceiptType? type,
  required bool? expense,
  required DateTime? startDate,
  required DateTime? endDate,
}) {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  var selectedCategory = categoryId;
  var selectedType = type;
  var selectedExpense = expense;
  var selectedStart = startDate;
  var selectedEnd = endDate;

  return showModalBottomSheet<ReceiptListFilterSelection?>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: context.finTrackColors.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          receiptsText.filters,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.finTrackColors.surface,
                      border: Border.all(
                        color: context.finTrackColors.borderStrong,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppDropdownField<int?>(
                            initialValue: selectedCategory,
                            menuMaxHeight: _dropdownMenuMaxHeight,
                            decoration: InputDecoration(
                              labelText: AppScope.of(
                                context,
                              ).appConfig.ui.receiptDetail.category,
                              prefixIcon: const Icon(Icons.category_outlined),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  receiptsText.allCategories,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...categories.map(
                                (category) => DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setSheetState(() => selectedCategory = value),
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<ReceiptType?>(
                            initialValue: selectedType,
                            menuMaxHeight: _dropdownMenuMaxHeight,
                            decoration: InputDecoration(
                              labelText: AppScope.of(
                                context,
                              ).appConfig.ui.receiptDetail.receiptType,
                              prefixIcon: const Icon(Icons.receipt_outlined),
                            ),
                            items: [
                              DropdownMenuItem<ReceiptType?>(
                                value: null,
                                child: Text(
                                  receiptsText.all,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...ReceiptType.values.map(
                                (type) => DropdownMenuItem<ReceiptType?>(
                                  value: type,
                                  child: Text(
                                    type.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setSheetState(() => selectedType = value),
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<bool?>(
                            initialValue: selectedExpense,
                            menuMaxHeight: _dropdownMenuMaxHeight,
                            decoration: InputDecoration(
                              labelText: AppScope.of(
                                context,
                              ).appConfig.ui.receiptDetail.nature,
                              prefixIcon: const Icon(
                                Icons.swap_vert_circle_outlined,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<bool?>(
                                value: null,
                                child: Text(receiptsText.all),
                              ),
                              DropdownMenuItem<bool?>(
                                value: true,
                                child: Text(receiptsText.expenses),
                              ),
                              DropdownMenuItem<bool?>(
                                value: false,
                                child: Text(receiptsText.incomes),
                              ),
                            ],
                            onChanged: (value) =>
                                setSheetState(() => selectedExpense = value),
                          ),
                          const SizedBox(height: 12),
                          DateRangeFilterField(
                            startDate: selectedStart,
                            endDate: selectedEnd,
                            onSelect: () async {
                              final range = await _selectDateRange(
                                context,
                                selectedStart,
                                selectedEnd,
                              );
                              if (range == null) {
                                return;
                              }
                              setSheetState(() {
                                selectedStart = startOfDay(range.start);
                                selectedEnd = endOfDay(range.end);
                              });
                            },
                            onClear:
                                selectedStart == null && selectedEnd == null
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedStart = null;
                                      selectedEnd = null;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(
                            context,
                            const ReceiptListFilterSelection(
                              categoryId: null,
                              type: null,
                              expense: null,
                              startDate: null,
                              endDate: null,
                              categoryName: null,
                              activeLabel: null,
                            ),
                          ),
                          icon: Icon(Icons.filter_alt_off_outlined),
                          label: Text(commonText.clear),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final categoryName = _selectedCategoryName(
                              categories,
                              selectedCategory,
                            );
                            Navigator.pop(
                              context,
                              ReceiptListFilterSelection(
                                categoryId: selectedCategory,
                                type: selectedType,
                                expense: selectedExpense,
                                startDate: selectedStart,
                                endDate: selectedEnd,
                                categoryName: categoryName,
                                activeLabel: _buildFilterLabel(
                                  receiptsText: receiptsText,
                                  categoryName: categoryName,
                                  withoutCategory:
                                      withoutCategory &&
                                      selectedCategory == null,
                                  categoryId: selectedCategory,
                                  type: selectedType,
                                  expenseFilter: selectedExpense,
                                  startDate: selectedStart,
                                  endDate: selectedEnd,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.check),
                          label: Text(commonText.apply),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String? _buildFilterLabel({
  required ReceiptsTextConfig receiptsText,
  String? categoryName,
  required bool withoutCategory,
  int? categoryId,
  ReceiptType? type,
  bool? expenseFilter,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final parts = <String>[];
  if (withoutCategory) {
    parts.add(receiptsText.withoutCategory);
  } else if (categoryId != null) {
    parts.add(categoryName ?? receiptsText.category);
  }
  if (type != null) {
    parts.add(type.label);
  }
  if (expenseFilter != null) {
    parts.add(expenseFilter ? receiptsText.expenses : receiptsText.incomes);
  }
  if (startDate != null && endDate != null) {
    parts.add('${formatDate(startDate)} - ${formatDate(endDate)}');
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _selectedCategoryName(List<Category> categories, int? categoryId) {
  if (categoryId == null) {
    return null;
  }
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }
  return null;
}

Future<DateTimeRange?> _selectDateRange(
  BuildContext context,
  DateTime? startDate,
  DateTime? endDate,
) {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final receiptsText = AppScope.of(context).appConfig.ui.receipts;
  final today = DateTime.now();
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(today.year + 5, 12, 31),
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    initialDateRange: startDate == null || endDate == null
        ? null
        : DateTimeRange(start: startOfDay(startDate), end: startOfDay(endDate)),
    helpText: receiptsText.selectRange,
    cancelText: commonText.cancel,
    confirmText: commonText.apply,
    saveText: commonText.apply,
    fieldStartHintText: receiptsText.start,
    fieldEndHintText: receiptsText.end,
    errorFormatText: receiptsText.invalidDate,
    errorInvalidText: receiptsText.invalidRange,
    errorInvalidRangeText: receiptsText.invalidRangeOrder,
  );
}
