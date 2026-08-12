import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/sale_item_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class SaleItemRepositoryImpl implements SaleItemRepository {
  SaleItemRepositoryImpl(this._db);

  final Database _db;

  SaleItem _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return SaleItem(
      id: r['id'] as int?,
      saleId: r['sale_id'] as int?,
      productId: r['product_id'] as int,
      quantity: d(r['quantity']),
      unitPrice: d(r['unit_price']),
      discountPercent: d(r['discount_percent']),
      discountAmount: d(r['discount_amount']),
      taxPercent: d(r['tax_percent']),
      taxAmount: d(r['tax_amount']),
      lineTotal: d(r['line_total']),
    );
  }

  @override
  Future<List<SaleItem>> findBySale(int saleId) async {
    final rows = _db.select(
      'SELECT * FROM sale_items WHERE sale_id = ? ORDER BY id;',
      [saleId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SaleItem> insert(SaleItem item) async {
    _db.execute(
      'INSERT INTO sale_items '
      '(sale_id, product_id, quantity, unit_price, discount_percent, '
      ' discount_amount, tax_percent, tax_amount, line_total) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        item.saleId,
        item.productId,
        item.quantity,
        item.unitPrice,
        item.discountPercent,
        item.discountAmount,
        item.taxPercent,
        item.taxAmount,
        item.lineTotal,
      ],
    );
    return item.copyWith(id: _db.lastInsertRowId);
  }
}
