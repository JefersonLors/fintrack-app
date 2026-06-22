import 'dart:async';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/category_repository.dart';
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

  test('category validates update association and reorder', () async {
    final categories = CategoryRepository(database);
    final receipts = ReceiptRepository(database);

    await expectLater(
      categories.update(const Category(id: 999, name: 'Fantasma')),
      throwsA(isA<StateError>()),
    );

    final pharmacy = await categories.save(
      const Category(id: 0, name: 'Farmácia', description: 'Saúde'),
    );
    final duplicate = await categories.save(
      const Category(id: 0, name: 'farmacia'),
    );
    expect(duplicate.id, pharmacy.id);

    await receipts.save(
      _receipt(
        name: 'pharmacy.png',
        category: pharmacy,
        establishment: 'Farmacia Central',
      ),
    );

    expect(await categories.hasAssociatedReceipts(pharmacy.id), isTrue);
    await expectLater(
      categories.delete(pharmacy.id),
      throwsA(isA<StateError>()),
    );

    final ids = (await categories.list()).map((category) => category.id);
    await expectLater(
      categories.reorder(ids.take(2).toList()),
      throwsA(isA<FormatException>()),
    );
  });

  test('watched categories react to insert order and deletion', () async {
    final repository = CategoryRepository(database);
    final events = <List<Category>>[];
    late StreamSubscription<List<Category>> subscription;
    subscription = repository.watchAll().listen(events.add);
    addTearDown(() async => subscription.cancel());

    final housing = await repository.save(
      const Category(id: 0, name: 'Moradia'),
    );
    final leisure = await repository.save(const Category(id: 0, name: 'Lazer'));

    final remaining = (await repository.list())
        .map((category) => category.id)
        .where((id) => id != leisure.id && id != housing.id);
    await expectLater(
      repository.reorder([leisure.id, housing.id, ...remaining]),
      completes,
    );
    await repository.delete(housing.id);

    await expectLater(
      repository.watchAll(),
      emits(
        predicate<List<Category>>(
          (categories) =>
              categories.isNotEmpty &&
              categories.any((category) => category.id == leisure.id) &&
              !categories.any((category) => category.id == housing.id),
        ),
      ),
    );
    expect(events, isNotEmpty);
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
  );
}
