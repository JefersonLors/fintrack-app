import 'package:drift/drift.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/value_objects/category_color_palette.dart';
import '../app_database.dart';

class ReceiptCategoryPersistence {
  const ReceiptCategoryPersistence(this._database);

  final AppDatabase _database;

  Future<int?> categoryId(Category? category) async {
    if (category == null) {
      return null;
    }
    return ensureCategory(category);
  }

  Future<int> ensureCategory(Category category) async {
    if (category.id > 0) {
      final existing = await (_database.select(
        _database.categories,
      )..where((tbl) => tbl.id.equals(category.id))).getSingleOrNull();
      if (existing != null) {
        return existing.id;
      }
    }

    final byName = await _findByNormalizedName(category.name);
    if (byName != null) {
      return byName.id;
    }

    return _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: category.name,
            description: Value(category.description),
            inferredAutomatically: Value(category.inferredAutomatically),
            icon: Value(category.icon),
            colorArgb: Value(normalizeCategoryColorArgb(category.colorArgb)),
          ),
        );
  }

  Future<CategoryRow?> _findByNormalizedName(String name) async {
    final normalized = _normalizeName(name);
    final rows = await _database.select(_database.categories).get();
    for (final row in rows) {
      if (_normalizeName(row.name) == normalized) {
        return row;
      }
    }
    return null;
  }

  String _normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
