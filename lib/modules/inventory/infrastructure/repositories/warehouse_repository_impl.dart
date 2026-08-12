import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  WarehouseRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Warehouse _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Warehouse(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      name: r['name'] as String,
      location: r['location'] as String?,
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<List<Warehouse>> findAll(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT * FROM warehouses WHERE business_id = ? '
      '${includeInactive ? '' : 'AND is_active = 1'} '
      'ORDER BY name ASC;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Warehouse?> findById(int id) async {
    final rows = _db.select('SELECT * FROM warehouses WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Warehouse?> findByName(int businessId, String name) async {
    final rows = _db.select(
      'SELECT * FROM warehouses WHERE business_id = ? AND name = ?;',
      [businessId, name],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Warehouse> insert(Warehouse warehouse) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO warehouses '
      '(business_id, name, location, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      [warehouse.businessId, warehouse.name, warehouse.location,
       warehouse.isActive ? 1 : 0, now, now],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Warehouse> update(Warehouse warehouse) async {
    _db.execute(
      'UPDATE warehouses SET name = ?, location = ?, is_active = ?, '
      'updated_at = ? WHERE id = ?;',
      [
        warehouse.name,
        warehouse.location,
        warehouse.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        warehouse.id,
      ],
    );
    return (await findById(warehouse.id!))!;
  }

  @override
  Future<void> deactivate(int id) async {
    _db.execute(
      'UPDATE warehouses SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }
}
