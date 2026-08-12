import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  UnitRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Unit _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Unit(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      name: r['name'] as String,
      abbreviation: r['abbreviation'] as String,
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<List<Unit>> findAll(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT * FROM units WHERE business_id = ? '
      '${includeInactive ? '' : 'AND is_active = 1'} '
      'ORDER BY name ASC;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Unit?> findById(int id) async {
    final rows = _db.select('SELECT * FROM units WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Unit?> findByAbbreviation(int businessId, String abbreviation) async {
    final rows = _db.select(
      'SELECT * FROM units WHERE business_id = ? AND abbreviation = ?;',
      [businessId, abbreviation],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Unit> insert(Unit unit) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO units '
      '(business_id, name, abbreviation, is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      [unit.businessId, unit.name, unit.abbreviation, unit.isActive ? 1 : 0, now, now],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Unit> update(Unit unit) async {
    _db.execute(
      'UPDATE units SET name = ?, abbreviation = ?, is_active = ?, '
      'updated_at = ? WHERE id = ?;',
      [
        unit.name,
        unit.abbreviation,
        unit.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        unit.id,
      ],
    );
    return (await findById(unit.id!))!;
  }

  @override
  Future<void> deactivate(int id) async {
    _db.execute(
      'UPDATE units SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }
}
