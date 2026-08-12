import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/brand.dart';
import '../../domain/repositories/brand_repository.dart';

class BrandRepositoryImpl implements BrandRepository {
  BrandRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Brand _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Brand(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      name: r['name'] as String,
      description: r['description'] as String?,
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<List<Brand>> findAll(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT * FROM brands WHERE business_id = ? '
      '${includeInactive ? '' : 'AND is_active = 1'} '
      'ORDER BY name ASC;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Brand?> findById(int id) async {
    final rows = _db.select('SELECT * FROM brands WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Brand?> findByName(int businessId, String name) async {
    final rows = _db.select(
      'SELECT * FROM brands WHERE business_id = ? AND name = ?;',
      [businessId, name],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Brand> insert(Brand brand) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO brands '
      '(business_id, name, description, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      [brand.businessId, brand.name, brand.description, brand.isActive ? 1 : 0, now, now],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Brand> update(Brand brand) async {
    _db.execute(
      'UPDATE brands SET name = ?, description = ?, is_active = ?, '
      'updated_at = ? WHERE id = ?;',
      [
        brand.name,
        brand.description,
        brand.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        brand.id,
      ],
    );
    return (await findById(brand.id!))!;
  }

  @override
  Future<void> deactivate(int id) async {
    _db.execute(
      'UPDATE brands SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }
}
