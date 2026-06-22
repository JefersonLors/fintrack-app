part of 'report_widgets.dart';

class MutableReportTotal {
  MutableReportTotal(
    this.label, {
    this.categoryId,
    this.type,
    this.withoutCategory = false,
    this.icon,
    this.color,
  });

  factory MutableReportTotal.fromCategory(
    Category category,
    BuildContext context,
  ) {
    return MutableReportTotal(
      category.name,
      categoryId: category.id,
      icon: categoryIconFor(category),
      color: categoryColorFor(category, context),
    );
  }

  final String label;
  final int? categoryId;
  final ReceiptType? type;
  final bool withoutCategory;
  final IconData? icon;
  final Color? color;
  double total = 0;

  void add(double value) {
    total += value;
  }

  ReportTotal toTotal() => ReportTotal(
    label,
    total,
    categoryId: categoryId,
    type: type,
    withoutCategory: withoutCategory,
    icon: icon,
    color: color,
  );
}

class ReportTotal {
  const ReportTotal(
    this.label,
    this.total, {
    this.categoryId,
    this.type,
    this.withoutCategory = false,
    this.icon,
    this.color,
  });

  final String label;
  final double total;
  final int? categoryId;
  final ReceiptType? type;
  final bool withoutCategory;
  final IconData? icon;
  final Color? color;
}
