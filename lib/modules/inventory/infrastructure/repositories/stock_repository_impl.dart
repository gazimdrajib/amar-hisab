import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  StockRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Stock _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return Stock(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      productId: r['product_id'] as int,
      warehouseId: r['warehouse_id'] as int,
      quantity: d(r['quantity']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<Stock?> find(int businessId, int productId, int warehouseId) async {
    final rows = _db.select(
      'SELECT * FROM stock WHERE business_id = ? AND product_id = ? AND warehouse_id = ?;',
      [businessId, productId, warehouseId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<Stock>> findByProduct(int businessId, int productId) async {
    final rows = _db.select(
      'SELECT * FROM stock WHERE business_id = ? AND product_id = ?;',
      [businessId, productId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Stock>> findByWarehouse(int businessId, int warehouseId) async {
    final rows = _db.select(
      'SELECT * FROM stock WHERE business_id = ? AND warehouse_id = ?;',
      [businessId, warehouseId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Stock> upsertAdd(
      int businessId, int productId, int warehouseId, double delta) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO stock (business_id, product_id, warehouse_id, quantity, updated_at) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT (business_id, product_id, warehouse_id) '
      'DO UPDATE SET quantity = quantity + excluded.quantity, '
      '              updated_at = excluded.updated_at;',
      [businessId, productId, warehouseId, delta, now],
    );
    final found = await find(businessId, productId, warehouseId);
    return found!;
  }
}
