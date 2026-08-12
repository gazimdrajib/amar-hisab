import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/supplier_payment_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class SupplierPaymentRepositoryImpl implements SupplierPaymentRepository {
  SupplierPaymentRepositoryImpl(this._db);

  final Database _db;

  SupplierPayment _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return SupplierPayment(
      id: r['id'] as int?,
      supplierId: r['supplier_id'] as int?,
      purchaseId: r['purchase_id'] as int?,
      amount: d(r['amount']),
      paymentMethod: (r['payment_method'] as String?) ?? 'Cash',
      reference: r['reference'] as String?,
      paymentDate: dt(r['payment_date']),
      createdBy: r['created_by'] as int?,
    );
  }

  @override
  Future<List<SupplierPayment>> findByPurchase(int purchaseId) async {
    final rows = _db.select(
      'SELECT * FROM supplier_payments WHERE purchase_id = ? ORDER BY id;',
      [purchaseId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<SupplierPayment> insert(SupplierPayment payment) async {
    _db.execute(
      'INSERT INTO supplier_payments '
      '(supplier_id, purchase_id, amount, payment_method, reference, '
      ' payment_date, created_by) '
      'VALUES (?, ?, ?, ?, ?, ?, ?);',
      [
        payment.supplierId,
        payment.purchaseId,
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
