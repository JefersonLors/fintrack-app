import 'dart:io';

import 'package:drift/native.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/infrastructure/i_embedding_service.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates and edits category with normalized data', () async {
    final dependencies = _dependencies();
    addTearDown(dependencies.dispose);

    final category = await dependencies.categoryService.create(
      '  Doações  ',
      '  Serviços recorrentes  ',
    );

    expect(category.name, 'Doações');
    expect(category.description, 'Serviços recorrentes');

    await dependencies.categoryService.update(
      category.copyWith(
        name: '  Apps  ',
        description: '',
        clearDescription: true,
      ),
    );

    final updated = (await dependencies.categoryService.list()).singleWhere(
      (item) => item.id == category.id,
    );

    expect(updated.name, 'Apps');
    expect(updated.description, isNull);
  });

  test('prevents creating or editing category with duplicate name', () async {
    final dependencies = _dependencies();
    addTearDown(dependencies.dispose);

    await expectLater(
      dependencies.categoryService.create('Alimentacao'),
      throwsFormatException,
    );

    final newCategory = await dependencies.categoryService.create('Eventos');

    await expectLater(
      dependencies.categoryService.update(
        newCategory.copyWith(name: 'Transporte'),
      ),
      throwsFormatException,
    );
  });

  test('prevents deleting category associated with receipt', () async {
    final dependencies = _dependencies();
    addTearDown(dependencies.dispose);

    final category = (await dependencies.categoryService.list()).first;
    await _saveTestReceipt(
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'associated_category.txt',
        fileType: 'text/plain',
        registeredAt: DateTime(2026, 4, 30),
        category: category,
      ),
    );

    expect(
      await dependencies.categoryService.hasAssociatedReceipts(category.id),
      isTrue,
    );
    await expectLater(
      dependencies.categoryService.delete(category.id),
      throwsFormatException,
    );
    expect(
      (await dependencies.categoryService.list()).any(
        (item) => item.id == category.id,
      ),
      isTrue,
    );
  });

  test('reorders categories without changing their identities', () async {
    final dependencies = _dependencies();
    addTearDown(dependencies.dispose);

    final categories = await dependencies.categoryService.list();
    final originalOrder = categories.map((category) => category.id).toList();
    final newOrder = <int>[
      originalOrder[2],
      originalOrder[0],
      originalOrder[1],
      ...originalOrder.skip(3),
    ];

    await dependencies.categoryService.reorder(newOrder);

    final reordered = await dependencies.categoryService.list();
    expect(reordered.map((category) => category.id), newOrder);
    expect(reordered.map((category) => category.id).toSet(), {
      ...originalOrder,
    });
  });

  test(
    'does not recreate initial categories after deletion and reopening',
    () async {
      final databaseFile = File(
        '${Directory.systemTemp.path}/fin_track_category_seed_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (await databaseFile.exists()) {
          await databaseFile.delete();
        }
      });

      final firstOpening = _dependencies(
        database: AppDatabase(NativeDatabase(databaseFile)),
      );
      final initialCategories = await firstOpening.categoryService.list();
      expect(initialCategories, isNotEmpty);

      for (final category in initialCategories) {
        await firstOpening.categoryService.delete(category.id);
      }
      expect(await firstOpening.categoryService.list(), isEmpty);
      firstOpening.dispose();

      final secondOpening = _dependencies(
        database: AppDatabase(NativeDatabase(databaseFile)),
      );
      addTearDown(secondOpening.dispose);

      expect(await secondOpening.categoryService.list(), isEmpty);
    },
  );
}

FinTrackDependencies _dependencies({AppDatabase? database}) {
  return FinTrackDependencies.local(
    database: database,
    embeddings: _TestEmbeddingService(),
  );
}

class _TestEmbeddingService implements IEmbeddingService {
  @override
  Future<EmbeddingVector> generate(String text) async {
    return EmbeddingVector(
      vector: List<double>.filled(8, 0.125),
      model: 'test',
      dimension: 8,
    );
  }
}

Future<Receipt> _saveTestReceipt(
  FinTrackDependencies dependencies,
  Receipt receipt,
) async {
  final file = File(
    '${Directory.systemTemp.path}/fin_track_category_${DateTime.now().microsecondsSinceEpoch}_${receipt.fileName}',
  );
  await file.writeAsString('test receipt');
  return dependencies.receiptService.saveConfirmed(
    receipt.copyWith(id: 0, fileName: file.path),
  );
}
