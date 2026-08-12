import '../../../../core/events/domain_event.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/change_log_service.dart';
import '../../../accounting/application/services/journal_service.dart';
import '../../../accounting/domain/entities/journal_line.dart';
import '../../../inventory/application/services/inventory_service.dart';
import '../../../inventory/application/services/warehouse_service.dart'
    show InventoryServiceException;
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_payment.dart';
import '../../domain/entities/sale_return.dart';
import '../../domain/events/sales_events.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/sale_return_repository.dart';

/// Error raised by [SalesService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class SalesServiceException implements Exception {
  const SalesServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SalesServiceException($code): $message';
}

/// Orchestrates the sales workflow (Architecture Book §14.2):
///
///  * [createSale] – validates items, computes totals, persists the sale
///    header/items/payments, deducts stock FIFO, posts accounting, then
///    publishes [SaleCompleted] **after commit** (Event Catalog §3.1).
///  * [processReturn] – records the return, optionally restocks, marks the
///    original sale `Returned`, then publishes [SaleReturned].
///  * [getSale] / [listSales] / [updateSale] / [deleteSale] – queries and
///    lifecycle mutations guarded by RBAC at the controller layer.
class SalesService {
  SalesService(
    this._saleRepo,
    this._returnRepo,
    this._inventoryService,
    this._audit,
    this._events, {
    JournalService? journalService,
    AccountLookup? accountLookup,
    ChangeLogService? changeLog,
  })  : _journalService = journalService,
        _accountLookup = accountLookup,
        _changeLog = changeLog;

  final SaleRepository _saleRepo;
  final SaleReturnRepository _returnRepo;
  final InventoryService _inventoryService;
  final AuditService _audit;
  final EventBus _events;
  final JournalService? _journalService;
  final AccountLookup? _accountLookup;

  /// Transactional outbox writer (Phase 9 Part B): every mutation records a
  /// `change_log` row INSIDE the same transaction as the business data.
  final ChangeLogService? _changeLog;

  static const double _eps = 0.0001;

  /// Sale statuses that may still be edited via [updateSale].
  static const _editableStatuses = {'Draft', 'Hold'};

  // -- Queries ----------------------------------------------------------------

  Future<SaleDetail?> getSale(int businessId, int id) async {
    final detail = await _saleRepo.getDetail(id);
    if (detail == null || detail.sale.businessId != businessId) return null;
    return detail;
  }

  Future<List<Sale>> listSales(
    int businessId, {
    int? customerId,
    String? status,
    String? paymentStatus,
    String? saleType,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) =>
      _saleRepo.list(
        businessId,
        customerId: customerId,
        status: status,
        paymentStatus: paymentStatus,
        saleType: saleType,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );

  Future<List<SaleReturn>> returnsFor(int businessId, int saleId) async {
    final sale = await _ownedSale(businessId, saleId);
    return _returnRepo.findBySale(sale.id!);
  }

  /// Record a due-collection payment against an existing sale
  /// (Event Catalog §3.1 `PaymentReceived`).
  ///
  /// Atomic with the transactional outbox row: the payment INSERT and the
  /// `change_log` entry commit together; the domain event is published only
  /// after COMMIT.
  Future<SalePayment> receivePayment({
    required int businessId,
    required int saleId,
    required DateTime? paymentDate,
    required String paymentMethod,
    required double amount,
    String? reference,
    required int actorId,
  }) async {
    if (amount <= 0) {
      throw const SalesServiceException(
          'invalid_payment', 'Payment amount must be greater than zero');
    }

    final sale = await _ownedSale(businessId, saleId);
    if (sale.status != 'Completed') {
      throw const SalesServiceException(
          'invalid_state', 'Only a Completed sale can receive payments');
    }

    // The payment INSERT and header-refresh happen inside the caller's
    // transactional unit (Phase 9 Part B). The repository hides the join to
    // the payments ledger behind a single repo method (added for Phase 9).
    final paid = await _saleRepo.insertPayment(SalePayment(
      saleId: sale.id,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      paymentDate: paymentDate ?? DateTime.now(),
      createdBy: actorId,
    ));
    final refreshed =
        await _saleRepo.refreshPaymentTotals(sale.id!);

    _audit.logAction(
      userId: actorId,
      entityType: 'sale_payment',
      entityId: paid.id ?? 0,
      action: 'create',
      newValue:
          'sale=$saleId; amount=$amount; method=$paymentMethod; due=${refreshed.dueAmount}',
      businessId: businessId,
    );

    _changeLog?.recordChange(
      entityType: 'sale_payment',
      entityId: paid.id ?? 0,
      operation: ChangeOperation.insert,
      payload: {
        'id': paid.id,
        'sale_id': saleId,
        'amount': amount,
        'payment_method': paymentMethod,
        'reference': reference,
        'payment_date': paid.paymentDate?.toIso8601String(),
      },
      businessId: businessId,
    );
    _changeLog?.recordChange(
      entityType: 'sale',
      entityId: sale.id!,
      operation: ChangeOperation.update,
      payload: {
        'id': sale.id,
        'paid_amount': refreshed.paidAmount,
        'due_amount': refreshed.dueAmount,
        'payment_status': refreshed.paymentStatus,
      },
      oldValues: {
        'paid_amount': sale.paidAmount,
        'due_amount': sale.dueAmount,
        'payment_status': sale.paymentStatus,
      },
      businessId: businessId,
    );

    _events.publish(PaymentReceived(
      saleId: saleId,
      paymentId: paid.id,
      amount: amount,
      method: paymentMethod,
      businessId: businessId,
    ));
    return paid;
  }

  // -- Commands ---------------------------------------------------------------

  /// Create a sale. When [status] is `Completed`, the whole workflow
  /// (header + items + payments + FIFO stock deduction) runs inside ONE
  /// SQLite transaction so a partial write can never persist; the
  /// [SaleCompleted] domain event is published only after COMMIT.
  Future<SaleDetail> createSale({
    required int businessId,
    int? customerId,
    required int warehouseId,
    DateTime? saleDate,
    String saleType = 'POS',
    double discountPercent = 0,
    double taxPercent = 0,
    String? note,
    required List<SaleItem> items,
    List<SalePayment> payments = const [],
    required int actorId,
    String status = 'Completed',
  }) async {
    if (items.isEmpty) {
      throw const SalesServiceException(
          'empty_sale', 'A sale must contain at least one item');
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        throw const SalesServiceException(
            'invalid_item', 'Item quantity must be greater than zero');
      }
      if (item.unitPrice < 0) {
        throw const SalesServiceException(
            'invalid_item', 'Item unit price cannot be negative');
      }
    }

    // -- Totals ---------------------------------------------------------------
    final computedItems = items.map((i) {
      final base = i.quantity * i.unitPrice;
      final discount = i.discountAmount > 0
          ? i.discountAmount
          : base * i.discountPercent / 100;
      final taxable = base - discount;
      final tax = i.taxAmount > 0 ? i.taxAmount : taxable * i.taxPercent / 100;
      return i.copyWith(
        discountAmount: discount,
        taxAmount: tax,
        lineTotal: taxable + tax,
      );
    }).toList();

    final totalAmount =
        computedItems.fold<double>(0, (s, i) => s + i.lineTotal);
    final discountAmount = totalAmount * discountPercent / 100;
    final afterDiscount = totalAmount - discountAmount;
    final taxAmount = afterDiscount * taxPercent / 100;
    final grandTotal = afterDiscount + taxAmount;
    final paidAmount = payments.fold<double>(0, (s, p) => s + p.amount);
    if (paidAmount - grandTotal > _eps) {
      throw const SalesServiceException(
          'overpayment', 'Payments exceed the grand total');
    }
    final dueAmount = grandTotal - paidAmount;
    final paymentStatus =
        dueAmount <= _eps ? 'Paid' : (paidAmount <= _eps ? 'Due' : 'Partial');

    final invoiceNumber =
        'INV-${DateTime.now().year}-${DateTime.now().microsecondsSinceEpoch}';
    final effectiveDate = saleDate ?? DateTime.now();
    late SaleDetail detail;

    Future<void> persistAndDeduct() {
      return _inventoryService.runInTransaction(() async {
        final header = await _saleRepo.insert(
          Sale(
            invoiceNumber: invoiceNumber,
            customerId: customerId,
            saleDate: effectiveDate,
            saleType: saleType,
            warehouseId: warehouseId,
            totalAmount: totalAmount,
            discountPercent: discountPercent,
            discountAmount: discountAmount,
            taxPercent: taxPercent,
            taxAmount: taxAmount,
            grandTotal: grandTotal,
            paidAmount: paidAmount,
            dueAmount: dueAmount < 0 ? 0 : dueAmount,
            status: status,
            paymentStatus: paymentStatus,
            note: note,
            businessId: businessId,
            createdBy: actorId,
          ),
          computedItems,
          payments
              .map((p) => p.copyWith(
                    createdBy: p.createdBy ?? actorId,
                    paymentDate: p.paymentDate ?? effectiveDate,
                  ))
              .toList(),
        );

        // Deduct stock FIFO only for completed sales (Draft/Hold hold no stock).
        if (status == 'Completed') {
          for (final item in computedItems) {
            await _inventoryService.deductStock(
              businessId: businessId,
              productId: item.productId,
              warehouseId: warehouseId,
              quantity: item.quantity,
              movementType: 'sale',
              referenceType: 'sale',
              referenceId: header.id,
              note: 'Sale ${header.invoiceNumber}',
              actorId: actorId,
            );
          }
        }

        // Transactional outbox (Event Catalog §4.2): the sale sync payload is
        // the full header + items + payments snapshot, written INSIDE the same
        // transaction.
        _changeLog?.recordChange(
          entityType: 'sale',
          entityId: header.id!,
          operation: ChangeOperation.insert,
          payload: {
            'id': header.id,
            'invoice_number': header.invoiceNumber,
            'customer_id': header.customerId,
            'sale_date': header.saleDate?.toIso8601String(),
            'sale_type': header.saleType,
            'warehouse_id': header.warehouseId,
            'total_amount': header.totalAmount,
            'discount_percent': header.discountPercent,
            'discount_amount': header.discountAmount,
            'tax_percent': header.taxPercent,
            'tax_amount': header.taxAmount,
            'grand_total': header.grandTotal,
            'paid_amount': header.paidAmount,
            'due_amount': header.dueAmount,
            'status': header.status,
            'payment_status': header.paymentStatus,
            'note': header.note,
            'business_id': header.businessId,
            'created_by': header.createdBy,
            'items': [
              for (final item in computedItems)
                {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                  'discount_percent': item.discountPercent,
                  'discount_amount': item.discountAmount,
                  'tax_percent': item.taxPercent,
                  'tax_amount': item.taxAmount,
                  'line_total': item.lineTotal,
                },
            ],
            'payments': [
              for (final p in payments)
                {'amount': p.amount, 'method': p.paymentMethod},
            ],
          },
          businessId: businessId,
        );

        detail = SaleDetail(
          sale: header,
          items: computedItems
              .map((i) => i.copyWith(saleId: header.id))
              .toList(),
          payments: payments,
        );
      });
    }

    try {
      await persistAndDeduct();
    } on InventoryServiceException catch (e) {
      // Map stock failures onto the documented INSUFFICIENT_STOCK contract.
      throw SalesServiceException(e.code, e.message);
    }

    // Accounting auto-posting (Architecture Book §13.5, §14.2): posts the
    // sale journal synchronously so accounting is consistent with the sale.
    await _postAccounting(detail, actorId);

    _audit.logAction(
      userId: actorId,
      entityType: 'sale',
      entityId: detail.sale.id!,
      action: 'create',
      newValue:
          'invoice=${detail.sale.invoiceNumber}; total=${detail.sale.grandTotal}; '
          'paid=${detail.sale.paidAmount}; status=${detail.sale.status}',
      businessId: businessId,
    );

    // Publish AFTER commit (Architecture Book §16.2 transactional safety).
    _events.publish(SaleCompleted(
      saleId: detail.sale.id!,
      invoiceNumber: detail.sale.invoiceNumber!,
      customerId: detail.sale.customerId,
      grandTotal: detail.sale.grandTotal,
      paidAmount: detail.sale.paidAmount,
      dueAmount: detail.sale.dueAmount,
      paymentStatus: detail.sale.paymentStatus,
      saleType: detail.sale.saleType,
      businessId: businessId,
    ));
    return detail;
  }

  /// Edit the header of an editable (Draft/Hold) sale.
  Future<Sale> updateSale({
    required int businessId,
    required int id,
    String? saleType,
    int? warehouseId,
    String? status,
    String? note,
    required int actorId,
  }) async {
    final existing = await _ownedSale(businessId, id);
    if (!_editableStatuses.contains(existing.status)) {
      throw const SalesServiceException(
          'not_editable', 'Only Draft or Hold sales can be updated');
    }
    if (status != null && !_editableStatuses.contains(status)) {
      throw const SalesServiceException(
          'invalid_status', 'Status must remain Draft or Hold');
    }
    final updated = await _saleRepo.update(existing.copyWith(
      saleType: saleType ?? existing.saleType,
      warehouseId: warehouseId ?? existing.warehouseId,
      status: status ?? existing.status,
      note: note ?? existing.note,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'sale',
      entityId: id,
      action: 'update',
      oldValue: 'status=${existing.status}; note=${existing.note}',
      newValue: 'status=${updated.status}; note=${updated.note}',
      businessId: businessId,
    );
    _changeLog?.recordChange(
      entityType: 'sale',
      entityId: id,
      operation: ChangeOperation.update,
      payload: updated.toJson(),
      oldValues: {
        'sale_type': existing.saleType,
        'warehouse_id': existing.warehouseId,
        'status': existing.status,
        'note': existing.note,
      },
      businessId: businessId,
    );
    return updated;
  }

  /// Cancel a sale (soft tombstone: `status = 'Cancelled'`). Returned sales
  /// and completed sales with payments cannot be cancelled.
  Future<void> deleteSale({
    required int businessId,
    required int id,
    required int actorId,
  }) async {
    final existing = await _ownedSale(businessId, id);
    if (existing.status == 'Returned' ||
        (existing.status == 'Completed' && existing.paidAmount > _eps)) {
      throw const SalesServiceException(
          'not_cancellable', 'Returned or paid sales cannot be cancelled');
    }
    await _saleRepo.cancel(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'sale',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
    _changeLog?.recordChange(
      entityType: 'sale',
      entityId: id,
      operation: ChangeOperation.update,
      payload: {'id': id, 'status': 'Cancelled'},
      oldValues: {'status': existing.status},
      businessId: businessId,
    );
  }

  /// Record a return against [saleId]; optionally restock the sold goods
  /// into the original warehouse, refresh payment totals, and mark the sale
  /// `Returned`. Publishes [SaleReturned] after commit.
  Future<SaleReturn> processReturn({
    required int businessId,
    required int saleId,
    DateTime? returnDate,
    String? reason,
    bool restock = false,
    double refundAmount = 0,
    String? refundMethod,
    required int actorId,
  }) async {
    final sale = await _ownedSale(businessId, saleId);
    if (sale.status == 'Cancelled') {
      throw const SalesServiceException(
          'invalid_state', 'A cancelled sale cannot be returned');
    }
    if (sale.status == 'Returned') {
      throw const SalesServiceException(
          'already_returned', 'This sale has already been returned');
    }
    if (refundAmount < 0) {
      throw const SalesServiceException(
          'invalid_refund', 'Refund amount cannot be negative');
    }

    late SaleReturn created;
    try {
      await _inventoryService.runInTransaction(() async {
        created = await _persistReturn(
            sale, returnDate, reason, restock, refundAmount, refundMethod);
        if (restock) {
          final items = await _itemsOf(saleId);
          for (final item in items) {
            await _inventoryService.addStock(
              businessId: businessId,
              productId: item.productId,
              warehouseId: sale.warehouseId!,
              quantity: item.quantity,
              purchasePrice: item.unitPrice,
              referenceType: 'sales_return',
              referenceId: created.id,
              note: reason ?? 'Sales return restock',
              actorId: actorId,
            );
          }
        }
      });
    } on InventoryServiceException catch (e) {
      throw SalesServiceException(e.code, e.message);
    }

    _audit.logAction(
      userId: actorId,
      entityType: 'sales_return',
      entityId: created.id!,
      action: 'create',
      newValue:
          'sale=$saleId; refund=${created.refundAmount}; restock=$restock',
      businessId: businessId,
    );

    _events.publish(SaleReturned(
      returnId: created.id!,
      originalSaleId: saleId,
      totalCredit: created.refundAmount,
      restock: restock,
      businessId: businessId,
    ));
    return created;
  }

  // -- Internals ---------------------------------------------------------------

  Future<Sale> _ownedSale(int businessId, int id) async {
    final sale = await _saleRepo.findById(id);
    if (sale == null || sale.businessId != businessId) {
      throw const SalesServiceException('not_found', 'Sale not found');
    }
    return sale;
  }

  Future<List<SaleItem>> _itemsOf(int saleId) async =>
      (await _saleRepo.getDetail(saleId))?.items ?? const [];

  Future<SaleReturn> _persistReturn(
    Sale sale,
    DateTime? returnDate,
    String? reason,
    bool restock,
    double refundAmount,
    String? refundMethod,
  ) async {
    final created = await _returnRepo.insert(SaleReturn(
      saleId: sale.id!,
      returnDate: returnDate ?? DateTime.now(),
      reason: reason,
      restock: restock,
      refundAmount: refundAmount,
      refundMethod: refundMethod,
    ));
    await _saleRepo.update(sale.copyWith(status: 'Returned'));
    await _saleRepo.refreshPaymentTotals(sale.id!);
    _changeLog?.recordChange(
      entityType: 'sales_return',
      entityId: created.id!,
      operation: ChangeOperation.insert,
      payload: {
        'id': created.id,
        'sale_id': created.saleId,
        'return_date': created.returnDate?.toIso8601String(),
        'reason': created.reason,
        'restock': created.restock,
        'refund_amount': created.refundAmount,
        'refund_method': created.refundMethod,
      },
      businessId: sale.businessId,
    );
    _changeLog?.recordChange(
      entityType: 'sale',
      entityId: sale.id!,
      operation: ChangeOperation.update,
      payload: {'id': sale.id, 'status': 'Returned'},
      oldValues: {'status': sale.status},
      businessId: sale.businessId,
    );
    return created;
  }

  /// Accounting auto-posting (Architecture Book §13.5, §14.2):
  /// `createSale → inventory → accounting → event`.
  ///
  /// Posts a posted journal for a Completed sale:
  ///   DR Cash/AR (paid) + DR AR (due)  →  CR Revenue (subtotal) + CR Tax
  /// Silently skips when chart-of-accounts rows for the business cannot be
  /// resolved (Accounting module not yet seeded for this business) or when
  /// the journal service was not injected.
  Future<void> _postAccounting(SaleDetail detail, int actorId) async {
    final journalService = _journalService;
    final lookup = _accountLookup;
    final sale = detail.sale;
    if (journalService == null || lookup == null) return;
    if (sale.status != 'Completed') return;

    final revenue = await lookup(sale.businessId, 'Revenue');
    final cash = await lookup(sale.businessId, 'Cash');
    final receivable = await lookup(sale.businessId, 'Accounts Receivable');
    final taxPayable = sale.taxAmount > _eps
        ? await lookup(sale.businessId, 'Tax Payable')
        : 0;

    // Need at least the revenue and a debit target to build a valid journal.
    if (revenue == 0 || (cash == 0 && receivable == 0)) return;

    final subtotal = sale.grandTotal - sale.taxAmount;
    final paid = sale.paidAmount;
    final due = sale.dueAmount;
    final debitTarget = cash != 0 ? cash : receivable;

    final lines = <JournalLine>[
      if (paid > _eps)
        JournalLine(
          accountId: debitTarget,
          debit: paid,
          description: 'Payment received on ${sale.invoiceNumber}',
        ),
      if (due > _eps && receivable != 0 && receivable != debitTarget)
        JournalLine(
          accountId: receivable,
          debit: due,
          description: 'Amount due on ${sale.invoiceNumber}',
        )
      else if (due > _eps)
        JournalLine(
          accountId: debitTarget,
          debit: due,
          description: 'Amount due on ${sale.invoiceNumber}',
        ),
      JournalLine(
        accountId: revenue,
        credit: subtotal,
        description: 'Sale ${sale.invoiceNumber}',
      ),
      if (sale.taxAmount > _eps && taxPayable != 0)
        JournalLine(
          accountId: taxPayable,
          credit: sale.taxAmount,
          description: 'Tax on ${sale.invoiceNumber}',
        ),
    ];
    if (lines.length < 2) return;

    await journalService.createAndPost(
      businessId: sale.businessId,
      entryDate: sale.saleDate ?? DateTime.now(),
      reference: sale.invoiceNumber,
      note: 'Auto-posted from sale #${sale.id}',
      lines: lines,
      actorId: actorId,
    );
  }
}
