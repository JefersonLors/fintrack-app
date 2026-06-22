import 'package:drift/drift.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../diagnostics/error_handling.dart';
import '../app_database.dart';

class ReceiptQueryBuilder {
  const ReceiptQueryBuilder(this._database);

  final AppDatabase _database;

  Future<List<ReceiptRow>> rowsByFilters(ReceiptFilter filter) async {
    final textIds = await idsByText(filter.text);
    if (filter.text != null &&
        filter.text!.trim().isNotEmpty &&
        textIds.isEmpty) {
      return const <ReceiptRow>[];
    }
    final query = _database.select(_database.receipts).join([
      leftOuterJoin(
        _database.extractedDataTable,
        _database.extractedDataTable.receiptId.equalsExp(_database.receipts.id),
      ),
      leftOuterJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.receipts.categoryId),
      ),
    ]);

    if (textIds.isNotEmpty) {
      query.where(_database.receipts.id.isIn(textIds));
    }
    applyFilters(query, filter);
    applyOrdering(query, filter);
    applyLimitOffset(query, filter);

    final rows = await query.get();
    final byId = <int, ReceiptRow>{};
    for (final row in rows) {
      final receipt = row.readTable(_database.receipts);
      byId[receipt.id] = receipt;
    }
    return byId.values.toList();
  }

  Future<List<ReceiptRow>> rowsByText(String text) async {
    final ids = await idsByText(text, limit: 200);
    if (ids.isNotEmpty) {
      final rows = await (_database.select(
        _database.receipts,
      )..where((tbl) => tbl.id.isIn(ids))).get();
      final byId = {for (final row in rows) row.id: row};
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    }

    final term = _normalize(text);
    final structuralSearch =
        term == 'expense' ||
        term == 'receita' ||
        ReceiptType.values.any(
          (type) => _normalize(type.label).contains(term),
        ) ||
        RegExp(r'^\d{1,4}([.,:-]\d{1,4})*$').hasMatch(term);

    if (!structuralSearch) {
      return const <ReceiptRow>[];
    }

    return rowsByFilters(
      const ReceiptFilter(
        sortOrder: ReceiptSort.date,
        sortDirection: SortDirection.descending,
      ),
    );
  }

  Future<List<int>> idsByText(String? text, {int limit = 500}) async {
    final queryText = ftsQuery(text);
    if (queryText.isEmpty) {
      return const <int>[];
    }

    return fallbackOnFailure(
      () async {
        final rows = await _database
            .customSelect(
              'SELECT rowid AS id '
              'FROM receipt_fts '
              'WHERE receipt_fts MATCH ? '
              'ORDER BY bm25(receipt_fts) '
              'LIMIT ?',
              variables: [
                Variable.withString(queryText),
                Variable.withInt(limit),
              ],
            )
            .get();
        return rows.map((row) => row.read<int>('id')).toList();
      },
      fallback: const <int>[],
      diagnosticContext: 'Falha ao executar busca textual FTS',
      report: true,
    );
  }

  void applyFilters(
    JoinedSelectStatement<HasResultSet, dynamic> query,
    ReceiptFilter filter,
  ) {
    if (filter.type != null) {
      query.where(_database.receipts.type.equals(filter.type!.persistedValue));
    }
    if (filter.expense != null) {
      query.where(_database.receipts.expense.equals(filter.expense!));
    }
    if (filter.withoutCategory) {
      query.where(_database.receipts.categoryId.isNull());
    } else if (filter.categoryId != null) {
      query.where(_database.receipts.categoryId.equals(filter.categoryId!));
    }
    if (filter.startDate != null) {
      query.where(
        _database.extractedDataTable.transactionDate.isBiggerOrEqualValue(
          filter.startDate!,
        ),
      );
    }
    if (filter.endDate != null) {
      query.where(
        _database.extractedDataTable.transactionDate.isSmallerOrEqualValue(
          filter.endDate!,
        ),
      );
    }
  }

  void applyOrdering(
    JoinedSelectStatement<HasResultSet, dynamic> query,
    ReceiptFilter filter,
  ) {
    switch (filter.sortOrder) {
      case ReceiptSort.date:
        query.orderBy([
          OrderingTerm(
            expression: _database.extractedDataTable.transactionDate,
            mode: _orderingMode(filter.sortDirection),
          ),
        ]);
      case ReceiptSort.amount:
        query.orderBy([
          OrderingTerm(
            expression: _database.extractedDataTable.amount,
            mode: _orderingMode(filter.sortDirection),
          ),
        ]);
      case ReceiptSort.establishment:
        query.orderBy([
          OrderingTerm(
            expression: _database.extractedDataTable.establishment,
            mode: _orderingMode(filter.sortDirection),
          ),
        ]);
    }
  }

  void applyLimitOffset(
    JoinedSelectStatement<HasResultSet, dynamic> query,
    ReceiptFilter filter,
  ) {
    if (filter.limit == null || filter.sortOrder == ReceiptSort.amount) {
      return;
    }
    query.limit(filter.limit!, offset: filter.offset);
  }

  bool canApplyLimitOffsetInSql(ReceiptFilter filter) {
    return filter.limit != null && filter.sortOrder != ReceiptSort.amount;
  }

  String ftsQuery(String? text) {
    if (text == null) {
      return '';
    }
    final terms = _normalize(text)
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .map((term) => term.trim())
        .where((term) => term.length >= 2)
        .toSet();
    return terms.map((term) => '$term*').join(' ');
  }

  OrderingMode _orderingMode(SortDirection direction) {
    return switch (direction) {
      SortDirection.ascending => OrderingMode.asc,
      SortDirection.descending => OrderingMode.desc,
    };
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
