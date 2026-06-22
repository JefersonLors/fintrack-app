import '../../domain/entities/receipt.dart';
import '../../domain/value_objects/receipt_filter.dart';
import '../widgets/formatters.dart';

enum SearchMatch { none, data, ocr, semantic }

bool hasAdvancedReceiptFilter({
  required int? categoryId,
  bool withoutCategory = false,
  required ReceiptType? type,
  required bool? expense,
  required DateTime? startDate,
  required DateTime? endDate,
}) {
  return withoutCategory ||
      categoryId != null ||
      type != null ||
      expense != null ||
      startDate != null ||
      endDate != null;
}

DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime endOfDay(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
}

String receiptResultCountLabel({
  required int total,
  required ReceiptFilter filter,
  required bool searching,
  bool hasMore = false,
}) {
  if (hasMore) {
    return total == 1
        ? '1 comprovante carregado'
        : '$total comprovantes carregados';
  }
  if (searching) {
    return total == 1
        ? '1 comprovante encontrado'
        : '$total comprovantes encontrados';
  }
  final singular = total == 1;
  final noun = singular ? 'comprovante' : 'comprovantes';
  final filtering = hasAdvancedReceiptFilter(
    categoryId: filter.categoryId,
    withoutCategory: filter.withoutCategory,
    type: filter.type,
    expense: filter.expense,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
  if (filtering) {
    return '$total $noun no filtro atual';
  }
  return '$total $noun cadastrado${singular ? '' : 's'}';
}

List<Receipt> applyAdvancedReceiptFilters(
  List<Receipt> receipts,
  ReceiptFilter filter,
) {
  return receipts.where((receipt) {
    if (filter.withoutCategory && receipt.category != null) {
      return false;
    }
    if (!filter.withoutCategory &&
        filter.categoryId != null &&
        receipt.category?.id != filter.categoryId) {
      return false;
    }
    if (filter.type != null && receipt.type != filter.type) {
      return false;
    }
    if (filter.expense != null && receipt.expense != filter.expense) {
      return false;
    }

    final receiptDate = receipt.extractedData?.transactionDate;
    if (filter.startDate != null) {
      if (receiptDate == null || receiptDate.isBefore(filter.startDate!)) {
        return false;
      }
    }
    if (filter.endDate != null) {
      if (receiptDate == null || receiptDate.isAfter(filter.endDate!)) {
        return false;
      }
    }
    return true;
  }).toList();
}

List<Receipt> sortReceipts(
  List<Receipt> receipts,
  ReceiptSort sortOrder,
  SortDirection direction,
) {
  final result = [...receipts];
  switch (sortOrder) {
    case ReceiptSort.date:
      result.sort((a, b) {
        final dateA = a.extractedData?.transactionDate;
        final dateB = b.extractedData?.transactionDate;
        if (dateA == null && dateB == null) {
          return 0;
        }
        if (dateA == null) {
          return 1;
        }
        if (dateB == null) {
          return -1;
        }
        final comparison = dateA.compareTo(dateB);
        return applySortDirection(comparison, direction);
      });
    case ReceiptSort.amount:
      result.sort((a, b) {
        final valueA = signedReceiptValue(a);
        final valueB = signedReceiptValue(b);
        if (valueA == null && valueB == null) {
          return 0;
        }
        if (valueA == null) {
          return 1;
        }
        if (valueB == null) {
          return -1;
        }
        final comparison = valueA.compareTo(valueB);
        return applySortDirection(comparison, direction);
      });
    case ReceiptSort.establishment:
      result.sort((a, b) {
        final nameA = a.extractedData?.establishment ?? '';
        final nameB = b.extractedData?.establishment ?? '';
        final comparison = nameA.compareTo(nameB);
        return applySortDirection(comparison, direction);
      });
  }
  return result;
}

int applySortDirection(int comparison, SortDirection direction) {
  return switch (direction) {
    SortDirection.ascending => comparison,
    SortDirection.descending => -comparison,
  };
}

double? signedReceiptValue(Receipt receipt) {
  final amount = receipt.extractedData?.amount;
  if (amount == null) {
    return null;
  }
  return receipt.expense ? -amount : amount;
}

SearchMatch receiptSearchMatch(Receipt receipt, String query) {
  final term = normalizeReceiptSearchText(query);
  if (structuredReceiptSearchText(receipt).contains(term)) {
    return SearchMatch.data;
  }
  if (ocrReceiptSearchText(receipt).contains(term)) {
    return SearchMatch.ocr;
  }
  return SearchMatch.semantic;
}

String structuredReceiptSearchText(Receipt receipt) {
  return normalizeReceiptSearchText(
    [
      receipt.type.label,
      receipt.expense ? 'despesa' : 'receita',
      receipt.extractedData?.establishment ?? '',
      receipt.extractedData?.amount?.toStringAsFixed(2) ?? '',
      receipt.extractedData?.transactionDate?.toIso8601String() ?? '',
      receipt.extractedData?.paymentMethod ?? '',
      receipt.category?.name ?? '',
    ].join(' '),
  );
}

String ocrReceiptSearchText(Receipt receipt) {
  return normalizeReceiptSearchText(receipt.extractedContent);
}

String normalizeReceiptSearchText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

String formatReceiptCurrencyWithNature(double? amount, bool expense) {
  if (amount == null) {
    return formatCurrency(null);
  }
  final sign = expense ? '-' : '+';
  return '$sign ${formatCurrency(amount)}';
}
