import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Category _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Category(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      name: r['name'] as String,
      description: r['description'] as String?,
      parentId: r['parent_id'] as int?,
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<List<Category>> findAll(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT * FROM categories WHERE business_id = ? '
      '${includeInactive ? '' : 'AND is_active = 1'} '
      'ORDER BY name ASC;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Category?> findById(int id) async {
    final rows = _db.select('SELECT * FROM categories WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Category?> findByName(int businessId, String name) async {
    final rows = _db.select(
      'SELECT * FROM categories WHERE business_id = ? AND name = ?;',
      [businessId, name],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Category> insert(Category category) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO categories '
      '(business_id, name, description, parent_id, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?);',
      [
        category.businessId,
        category.name,
        category.description,
        category.parentId,
        category.isActive ? 1 : 0,
        now,
        now,
      ],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Category> update(Category category) async {
    _db.execute(
      'UPDATE categories SET name = ?, description = ?, parent_id = ?, '
      'is_active = ?, updated_at = ? WHERE id = ?;',
      [
        category.name,
        category.description,
        category.parentId,
        category.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        category.id,
      ],
    );
    return (await findById(category.id!))!;
  }

  @override
  Future<void> deactivate(int id) async {
    _db.execute(
      'UPDATE categories SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }
}
