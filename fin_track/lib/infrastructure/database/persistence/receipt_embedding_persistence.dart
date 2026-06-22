import 'dart:convert';
import 'dart:typed_data';

import '../../../domain/entities/embedding.dart';
import '../../diagnostics/error_handling.dart';
import '../app_database.dart';
import '../mappers/receipt_row_mapper.dart';
import '../queries/receipt_semantic_query.dart';

class ReceiptEmbeddingPersistence {
  const ReceiptEmbeddingPersistence({
    required AppDatabase database,
    required ReceiptRowMapper mapper,
    required ReceiptSemanticQuery semanticQuery,
  }) : _database = database,
       _mapper = mapper,
       _semanticQuery = semanticQuery;

  final AppDatabase _database;
  final ReceiptRowMapper _mapper;
  final ReceiptSemanticQuery _semanticQuery;

  Future<void> save(Embedding? embedding, {required int receiptId}) async {
    await (_database.delete(
      _database.embeddings,
    )..where((tbl) => tbl.receiptId.equals(receiptId))).go();
    await removeSearchVector(receiptId);
    if (embedding == null) {
      return;
    }

    await _database
        .into(_database.embeddings)
        .insert(
          EmbeddingsCompanion.insert(
            receiptId: receiptId,
            vector: embedding.vector,
            model: embedding.model,
            dimension: embedding.dimension,
            generatedAt: embedding.generatedAt,
          ),
        );
    await indexSearchVector(embedding.copyWith(receiptId: receiptId));
  }

  Future<Embedding?> findByReceipt(int receiptId) async {
    final row = await (_database.select(
      _database.embeddings,
    )..where((tbl) => tbl.receiptId.equals(receiptId))).getSingleOrNull();
    return row == null ? null : _mapper.mapEmbedding(row);
  }

  Future<void> clearSearchVectors() async {
    await _database.customStatement('DELETE FROM embedding_vector');
    _semanticQuery.invalidateVectorIndex();
  }

  Future<void> removeSearchVector(int receiptId) async {
    await _database.customStatement(
      'DELETE FROM embedding_vector WHERE receipt_id = ?',
      [receiptId],
    );
    _semanticQuery.invalidateVectorIndex();
  }

  Future<void> indexSearchVector(Embedding embedding) async {
    try {
      final vector = _deserializeVector(embedding.vector);
      if (vector.length != embedding.dimension || vector.isEmpty) {
        return;
      }

      await _database.customStatement(
        'INSERT OR REPLACE INTO embedding_vector'
        '(receipt_id, vector, model, dimension) '
        'VALUES (?, vector_as_f32(?), ?, ?)',
        [
          embedding.receiptId,
          _vectorAsJson(vector),
          embedding.model,
          embedding.dimension,
        ],
      );
      await _semanticQuery.initializeVectorIndex(embedding.dimension);
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao indexar vetor de busca semântica',
      );
      await removeSearchVector(embedding.receiptId);
    }
  }

  String _vectorAsJson(List<double> vector) {
    return jsonEncode(
      vector.map((amount) => amount.isFinite ? amount : 0).toList(),
    );
  }

  List<double> _deserializeVector(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final values = <double>[];
    for (var i = 0; i + 8 <= bytes.length; i += 8) {
      values.add(data.getFloat64(i, Endian.little));
    }
    return values;
  }
}
