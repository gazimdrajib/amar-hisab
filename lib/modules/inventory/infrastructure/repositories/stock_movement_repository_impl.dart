import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_movement_repository.dart';

class StockMovementRepositoryImpl implements StockMovementRepository {
  StockMovementRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  StockMovement _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return StockMovement(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      productId: r['product_id'] as int,
      warehouseId: r['warehouse_id'] as int,
      batchId: r['batch_id'] as int?,
      movementType: r['movement_type'] as String,
      quantity: d(r['quantity']),
      referenceType: r['reference_type'] as String?,
      referenceId: r['reference_id'] as int?,
      note: r['note'] as String?,
      performedBy: r['performed_by'] as int?,
      createdAt: dt(r['created_at']),
    );
  }

  @override
  Future<StockMovement> insert(StockMovement movement) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO stock_movements '
      '(business_id, product_id, warehouse_id, batch_id, movement_type, '
      ' quantity, reference_type, reference_id, note, performed_by, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        movement.businessId,
        movement.productId,
        movement.warehouseId,
        movement.batchId,
        movement.movementType,
        movement.quantity,
        movement.referenceType,
        movement.referenceId,
        movement.note,
        movement.performedBy,
        now,
      ],
    );
    final id = _db.lastInsertRowId;
    return movement.copyWith(id: id, createdAt: DateTime.parse(now));
  }

  @override
  Future<List<StockMovement>> findByProduct(int businessId, int productId,
      {int limit = 200}) async {
    final rows = _db.select(
      'SELECT * FROM stock_movements WHERE business_id = ? AND product_id = ? '
      'ORDER BY id DESC LIMIT ?;',
      [businessId, productId, limit],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<StockMovement>> findByWarehouse(int businessId, int warehouseId,
      {int limit = 200}) async {
    final rows = _db.select(
      'SELECT * FROM stock_movements WHERE business_id = ? AND warehouse_id = ? '
      'ORDER BY id DESC LIMIT ?;',
      [businessId, warehouseId, limit],
    );
    return rows.map(_fromRow).toList();
  }
}
