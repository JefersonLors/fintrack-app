import '../entities/receipt.dart';

class ReceiptFilter {
  const ReceiptFilter({
    this.text,
    this.categoryId,
    this.withoutCategory = false,
    this.startDate,
    this.endDate,
    this.type,
    this.expense,
    this.sortOrder = ReceiptSort.date,
    this.sortDirection = SortDirection.descending,
    this.limit,
    this.offset,
  });

  final String? text;
  final int? categoryId;
  final bool withoutCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final ReceiptType? type;
  final bool? expense;
  final ReceiptSort sortOrder;
  final SortDirection sortDirection;
  final int? limit;
  final int? offset;

  ReceiptFilter copyWith({
    String? text,
    int? categoryId,
    bool? withoutCategory,
    DateTime? startDate,
    DateTime? endDate,
    ReceiptType? type,
    bool? expense,
    ReceiptSort? sortOrder,
    SortDirection? sortDirection,
    int? limit,
    int? offset,
    bool clearText = false,
    bool clearCategory = false,
    bool clearWithoutCategory = false,
    bool clearPeriod = false,
    bool clearType = false,
    bool clearExpense = false,
  }) {
    return ReceiptFilter(
      text: clearText ? null : text ?? this.text,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      withoutCategory: clearWithoutCategory
          ? false
          : withoutCategory ?? this.withoutCategory,
      startDate: clearPeriod ? null : startDate ?? this.startDate,
      endDate: clearPeriod ? null : endDate ?? this.endDate,
      type: clearType ? null : type ?? this.type,
      expense: clearExpense ? null : expense ?? this.expense,
      sortOrder: sortOrder ?? this.sortOrder,
      sortDirection: sortDirection ?? this.sortDirection,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

enum SortDirection {
  ascending('Crescente'),
  descending('Decrescente');

  const SortDirection(this.label);

  final String label;

  SortDirection get toggled => switch (this) {
    SortDirection.ascending => SortDirection.descending,
    SortDirection.descending => SortDirection.ascending,
  };
}
