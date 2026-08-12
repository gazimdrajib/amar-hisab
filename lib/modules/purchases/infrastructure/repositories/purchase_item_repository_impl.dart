import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_item_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class PurchaseItemRepositoryImpl implements PurchaseItemRepository {
  PurchaseItemRepositoryImpl(this._db);

  final Database _db;

  PurchaseItem _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return PurchaseItem(
      id: r['id'] as int?,
      purchaseId: r['purchase_id'] as int?,
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
  Future<List<PurchaseItem>> findByPurchase(int purchaseId) async {
    final rows = _db.select(
      'SELECT * FROM purchase_items WHERE purchase_id = ? ORDER BY id;',
      [purchaseId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<PurchaseItem> insert(PurchaseItem item) async {
    _db.execute(
      'INSERT INTO purchase_items '
      '(purchase_id, product_id, quantity, unit_price, discount_percent, '
      ' discount_amount, tax_percent, tax_amount, line_total) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        item.purchaseId,
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
