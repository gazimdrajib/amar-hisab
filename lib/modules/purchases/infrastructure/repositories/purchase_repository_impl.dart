import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/repositories/purchase_item_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/supplier_payment_repository.dart';

/// SQLite implementation of [PurchaseRepository]. Parameterised queries only;
/// the caller (PurchaseService) owns the surrounding transaction.
class PurchaseRepositoryImpl implements PurchaseRepository {
  PurchaseRepositoryImpl(this._db, this._itemRepo, this._paymentRepo);

  final Database _db;
  final PurchaseItemRepository _itemRepo;
  final SupplierPaymentRepository _paymentRepo;

  static const double _eps = 0.0001;

  // -- Mapper ---------------------------------------------------------------
  Purchase _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Purchase(
      id: r['id'] as int?,
      invoiceNumber: r['invoice_number'] as String?,
      supplierId: r['supplier_id'] as int?,
      purchaseDate: dt(r['purchase_date']),
      warehouseId: r['warehouse_id'] as int?,
      totalAmount: d(r['total_amount']),
      discountPercent: d(r['discount_percent']),
      discountAmount: d(r['discount_amount']),
      taxPercent: d(r['tax_percent']),
      taxAmount: d(r['tax_amount']),
      grandTotal: d(r['grand_total']),
      paidAmount: d(r['paid_amount']),
      dueAmount: d(r['due_amount']),
      status: (r['status'] as String?) ?? 'Received',
      paymentStatus: (r['payment_status'] as String?) ?? 'Paid',
      note: r['note'] as String?,
      businessId: r['business_id'] as int,
      createdBy: r['created_by'] as int?,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<Purchase> insert(Purchase purchase, List<PurchaseItem> items,
      List<SupplierPayment> payments) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO purchases '
      '(invoice_number, supplier_id, purchase_date, warehouse_id, '
      ' total_amount, discount_percent, discount_amount, tax_percent, '
      ' tax_amount, grand_total, paid_amount, due_amount, status, '
      ' payment_status, note, business_id, created_by, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        purchase.invoiceNumber,
        purchase.supplierId,
        (purchase.purchaseDate ?? DateTime.now())
            .toIso8601String()
            .substring(0, 10),
        purchase.warehouseId,
        purchase.totalAmount,
        purchase.discountPercent,
        purchase.discountAmount,
        purchase.taxPercent,
        purchase.taxAmount,
        purchase.grandTotal,
        purchase.paidAmount,
        purchase.dueAmount,
        purchase.status,
        purchase.paymentStatus,
        purchase.note,
        purchase.businessId,
        purchase.createdBy,
        now,
      ],
    );
    final purchaseId = _db.lastInsertRowId;
    for (final item in items) {
      await _itemRepo.insert(item.copyWith(purchaseId: purchaseId));
    }
    for (final payment in payments) {
      await _paymentRepo.insert(payment.copyWith(
        purchaseId: purchaseId,
        supplierId: payment.supplierId ?? purchase.supplierId,
      ));
    }
    return (await findById(purchaseId))!;
  }

  @override
  Future<Purchase?> findById(int id) async {
    final rows = _db.select('SELECT * FROM purchases WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<PurchaseDetail?> getDetail(int id) async {
    final purchase = await findById(id);
    if (purchase == null) return null;
    return PurchaseDetail(
      purchase: purchase,
      items: await _itemRepo.findByPurchase(id),
      payments: await _paymentRepo.findByPurchase(id),
    );
  }

  @override
  Future<List<Purchase>> list(
    int businessId, {
    int? supplierId,
    String? status,
    String? paymentStatus,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = StringBuffer('business_id = ?');
    final args = <Object?>[businessId];
    if (supplierId != null) {
      where.write(' AND supplier_id = ?');
      args.add(supplierId);
    }
    if (status != null) {
      where.write(' AND status = ?');
      args.add(status);
    }
    if (paymentStatus != null) {
      where.write(' AND payment_status = ?');
      args.add(paymentStatus);
    }
    if (fromDate != null) {
      where.write(' AND purchase_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.write(' AND purchase_date <= ?');
      args.add(toDate);
    }
    args.add(limit);
    args.add(offset);
    final rows = _db.select(
      'SELECT * FROM purchases WHERE $where '
      'ORDER BY purchase_date DESC, id DESC LIMIT ? OFFSET ?;',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Purchase> update(Purchase purchase) async {
    _db.execute(
      'UPDATE purchases SET supplier_id = ?, warehouse_id = ?, status = ?, '
      'note = ?, updated_at = ? WHERE id = ?;',
      [
        purchase.supplierId,
        purchase.warehouseId,
        purchase.status,
        purchase.note,
        DateTime.now().toUtc().toIso8601String(),
        purchase.id,
      ],
    );
    return (await findById(purchase.id!))!;
  }

  @override
  Future<void> cancel(int id) async {
    _db.execute(
      "UPDATE purchases SET status = 'Cancelled', updated_at = ? WHERE id = ?;",
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }

  @override
  Future<Purchase> refreshPaymentTotals(int purchaseId) async {
    final rows = _db.select(
      'SELECT COALESCE(SUM(amount), 0) AS paid FROM supplier_payments '
      'WHERE purchase_id = ?;',
      [purchaseId],
    );
    final paid = (rows.first['paid'] as num?)?.toDouble() ?? 0;
    final purchase = await findById(purchaseId);
    if (purchase == null) {
      throw StateError('Purchase $purchaseId not found during payment refresh');
    }
    final due = purchase.grandTotal - paid;
    final status = due <= _eps ? 'Paid' : (paid <= _eps ? 'Due' : 'Partial');
    _db.execute(
      'UPDATE purchases SET paid_amount = ?, due_amount = ?, '
      'payment_status = ?, updated_at = ? WHERE id = ?;',
      [
        paid,
        due < 0 ? 0 : due,
        status,
        DateTime.now().toUtc().toIso8601String(),
        purchaseId,
      ],
    );
    return (await findById(purchaseId))!;
  }
}
