import '../entities/category.dart';

abstract class ICategoryRepository {
  Future<List<Category>> list();
  Future<Category> save(Category category);
  Future<void> update(Category category);
  Future<void> reorder(List<int> orderedIds);
  Future<void> delete(int id);
  Future<bool> hasAssociatedReceipts(int id);
  Future<Category?> findById(int id);
  Future<Category?> findByName(String name);
  Stream<List<Category>> watchAll();
}
