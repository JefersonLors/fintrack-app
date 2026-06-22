import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReceiptFilter copies clears fields and toggles sortOrder', () {
    final filter = ReceiptFilter(
      text: 'mercado',
      categoryId: 7,
      withoutCategory: true,
      startDate: DateTime(2026, 5),
      endDate: DateTime(2026, 5, 23),
      type: ReceiptType.invoice,
      expense: true,
      limit: 20,
      offset: 40,
    );

    final updated = filter.copyWith(
      text: 'farmacia',
      categoryId: 8,
      withoutCategory: false,
      startDate: DateTime(2026, 4),
      endDate: DateTime(2026, 4, 30),
      type: ReceiptType.receipt,
      expense: false,
      sortOrder: ReceiptSort.amount,
      sortDirection: SortDirection.ascending,
      limit: 10,
      offset: 5,
    );

    expect(updated.text, 'farmacia');
    expect(updated.categoryId, 8);
    expect(updated.withoutCategory, isFalse);
    expect(updated.startDate, DateTime(2026, 4));
    expect(updated.endDate, DateTime(2026, 4, 30));
    expect(updated.type, ReceiptType.receipt);
    expect(updated.expense, isFalse);
    expect(updated.sortOrder, ReceiptSort.amount);
    expect(updated.sortDirection, SortDirection.ascending);
    expect(updated.limit, 10);
    expect(updated.offset, 5);

    final cleared = updated.copyWith(
      clearText: true,
      clearCategory: true,
      clearWithoutCategory: true,
      clearPeriod: true,
      clearType: true,
      clearExpense: true,
    );

    expect(cleared.text, isNull);
    expect(cleared.categoryId, isNull);
    expect(cleared.withoutCategory, isFalse);
    expect(cleared.startDate, isNull);
    expect(cleared.endDate, isNull);
    expect(cleared.type, isNull);
    expect(cleared.expense, isNull);
    expect(SortDirection.ascending.label, 'Crescente');
    expect(SortDirection.descending.label, 'Decrescente');
    expect(SortDirection.ascending.toggled, SortDirection.descending);
    expect(SortDirection.descending.toggled, SortDirection.ascending);

    final preservado = filter.copyWith();
    expect(preservado.text, filter.text);
    expect(preservado.categoryId, filter.categoryId);
    expect(preservado.withoutCategory, filter.withoutCategory);
    expect(preservado.startDate, filter.startDate);
    expect(preservado.endDate, filter.endDate);
    expect(preservado.type, filter.type);
    expect(preservado.expense, filter.expense);
  });
}
