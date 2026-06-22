import 'package:drift/drift.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/value_objects/category_color_palette.dart';
import 'app_database.dart';

class CategoryRepository implements ICategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  static const _orderedCategoriesSql = '''
SELECT c.id AS id,
       c.name AS name,
       c.description AS description,
       c.inferred_automatically AS inferred_automatically,
       c.icon AS icon,
       c.color_argb AS color_argb
FROM category c
LEFT JOIN category_order o ON o.category_id = c.id
ORDER BY COALESCE(o.sort_order, c.id), c.id
''';

  @override
  Future<List<Category>> list() async {
    final rows = await _database.customSelect(_orderedCategoriesSql).get();
    return rows.map(_mapCategoryQuery).toList();
  }

  @override
  Future<Category> save(Category category) async {
    final existing = await findByName(category.name);
    if (existing != null) {
      return existing;
    }

    final id = await _database
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
    await _database.customStatement(
      'INSERT INTO category_order (category_id, sort_order) '
      'VALUES (?, COALESCE((SELECT MAX(sort_order) + 1 FROM category_order), ?)) '
      'ON CONFLICT(category_id) DO NOTHING',
      [id, id],
    );
    return (await findById(id))!;
  }

  @override
  Future<void> update(Category category) async {
    final count =
        await (_database.update(
          _database.categories,
        )..where((tbl) => tbl.id.equals(category.id))).write(
          CategoriesCompanion(
            name: Value(category.name),
            description: Value(category.description),
            inferredAutomatically: Value(category.inferredAutomatically),
            icon: Value(category.icon),
            colorArgb: Value(normalizeCategoryColorArgb(category.colorArgb)),
          ),
        );
    if (count == 0) {
      throw StateError('Categoria não encontrada.');
    }
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    final rows = await _database.select(_database.categories).get();
    if (rows.length != orderedIds.length) {
      throw const FormatException(
        'A reordenação deve incluir todas as categorias.',
      );
    }

    final currentIds = rows.map((row) => row.id).toSet();
    final receivedIds = orderedIds.toSet();
    if (currentIds.length != receivedIds.length ||
        !currentIds.containsAll(receivedIds)) {
      throw const FormatException('Ordem de categorias inválida.');
    }

    await _database.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await _database.customStatement(
          'INSERT INTO category_order (category_id, sort_order) VALUES (?, ?) '
          'ON CONFLICT(category_id) DO UPDATE SET sort_order = excluded.sort_order',
          [orderedIds[index], index],
        );
      }
    });
    _database.notifyUpdates({
      const TableUpdate('category', kind: UpdateKind.update),
    });
  }

  @override
  Future<void> delete(int id) async {
    if (await hasAssociatedReceipts(id)) {
      throw StateError('Categoria associada a comprovantes.');
    }
    await (_database.delete(
      _database.categories,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<bool> hasAssociatedReceipts(int id) async {
    final row = await (_database.select(
      _database.receipts,
    )..where((tbl) => tbl.categoryId.equals(id))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<Category?> findById(int id) async {
    final row = await (_database.select(
      _database.categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapCategory(row);
  }

  @override
  Future<Category?> findByName(String name) async {
    final normalized = _normalizeName(name);
    final rows = await _database.select(_database.categories).get();
    for (final row in rows) {
      if (_normalizeName(row.name) == normalized) {
        return _mapCategory(row);
      }
    }
    return null;
  }

  @override
  Stream<List<Category>> watchAll() {
    return _database
        .customSelect(_orderedCategoriesSql, readsFrom: {_database.categories})
        .watch()
        .map((rows) => rows.map(_mapCategoryQuery).toList());
  }

  Category _mapCategory(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      description: row.description,
      inferredAutomatically: row.inferredAutomatically,
      icon: row.icon,
      colorArgb: normalizeCategoryColorArgb(row.colorArgb),
    );
  }

  Category _mapCategoryQuery(QueryRow row) {
    return Category(
      id: row.read<int>('id'),
      name: row.read<String>('name'),
      description: row.read<String?>('description'),
      inferredAutomatically: row.read<bool>('inferred_automatically'),
      icon: row.read<String>('icon'),
      colorArgb: normalizeCategoryColorArgb(row.read<int>('color_argb')),
    );
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
