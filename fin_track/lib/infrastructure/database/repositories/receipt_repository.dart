import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/entities/embedding.dart';
import '../../../domain/repositories/i_receipt_repository.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../../domain/value_objects/embedding_vector.dart';
import '../app_database.dart';
import '../mappers/receipt_row_mapper.dart';
import '../persistence/receipt_category_persistence.dart';
import '../persistence/receipt_embedding_persistence.dart';
import '../persistence/receipt_extracted_data_persistence.dart';
import '../queries/receipt_query_builder.dart';
import '../queries/receipt_semantic_query.dart';
import '../queries/receipt_semantic_ranker.dart';

part 'receipt_repository_helpers.dart';

class ReceiptRepository implements IReceiptRepository {
  ReceiptRepository(this._database)
    : _mapper = ReceiptRowMapper(_database),
      _queryBuilder = ReceiptQueryBuilder(_database),
      _semanticQuery = ReceiptSemanticQuery(
        _database,
        ReceiptQueryBuilder(_database),
      ),
      _categoryPersistence = ReceiptCategoryPersistence(_database),
      _extractedDataPersistence = ReceiptExtractedDataPersistence(_database),
      _embeddingPersistence = ReceiptEmbeddingPersistence(
        database: _database,
        mapper: ReceiptRowMapper(_database),
        semanticQuery: ReceiptSemanticQuery(
          _database,
          ReceiptQueryBuilder(_database),
        ),
      ),
      _semanticRanker = const ReceiptSemanticRanker();

  final AppDatabase _database;
  final ReceiptRowMapper _mapper;
  final ReceiptQueryBuilder _queryBuilder;
  final ReceiptSemanticQuery _semanticQuery;
  final ReceiptCategoryPersistence _categoryPersistence;
  final ReceiptExtractedDataPersistence _extractedDataPersistence;
  final ReceiptEmbeddingPersistence _embeddingPersistence;
  final ReceiptSemanticRanker _semanticRanker;

  @override
  Future<Receipt> save(Receipt receipt) async {
    final id = await _database.transaction(() async {
      final categoryId = await _categoryPersistence.categoryId(
        receipt.category,
      );
      final receiptId = await _database
          .into(_database.receipts)
          .insert(_receiptCompanion(receipt, categoryId: categoryId));

      await _extractedDataPersistence.save(
        receipt.extractedData,
        receiptId: receiptId,
      );
      await _embeddingPersistence.save(receipt.embedding, receiptId: receiptId);
      await _indexSearch(receipt.copyWith(id: receiptId));

      return receiptId;
    });

    return findById(id);
  }

  @override
  Future<void> update(Receipt receipt) async {
    final existing = await _findReceiptRow(receipt.id);
    if (existing == null) {
      throw StateError('Comprovante não encontrado.');
    }

    await _database.transaction(() async {
      final categoryId = await _categoryPersistence.categoryId(
        receipt.category,
      );
      await (_database.update(
        _database.receipts,
      )..where((tbl) => tbl.id.equals(receipt.id))).write(
        _receiptCompanion(receipt, update: true, categoryId: categoryId),
      );

      await _extractedDataPersistence.save(
        receipt.extractedData,
        receiptId: receipt.id,
      );
      await _embeddingPersistence.save(
        receipt.embedding,
        receiptId: receipt.id,
      );
      await _indexSearch(receipt);
    });
  }

  @override
  Future<void> markCloudSynced(Iterable<int> ids) async {
    final validIds = ids.where((id) => id > 0).toSet();
    if (validIds.isEmpty) {
      return;
    }
    await (_database.update(_database.receipts)
          ..where((tbl) => tbl.id.isIn(validIds)))
        .write(const ReceiptsCompanion(cloudSynced: Value(true)));
  }

  @override
  Future<void> markAllAsNotCloudSynced() {
    return _database
        .update(_database.receipts)
        .write(const ReceiptsCompanion(cloudSynced: Value(false)));
  }

  @override
  Future<void> replaceAll(List<Receipt> receipts) async {
    await _database.transaction(() async {
      await _database.delete(_database.receipts).go();
      await _clearSearchIndexes();

      for (final receipt in receipts) {
        final categoryId = await _categoryPersistence.categoryId(
          receipt.category,
        );
        final receiptId = await _database
            .into(_database.receipts)
            .insert(
              _receiptCompanion(
                receipt.copyWith(id: 0),
                categoryId: categoryId,
              ),
            );

        await _extractedDataPersistence.save(
          receipt.extractedData,
          receiptId: receiptId,
        );
        await _embeddingPersistence.save(
          receipt.embedding,
          receiptId: receiptId,
        );
        await _indexSearch(receipt.copyWith(id: receiptId));
      }
    });
  }

  @override
  Future<void> delete(int id) async {
    await _database.transaction(() async {
      await _removeFromSearchIndexes(id);
      await (_database.delete(
        _database.receipts,
      )..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  @override
  Future<Receipt> findById(int id) async {
    final row = await _findReceiptRow(id);
    if (row == null) {
      throw StateError('Comprovante não encontrado.');
    }
    return _mapper.mapReceipt(row);
  }

  @override
  Future<List<Receipt>> findByFilters(ReceiptFilter filter) async {
    final rows = await _queryBuilder.rowsByFilters(filter);
    final todos = await Future.wait(rows.map(_mapper.mapReceipt));
    final sorted = _sortReceipts(todos, filter);
    if (_queryBuilder.canApplyLimitOffsetInSql(filter)) {
      return sorted;
    }
    return _applyLimitOffset(sorted, filter);
  }

  @override
  Future<List<Receipt>> findByTerms(String text) async {
    final term = _normalize(text.trim());
    if (term.isEmpty) {
      return <Receipt>[];
    }

    final candidates = await _queryBuilder.rowsByText(text.trim());
    final results = await Future.wait(candidates.map(_mapper.mapReceipt));
    return results.where((receipt) {
      final indexedText =
          '${_indexedStructuredText(receipt)} '
          '${_indexedOcrText(receipt)}';
      return _matchesTerms(indexedText, term);
    }).toList()..sort(_compareByExtractedDateDesc);
  }

  @override
  Future<List<Receipt>> findSimilar(EmbeddingVector vector, int limit) async {
    return findSimilarByFilters(vector, const ReceiptFilter(), limit);
  }

  @override
  Future<List<Receipt>> findSimilarByFilters(
    EmbeddingVector vector,
    ReceiptFilter filter,
    int limit,
  ) async {
    final candidates = await _semanticQuery.rowsWithEmbeddingsByFilters(
      vector,
      ReceiptFilter(
        text: filter.text,
        categoryId: filter.categoryId,
        withoutCategory: filter.withoutCategory,
        startDate: filter.startDate,
        endDate: filter.endDate,
        type: filter.type,
        expense: filter.expense,
        sortOrder: filter.sortOrder,
        sortDirection: filter.sortDirection,
      ),
      math.max(60, limit * 8),
    );
    final rankedRows = _semanticRanker.rank(candidates, vector, limit);
    return Future.wait(rankedRows.map(_mapper.mapReceipt));
  }

  @override
  Future<void> saveEmbedding(Embedding embedding) async {
    await _embeddingPersistence.save(embedding, receiptId: embedding.receiptId);
    await (_database.update(_database.receipts)
          ..where((tbl) => tbl.id.equals(embedding.receiptId)))
        .write(const ReceiptsCompanion(cloudSynced: Value(false)));
  }

  @override
  Future<Embedding?> findEmbeddingByReceipt(int receiptId) async {
    return _embeddingPersistence.findByReceipt(receiptId);
  }

  @override
  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter) {
    return _watchChanges().asyncMap((_) => findByFilters(filter));
  }

  @override
  Stream<List<Receipt>> watchAll() {
    return watchByFilters(const ReceiptFilter());
  }
}
