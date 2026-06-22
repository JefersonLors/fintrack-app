import '../entities/category.dart';

abstract class ICategoryService {
  Future<List<Category>> list();
  Future<Category> create(
    String name, [
    String? description,
    String? icon,
    int? colorArgb,
  ]);
  Future<void> update(Category category);
  Future<void> reorder(List<int> orderedIds);
  Future<void> delete(int id);
  Future<bool> hasAssociatedReceipts(int id);
  Stream<List<Category>> watchAll();
}
