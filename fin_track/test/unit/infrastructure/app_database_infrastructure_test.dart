import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'in-memory database creates auxiliary structures and initial data',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      final configurations = await database
          .select(database.configurations)
          .get();
      expect(configurations, hasLength(1));

      final categories = await database.select(database.categories).get();
      expect(categories.map((category) => category.name), contains('Pix'));
      expect(categories.map((category) => category.name), contains('Outros'));

      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
          )
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      expect(names, contains('receipt_fts'));
      expect(names, contains('embedding_vector'));
      expect(names, contains('fiscal_document_cache'));
      expect(names, contains('category_order'));
      expect(names, contains('idx_receipt_category'));
      expect(names, contains('idx_fiscal_document_cache_issuer_cnpj'));

      final sortOrder = await database
          .customSelect('SELECT category_id, sort_order FROM category_order')
          .get();
      expect(sortOrder, hasLength(categories.length));

      final busyTimeout = await database
          .customSelect('PRAGMA busy_timeout')
          .getSingle();
      expect(busyTimeout.read<int>('timeout'), 5000);
    },
  );

  test(
    'initial data restores missing categories without duplicating existing ones',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);

      await database.customStatement(
        "DELETE FROM category WHERE name = 'Investimentos'",
      );
      final countBefore = await database
          .customSelect(
            "SELECT COUNT(*) AS total FROM category WHERE name = 'Investimentos'",
          )
          .getSingle();
      expect(countBefore.read<int>('total'), 0);

      await database.ensureInitialDataForTesting();
      await database.ensureInitialDataForTesting();

      final countAfter = await database
          .customSelect(
            "SELECT COUNT(*) AS total FROM category WHERE name = 'Investimentos'",
          )
          .getSingle();
      expect(countAfter.read<int>('total'), 1);
    },
  );
}
