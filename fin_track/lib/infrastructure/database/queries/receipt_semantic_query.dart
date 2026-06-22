import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/embedding.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../../domain/value_objects/embedding_vector.dart';
import '../../diagnostics/error_handling.dart';
import '../app_database.dart';
import '../mappers/receipt_row_mapper.dart';
import 'receipt_query_builder.dart';

class ReceiptSemanticQuery {
  ReceiptSemanticQuery(this._database, this._queryBuilder)
    : _mapper = ReceiptRowMapper(_database);

  final AppDatabase _database;
  final ReceiptQueryBuilder _queryBuilder;
  final ReceiptRowMapper _mapper;
  int? _vectorIndexDimension;

  Future<List<ReceiptSemanticCandidate>> rowsWithEmbeddingsByFilters(
    EmbeddingVector vector,
    ReceiptFilter filter,
    int limit,
  ) async {
    final vectorIds = await _idsByVector(vector, limit: limit);
    if (vectorIds.isEmpty) {
      return const <ReceiptSemanticCandidate>[];
    }
    final textIds = await _queryBuilder.idsByText(filter.text);
    if (filter.text != null &&
        filter.text!.trim().isNotEmpty &&
        textIds.isEmpty) {
      return const <ReceiptSemanticCandidate>[];
    }
    final textIdSet = textIds.toSet();
    final allowedIds = textIds.isEmpty
        ? vectorIds
        : vectorIds.where(textIdSet.contains).toList();
    if (allowedIds.isEmpty) {
      return const <ReceiptSemanticCandidate>[];
    }

    final query = _database.select(_database.receipts).join([
      innerJoin(
        _database.embeddings,
        _database.embeddings.receiptId.equalsExp(_database.receipts.id),
      ),
      leftOuterJoin(
        _database.extractedDataTable,
        _database.extractedDataTable.receiptId.equalsExp(_database.receipts.id),
      ),
      leftOuterJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.receipts.categoryId),
      ),
    ]);

    query.where(_database.receipts.id.isIn(allowedIds));
    _queryBuilder.applyFilters(query, filter);

    final rows = await query.get();
    final byId = <int, ReceiptSemanticCandidate>{};
    for (final row in rows) {
      final receipt = row.readTable(_database.receipts);
      byId[receipt.id] = ReceiptSemanticCandidate(
        receipt,
        _mapper.mapEmbedding(row.readTable(_database.embeddings)),
      );
    }
    return byId.values.toList();
  }

  Future<void> initializeVectorIndex(int dimension) async {
    if (_vectorIndexDimension == dimension) {
      return;
    }
    await _database
        .customSelect(
          "SELECT vector_init('embedding_vector', 'vector', ?) AS ok",
          variables: [Variable.withString('type=FLOAT32,dimension=$dimension')],
        )
        .get();
    _vectorIndexDimension = dimension;
  }

  void invalidateVectorIndex() {
    _vectorIndexDimension = null;
  }

  Future<List<int>> _idsByVector(
    EmbeddingVector vector, {
    required int limit,
  }) async {
    if (vector.vector.isEmpty || vector.dimension != vector.vector.length) {
      return const <int>[];
    }

    try {
      await initializeVectorIndex(vector.dimension);
      final rows = await _database
          .customSelect(
            'SELECT ev.receipt_id AS id '
            'FROM embedding_vector ev '
            "JOIN vector_full_scan('embedding_vector', 'vector', vector_as_f32(?), ?) v "
            'ON ev.rowid = v.rowid '
            'WHERE ev.dimension = ? '
            'ORDER BY v.distance '
            'LIMIT ?',
            variables: [
              Variable.withString(_vectorAsJson(vector.vector)),
              Variable.withInt(limit),
              Variable.withInt(vector.dimension),
              Variable.withInt(limit),
            ],
          )
          .get();
      return rows.map((row) => row.read<int>('id')).toList();
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext:
            'Falha ao executar busca vetorial; usando fallback por tabela',
      );
      // coverage:ignore-start
      // Defensive fallback for environments where sqlite-vector cannot run
      // vector_full_scan even though the plain embedding table is available.
      final rows = await _database
          .customSelect(
            'SELECT receipt_id AS id '
            'FROM embedding_vector '
            'WHERE dimension = ? '
            'LIMIT ?',
            variables: [
              Variable.withInt(vector.dimension),
              Variable.withInt(limit),
            ],
          )
          .get();
      return rows.map((row) => row.read<int>('id')).toList();
      // coverage:ignore-end
    }
  }

  String _vectorAsJson(List<double> vector) {
    return jsonEncode(
      vector.map((amount) => amount.isFinite ? amount : 0).toList(),
    );
  }
}

class ReceiptSemanticCandidate {
  const ReceiptSemanticCandidate(this.row, this.embedding);

  final ReceiptRow row;
  final Embedding embedding;
}
