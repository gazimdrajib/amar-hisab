import '../../domain/entities/sale_payment.dart';
import '../../domain/repositories/sale_payment_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class SalePaymentRepositoryImpl implements SalePaymentRepository {
  SalePaymentRepositoryImpl(this._db);

  final Database _db;

  SalePayment _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return SalePayment(
      id: r['id'] as int?,
      saleId: r['sale_id'] as int?,
      amount: d(r['amount']),
      paymentMethod: (r['payment_method'] as String?) ?? 'Cash',
      reference: r['reference'] as String?,
      paymentDate: dt(r['payment_date']),
      createdBy: r['created_by'] as int?,
    );
  }

  @override
  Future<List<SalePayment>> findBySale(int saleId) async {
    final rows = _db.select(
      'SELECT * FROM sale_payments WHERE sale_id = ? ORDER BY id;',
      [saleId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SalePayment> insert(SalePayment payment) async {
    _db.execute(
      'INSERT INTO sale_payments '
      '(sale_id, amount, payment_method, reference, payment_date, created_by) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      [
        payment.saleId,
        payment.amount,
        payment.paymentMethod,
        payment.reference,
        (payment.paymentDate ?? DateTime.now()).toIso8601String(),
        payment.createdBy,
      ],
    );
    return payment.copyWith(id: _db.lastInsertRowId);
  }
}
