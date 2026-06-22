import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/embedding.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/mappers/receipt_row_mapper.dart';
import 'package:fin_track/infrastructure/database/queries/receipt_query_builder.dart';
import 'package:fin_track/infrastructure/database/queries/receipt_semantic_query.dart';
import 'package:fin_track/infrastructure/database/queries/receipt_semantic_ranker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.memory();
    await database.ensureInitialDataForTesting();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'ReceiptRowMapper maps receipt row with extracted data and category',
    () async {
      final receiptId = await _insertReceipt(database, categoryId: 1);
      await database
          .into(database.extractedDataTable)
          .insert(
            ExtractedDataTableCompanion.insert(
              receiptId: receiptId,
              amount: const Value(42.5),
              establishment: const Value('Mercado Central'),
            ),
          );
      final row = await (database.select(
        database.receipts,
      )..where((tbl) => tbl.id.equals(receiptId))).getSingle();

      final receipt = await ReceiptRowMapper(database).mapReceipt(row);

      expect(receipt.id, receiptId);
      expect(receipt.category?.id, 1);
      expect(receipt.extractedData?.amount, 42.5);
      expect(receipt.extractedData?.establishment, 'Mercado Central');
    },
  );

  test(
    'ReceiptQueryBuilder applies category and no-category filters',
    () async {
      final categorizedId = await _insertReceipt(database, categoryId: 1);
      final uncategorizedId = await _insertReceipt(database);
      final queryBuilder = ReceiptQueryBuilder(database);

      final categorized = await queryBuilder.rowsByFilters(
        const ReceiptFilter(categoryId: 1),
      );
      final uncategorized = await queryBuilder.rowsByFilters(
        const ReceiptFilter(withoutCategory: true),
      );

      expect(categorized.map((row) => row.id), contains(categorizedId));
      expect(
        categorized.map((row) => row.id),
        isNot(contains(uncategorizedId)),
      );
      expect(uncategorized.map((row) => row.id), contains(uncategorizedId));
    },
  );

  test('ReceiptSemanticRanker orders compatible candidates by score', () async {
    final firstId = await _insertReceipt(database);
    final secondId = await _insertReceipt(database);
    final rows = await database.select(database.receipts).get();
    final byId = {for (final row in rows) row.id: row};
    final ranker = const ReceiptSemanticRanker();
    final query = EmbeddingVector(
      vector: const [1, 0],
      model: 'test',
      dimension: 2,
    );

    final ranked = ranker.rank(
      [
        ReceiptSemanticCandidate(
          byId[secondId]!,
          _embedding(secondId, const [0, 1]),
        ),
        ReceiptSemanticCandidate(
          byId[firstId]!,
          _embedding(firstId, const [1, 0]),
        ),
      ],
      query,
      2,
    );

    expect(ranked.map((row) => row.id).toList(), [firstId]);
  });
}

Future<int> _insertReceipt(AppDatabase database, {int? categoryId}) {
  return database
      .into(database.receipts)
      .insert(
        ReceiptsCompanion.insert(
          type: ReceiptType.invoice.persistedValue,
          expense: true,
          fileName:
              'receipt_${DateTime.now().microsecondsSinceEpoch}_$categoryId.jpg',
          fileType: 'image/jpeg',
          categoryId: Value(categoryId),
          registeredAt: DateTime(2026, 5, 25),
        ),
      );
}

Embedding _embedding(int receiptId, List<double> values) {
  return Embedding(
    id: 0,
    receiptId: receiptId,
    vector: _serializeVector(values),
    model: 'test',
    dimension: values.length,
    generatedAt: DateTime(2026, 5, 25),
  );
}

Uint8List _serializeVector(List<double> values) {
  final bytes = ByteData(values.length * 8);
  for (var index = 0; index < values.length; index++) {
    bytes.setFloat64(index * 8, values[index], Endian.little);
  }
  return bytes.buffer.asUint8List();
}
