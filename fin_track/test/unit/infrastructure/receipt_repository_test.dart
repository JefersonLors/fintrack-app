import 'dart:typed_data';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/embedding.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/repositories/receipt_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'receipt filters sorts searches embeddings and returns empty states',
    () async {
      final repository = ReceiptRepository(database);
      final market = const Category(id: 0, name: 'Mercado');

      await expectLater(
        repository.update(_receipt(id: 404, name: 'nao-existe.png')),
        throwsA(isA<StateError>()),
      );
      expect(await repository.findByTerms('   '), isEmpty);

      final withoutCategory = await repository.save(
        _receipt(
          name: 'without-category.png',
          value: null,
          date: null,
          establishment: null,
        ),
      );
      final cheap = await repository.save(
        _receipt(
          name: 'market-a.png',
          category: market,
          value: 12,
          date: DateTime(2026, 5, 20),
          establishment: 'Mercado A',
          content: 'arroz feijao',
        ),
      );
      final expensive = await repository.save(
        _receipt(
          name: 'market-b.png',
          category: market,
          value: 30,
          date: DateTime(2026, 5, 21),
          establishment: 'Mercado B',
          type: ReceiptType.receipt,
          expense: false,
          content: 'leite cafe',
        ),
      );

      expect(await repository.findEmbeddingByReceipt(expensive.id), isNull);
      await repository.saveEmbedding(
        Embedding(
          id: 0,
          receiptId: expensive.id,
          vector: Uint8List.fromList([1, 2, 3, 4]),
          model: 'test',
          dimension: 4,
          generatedAt: DateTime(2026, 5, 23),
        ),
      );
      expect(
        (await repository.findEmbeddingByReceipt(expensive.id))?.model,
        'test',
      );

      expect(
        await repository.findByFilters(
          const ReceiptFilter(text: 'inexistente'),
        ),
        isEmpty,
      );
      expect(
        (await repository.findByFilters(
          const ReceiptFilter(withoutCategory: true),
        )).map((receipt) => receipt.id),
        [withoutCategory.id],
      );
      expect(
        (await repository.findByFilters(
          const ReceiptFilter(type: ReceiptType.receipt, expense: false),
        )).single.id,
        expensive.id,
      );
      expect(
        (await repository.findByFilters(
          const ReceiptFilter(
            sortOrder: ReceiptSort.amount,
            sortDirection: SortDirection.ascending,
            limit: 1,
            offset: 1,
          ),
        )).single.id,
        expensive.id,
      );
      expect(
        (await repository.findByFilters(
          const ReceiptFilter(
            sortOrder: ReceiptSort.establishment,
            sortDirection: SortDirection.ascending,
          ),
        )).map((receipt) => receipt.id),
        containsAllInOrder([cheap.id, expensive.id]),
      );
      expect(
        (await repository.findByFilters(
          const ReceiptFilter(
            sortOrder: ReceiptSort.establishment,
            sortDirection: SortDirection.descending,
            limit: 1,
          ),
        )).single.id,
        expensive.id,
      );

      await repository.markCloudSynced([expensive.id, -1]);
      expect((await repository.findById(expensive.id)).cloudSynced, isTrue);
      await repository.markAllAsNotCloudSynced();
      expect((await repository.findById(expensive.id)).cloudSynced, isFalse);
    },
  );

  test('receipts watch changes and apply composite SQL filters', () async {
    final repository = ReceiptRepository(database);
    final stream = repository.watchAll();
    final subscription = stream.listen((_) {});
    addTearDown(() async => subscription.cancel());

    final food = const Category(id: 0, name: 'Alimentação');
    final withoutCategory = await repository.save(
      _receipt(
        name: 'without-category-db.png',
        value: null,
        date: null,
        establishment: null,
        content: 'receipt avulso',
      ),
    );
    final market = await repository.save(
      _receipt(
        name: 'central-market-db.png',
        category: food,
        value: 15,
        date: DateTime(2026, 5, 20),
        establishment: 'Mercado Central',
        content: 'arroz feijao despesa',
        embedding: _embedding(),
      ),
    );
    final income = await repository.save(
      _receipt(
        name: 'extra-income-db.png',
        category: food,
        value: 80,
        date: DateTime(2026, 5, 22),
        establishment: 'Cliente B',
        type: ReceiptType.receipt,
        expense: false,
        content: 'receita servico',
        embedding: _embedding(),
      ),
    );

    await repository.update(
      market.copyWith(extractedContent: 'mercado central updated'),
    );

    expect(
      (await repository.findByFilters(
        const ReceiptFilter(text: 'mercado'),
      )).map((receipt) => receipt.id),
      contains(market.id),
    );
    expect(await repository.findByTerms('despesa'), isNotEmpty);
    expect(
      (await repository.findByFilters(
        ReceiptFilter(
          type: ReceiptType.receipt,
          expense: false,
          categoryId: income.category!.id,
          startDate: DateTime(2026, 5, 21),
          endDate: DateTime(2026, 5, 23),
          sortOrder: ReceiptSort.amount,
          sortDirection: SortDirection.descending,
        ),
      )).single.id,
      income.id,
    );
    expect(
      (await repository.findByFilters(
        const ReceiptFilter(
          withoutCategory: true,
          sortOrder: ReceiptSort.establishment,
        ),
      )).single.id,
      withoutCategory.id,
    );

    final filteredSimilar = await repository.findSimilarByFilters(
      const EmbeddingVector(vector: [1, 0, 0], model: 'test', dimension: 3),
      ReceiptFilter(
        text: 'receita',
        type: ReceiptType.receipt,
        expense: false,
        categoryId: income.category!.id,
        startDate: DateTime(2026, 5, 21),
        endDate: DateTime(2026, 5, 23),
      ),
      5,
    );
    expect(filteredSimilar.map((receipt) => receipt.id), [income.id]);

    expect(
      await repository.findSimilarByFilters(
        const EmbeddingVector(vector: [1, 0, 0], model: 'test', dimension: 3),
        const ReceiptFilter(text: 'nao-encontra-nada'),
        5,
      ),
      isEmpty,
    );

    await repository.delete(withoutCategory.id);
    await expectLater(
      repository.watchAll(),
      emits(predicate<List<Receipt>>((items) => items.length == 2)),
    );
  });
}

Receipt _receipt({
  int id = 0,
  required String name,
  Category? category,
  double? value = 10,
  DateTime? date,
  String? establishment = 'Loja Teste',
  ReceiptType type = ReceiptType.invoice,
  bool expense = true,
  String content = 'fiscal test content',
  Embedding? embedding,
}) {
  final record = DateTime(2026, 5, 23, 8);
  return Receipt(
    id: id,
    type: type,
    expense: expense,
    fileName: name,
    fileType: 'image/png',
    extractedContent: content,
    registeredAt: record,
    category: category,
    extractedData: ExtractedData(
      id: 0,
      receiptId: id,
      amount: value,
      transactionDate: date,
      establishment: establishment,
      items: const ['item'],
      paymentMethod: 'Pix',
    ),
    embedding: embedding,
  );
}

Embedding _embedding() {
  return Embedding(
    id: 0,
    receiptId: 0,
    vector: _vectorBytes([1, 0, 0]),
    model: 'test',
    dimension: 3,
    generatedAt: DateTime(2026, 5, 24, 10),
  );
}

Uint8List _vectorBytes(List<double> values) {
  final bytes = ByteData(values.length * 8);
  for (var i = 0; i < values.length; i++) {
    bytes.setFloat64(i * 8, values[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}
