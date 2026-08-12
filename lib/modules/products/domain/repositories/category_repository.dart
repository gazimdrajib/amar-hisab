import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> findAll(int businessId, {bool includeInactive = false});
  Future<Category?> findById(int id);
  Future<Category?> findByName(int businessId, String name);
  Future<Category> insert(Category category);
  Future<Category> update(Category category);
  Future<void> deactivate(int id);
}
