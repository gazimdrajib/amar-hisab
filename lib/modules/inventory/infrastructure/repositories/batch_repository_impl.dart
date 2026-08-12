import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/batch.dart';
import '../../domain/repositories/batch_repository.dart';

class BatchRepositoryImpl implements BatchRepository {
  BatchRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Batch _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return Batch(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      productId: r['product_id'] as int,
      warehouseId: r['warehouse_id'] as int,
      batchNumber: r['batch_number'] as String?,
      purchasePrice: d(r['purchase_price']),
      expiryDate: dt(r['expiry_date']),
      receivedAt: dt(r['received_at']) ?? DateTime.now(),
      quantity: d(r['quantity']),
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
    );
  }

  @override
  Future<List<Batch>> findByProduct(int businessId, int productId,
      {int? warehouseId}) async {
    final parameters = <Object?>[businessId, productId];
    var sql =
        'SELECT * FROM batches WHERE business_id = ? AND product_id = ?';
    if (warehouseId != null) {
      sql += ' AND warehouse_id = ?';
      parameters.add(warehouseId);
    }
    sql += ' ORDER BY received_at ASC, id ASC;';
    final rows = _db.select(sql, parameters);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Batch>> findFifoBatches(
      int businessId, int productId, int warehouseId) async {
    final rows = _db.select(
      'SELECT * FROM batches '
      'WHERE business_id = ? AND product_id = ? AND warehouse_id = ? '
      '  AND is_active = 1 AND quantity > 0 '
      'ORDER BY received_at ASC, id ASC;',
      [businessId, productId, warehouseId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Batch?> findById(int id) async {
    final rows = _db.select('SELECT * FROM batches WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Batch> insert(Batch batch) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO batches '
      '(business_id, product_id, warehouse_id, batch_number, purchase_price, '
      ' expiry_date, received_at, quantity, is_active, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        batch.businessId,
        batch.productId,
        batch.warehouseId,
        batch.batchNumber,
        batch.purchasePrice,
        batch.expiryDate?.toIso8601String(),
        batch.receivedAt.toIso8601String(),
        batch.quantity,
        batch.isActive ? 1 : 0,
        now,
      ],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Batch> update(Batch batch) async {
    _db.execute(
      'UPDATE batches SET batch_number = ?, purchase_price = ?, expiry_date = ?, '
      'received_at = ?, quantity = ?, is_active = ? WHERE id = ?;',
      [
        batch.batchNumber,
        batch.purchasePrice,
        batch.expiryDate?.toIso8601String(),
        batch.receivedAt.toIso8601String(),
        batch.quantity,
        batch.isActive ? 1 : 0,
        batch.id,
      ],
    );
    return (await findById(batch.id!))!;
  }

  @override
  Future<void> adjustQuantity(int id, double newQuantity) async {
    _db.execute(
      'UPDATE batches SET quantity = ? WHERE id = ?;',
      [newQuantity, id],
    );
  }
}
