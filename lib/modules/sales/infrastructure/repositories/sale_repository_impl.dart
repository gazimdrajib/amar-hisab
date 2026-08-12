import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_payment.dart';
import '../../domain/repositories/sale_item_repository.dart';
import '../../domain/repositories/sale_payment_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// SQLite implementation of [SaleRepository]. Parameterised queries only;
/// the caller (SalesService) owns the surrounding transaction.
class SaleRepositoryImpl implements SaleRepository {
  SaleRepositoryImpl(this._db, this._itemRepo, this._paymentRepo);

  final Database _db;
  final SaleItemRepository _itemRepo;
  final SalePaymentRepository _paymentRepo;

  static const double _eps = 0.0001;

  // -- Mapper ---------------------------------------------------------------
  Sale _fromRow(Map<String, Object?> r) {
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    return Sale(
      id: r['id'] as int?,
      invoiceNumber: r['invoice_number'] as String?,
      customerId: r['customer_id'] as int?,
      saleDate: dt(r['sale_date']),
      saleType: (r['sale_type'] as String?) ?? 'POS',
      warehouseId: r['warehouse_id'] as int?,
      totalAmount: d(r['total_amount']),
      discountPercent: d(r['discount_percent']),
      discountAmount: d(r['discount_amount']),
      taxPercent: d(r['tax_percent']),
      taxAmount: d(r['tax_amount']),
      grandTotal: d(r['grand_total']),
      paidAmount: d(r['paid_amount']),
      dueAmount: d(r['due_amount']),
      status: (r['status'] as String?) ?? 'Completed',
      paymentStatus: (r['payment_status'] as String?) ?? 'Paid',
      note: r['note'] as String?,
      businessId: r['business_id'] as int,
      createdBy: r['created_by'] as int?,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<Sale> insert(Sale sale, List<SaleItem> items,
      List<SalePayment> payments) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO sales '
      '(invoice_number, customer_id, sale_date, sale_type, warehouse_id, '
      ' total_amount, discount_percent, discount_amount, tax_percent, '
      ' tax_amount, grand_total, paid_amount, due_amount, status, '
      ' payment_status, note, business_id, created_by, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        sale.invoiceNumber,
        sale.customerId,
        (sale.saleDate ?? DateTime.now()).toIso8601String().substring(0, 10),
        sale.saleType,
        sale.warehouseId,
        sale.totalAmount,
        sale.discountPercent,
        sale.discountAmount,
        sale.taxPercent,
        sale.taxAmount,
        sale.grandTotal,
        sale.paidAmount,
        sale.dueAmount,
        sale.status,
        sale.paymentStatus,
        sale.note,
        sale.businessId,
        sale.createdBy,
        now,
      ],
    );
    final saleId = _db.lastInsertRowId;
    for (final item in items) {
      await _itemRepo.insert(item.copyWith(saleId: saleId));
    }
    for (final payment in payments) {
      await _paymentRepo.insert(payment.copyWith(saleId: saleId));
    }
    return (await findById(saleId))!;
  }

  @override
  Future<Sale?> findById(int id) async {
    final rows = _db.select('SELECT * FROM sales WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<SaleDetail?> getDetail(int id) async {
    final sale = await findById(id);
    if (sale == null) return null;
    return SaleDetail(
      sale: sale,
      items: await _itemRepo.findBySale(id),
      payments: await _paymentRepo.findBySale(id),
    );
  }

  @override
  Future<List<Sale>> list(
    int businessId, {
    int? customerId,
    String? status,
    String? paymentStatus,
    String? saleType,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = StringBuffer('business_id = ?');
    final args = <Object?>[businessId];
    if (customerId != null) {
      where.write(' AND customer_id = ?');
      args.add(customerId);
    }
    if (status != null) {
      where.write(' AND status = ?');
      args.add(status);
    }
    if (paymentStatus != null) {
      where.write(' AND payment_status = ?');
      args.add(paymentStatus);
    }
    if (saleType != null) {
      where.write(' AND sale_type = ?');
      args.add(saleType);
    }
    if (fromDate != null) {
      where.write(' AND sale_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null) {
      where.write(' AND sale_date <= ?');
      args.add(toDate);
    }
    args.add(limit);
    args.add(offset);
    final rows = _db.select(
      'SELECT * FROM sales WHERE $where '
      'ORDER BY sale_date DESC, id DESC LIMIT ? OFFSET ?;',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Sale> update(Sale sale) async {
    _db.execute(
      'UPDATE sales SET sale_type = ?, warehouse_id = ?, status = ?, '
      'note = ?, updated_at = ? WHERE id = ?;',
      [
        sale.saleType,
        sale.warehouseId,
        sale.status,
        sale.note,
        DateTime.now().toUtc().toIso8601String(),
        sale.id,
      ],
    );
    return (await findById(sale.id!))!;
  }

  @override
  Future<void> cancel(int id) async {
    _db.execute(
      "UPDATE sales SET status = 'Cancelled', updated_at = ? WHERE id = ?;",
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }

  @override
  Future<Sale> refreshPaymentTotals(int saleId) async {
    final rows = _db.select(
      'SELECT COALESCE(SUM(amount), 0) AS paid FROM sale_payments '
      'WHERE sale_id = ?;',
      [saleId],
    );
    final paid =
        (rows.first['paid'] as num?)?.toDouble() ?? 0;
    final sale = await findById(saleId);
    if (sale == null) {
      throw StateError('Sale $saleId not found during payment refresh');
    }
    final due = sale.grandTotal - paid;
    final status = due <= _eps ? 'Paid' : (paid <= _eps ? 'Due' : 'Partial');
    _db.execute(
      'UPDATE sales SET paid_amount = ?, due_amount = ?, payment_status = ?, '
      'updated_at = ? WHERE id = ?;',
      [paid, due < 0 ? 0 : due, status,
       DateTime.now().toUtc().toIso8601String(), saleId],
    );
    return (await findById(saleId))!;
  }

  /// Append one payment row (Phase 9 – due collection after the sale).
  ///
  /// Parameterised SQL, caller manages the surrounding transaction together
  /// with the `change_log` outbox row (phase 9 Part B).
  @override
  Future<SalePayment> insertPayment(SalePayment payment) async {
    _db.execute(
      'INSERT INTO sale_payments '
      '(sale_id, amount, payment_method, reference, payment_date, created_by) '
      'VALUES (?, ?, ?, ?, ?, ?);',
      [
        payment.saleId,
        payment.amount,
        payment.paymentMethod,
        payment.reference,
        (payment.paymentDate ?? DateTime.now()).toUtc().toIso8601String(),
        payment.createdBy,
      ],
    );
    return payment.copyWith(id: _db.lastInsertRowId);
  }
}
