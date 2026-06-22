import '../../domain/entities/category.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/services/i_category_service.dart';
import '../../domain/value_objects/category_color_palette.dart';
import '../policies/category_deletion_policy.dart';

class CategoryService implements ICategoryService {
  CategoryService(this._categories);

  static const _deletionPolicy = CategoryDeletionPolicy();

  final ICategoryRepository _categories;

  @override
  Future<List<Category>> list() => _categories.list();

  @override
  Future<Category> create(
    String name, [
    String? description,
    String? icon,
    int? colorArgb,
  ]) async {
    final normalizedName = name.trim();
    final normalizedDescription = _normalizeDescription(description);
    if (normalizedName.isEmpty) {
      throw const FormatException('Informe um nome para a categoria.');
    }

    final existing = await _categories.findByName(normalizedName);
    if (existing != null) {
      throw const FormatException('Já existe uma categoria com esse nome.');
    }

    return _categories.save(
      Category(
        id: 0,
        name: normalizedName,
        description: normalizedDescription,
        icon: icon ?? 'category',
        colorArgb: normalizeCategoryColorArgb(
          colorArgb ?? CategoryColorPalette.noColor,
        ),
      ),
    );
  }

  @override
  Future<void> update(Category category) async {
    final normalizedName = category.name.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('Informe um nome para a categoria.');
    }
    final existing = await _categories.findByName(normalizedName);
    if (existing != null && existing.id != category.id) {
      throw const FormatException('Já existe uma categoria com esse nome.');
    }

    final normalizedDescription = _normalizeDescription(category.description);
    await _categories.update(
      category.copyWith(
        name: normalizedName,
        description: normalizedDescription,
        colorArgb: normalizeCategoryColorArgb(category.colorArgb),
        clearDescription: normalizedDescription == null,
      ),
    );
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    if (orderedIds.isEmpty) {
      return;
    }
    await _categories.reorder(orderedIds);
  }

  @override
  Future<void> delete(int id) async {
    _deletionPolicy.validateDeletion(
      hasAssociatedReceipts: await _categories.hasAssociatedReceipts(id),
    );
    await _categories.delete(id);
  }

  @override
  Future<bool> hasAssociatedReceipts(int id) {
    return _categories.hasAssociatedReceipts(id);
  }

  @override
  Stream<List<Category>> watchAll() => _categories.watchAll();

  String? _normalizeDescription(String? description) {
    final normalized = description?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
