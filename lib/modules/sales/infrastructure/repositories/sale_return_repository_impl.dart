import '../../domain/entities/sale_return.dart';
import '../../domain/repositories/sale_return_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class SaleReturnRepositoryImpl implements SaleReturnRepository {
  SaleReturnRepositoryImpl(this._db);

  final Database _db;

  SaleReturn _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final restock = r['restock'];
    return SaleReturn(
      id: r['id'] as int?,
      saleId: r['sale_id'] as int,
      returnDate: dt(r['return_date']),
      reason: r['reason'] as String?,
      restock: restock == 1 || restock == true || restock == '1',
      refundAmount: d(r['refund_amount']),
      refundMethod: r['refund_method'] as String?,
      createdAt: dt(r['created_at']),
    );
  }

  @override
  Future<SaleReturn> insert(SaleReturn saleReturn) async {
    _db.execute(
      'INSERT INTO sales_returns '
      '(sale_id, return_date, reason, restock, refund_amount, refund_method, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?);',
      [
        saleReturn.saleId,
        (saleReturn.returnDate ?? DateTime.now()).toIso8601String(),
        saleReturn.reason,
        saleReturn.restock ? 1 : 0,
        saleReturn.refundAmount,
        saleReturn.refundMethod,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
    return saleReturn.copyWith(id: _db.lastInsertRowId);
  }

  @override
  Future<List<SaleReturn>> findBySale(int saleId) async {
    final rows = _db.select(
      'SELECT * FROM sales_returns WHERE sale_id = ? ORDER BY id;',
      [saleId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SaleReturn?> findById(int id) async {
    final rows =
        _db.select('SELECT * FROM sales_returns WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }
}
