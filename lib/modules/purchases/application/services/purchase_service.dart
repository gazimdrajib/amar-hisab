import '../../../../core/events/domain_event.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/change_log_service.dart';
import '../../../accounting/application/services/journal_service.dart';
import '../../../accounting/domain/entities/journal_line.dart';
import '../../../inventory/application/services/inventory_service.dart';
import '../../../inventory/application/services/warehouse_service.dart'
    show InventoryServiceException;
import '../../domain/entities/purchase.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/events/purchase_events.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Error raised by [PurchaseService]; carries a machine-readable [code] the
/// controller maps to an HTTP status.
class PurchaseServiceException implements Exception {
  const PurchaseServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PurchaseServiceException($code): $message';
}

/// Orchestrates the purchase workflow (Architecture Book §14.2 mirrored for
/// procurement):
///
///  * [createPurchase] – validates items, computes totals, persists the
///    purchase header/items/payments, adds received stock to batches
///    (driving the FIFO costing basis), then publishes [PurchaseCompleted]
///    **after commit** (Event Catalog §3.2).
///  * [getPurchase] / [listPurchases] / [updatePurchase] / [deletePurchase] –
///    queries and lifecycle mutations guarded by RBAC at the controller layer.
class PurchaseService {
  PurchaseService(
    this._purchaseRepo,
    this._inventoryService,
    this._audit,
    this._events, {
    JournalService? journalService,
    AccountLookup? accountLookup,
    ChangeLogService? changeLog,
  })  : _journalService = journalService,
        _accountLookup = accountLookup,
        _changeLog = changeLog;

  final PurchaseRepository _purchaseRepo;
  final InventoryService _inventoryService;
  final AuditService _audit;
  final EventBus _events;
  final JournalService? _journalService;
  final AccountLookup? _accountLookup;
  final ChangeLogService? _changeLog;

  static const double _eps = 0.0001;

  /// Purchase statuses that may still be edited via [updatePurchase].
  static const _editableStatuses = {'Draft', 'Ordered'};

  // -- Queries ---------------------------------------------------------------

  Future<PurchaseDetail?> getPurchase(int businessId, int id) async {
    final detail = await _purchaseRepo.getDetail(id);
    if (detail == null || detail.purchase.businessId != businessId) return null;
    return detail;
  }

  Future<List<Purchase>> listPurchases(
    int businessId, {
    int? supplierId,
    String? status,
    String? paymentStatus,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) =>
      _purchaseRepo.list(
        businessId,
        supplierId: supplierId,
        status: status,
        paymentStatus: paymentStatus,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );

  // -- Commands ---------------------------------------------------------------

  /// Create a purchase invoice. When [status] is `Received`, the whole
  /// workflow (header + items + payments + stock receipt into batches) runs
  /// inside ONE SQLite transaction so a partial write can never persist; the
  /// [PurchaseCompleted] domain event is published only after COMMIT.
  Future<PurchaseDetail> createPurchase({
    required int businessId,
    int? supplierId,
    required int warehouseId,
    DateTime? purchaseDate,
    double discountPercent = 0,
    double taxPercent = 0,
    String? note,
    required List<PurchaseItem> items,
    List<SupplierPayment> payments = const [],
    required int actorId,
    String status = 'Received',
  }) async {
    if (items.isEmpty) {
      throw const PurchaseServiceException(
          'empty_purchase', 'A purchase must contain at least one item');
    }
    for (final item in items) {
      if (item.quantity <= 0) {
        throw const PurchaseServiceException(
            'invalid_item', 'Item quantity must be greater than zero');
      }
      if (item.unitPrice < 0) {
        throw const PurchaseServiceException(
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
      throw const PurchaseServiceException(
          'overpayment', 'Payments exceed the grand total');
    }
    final dueAmount = grandTotal - paidAmount;
    final paymentStatus =
        dueAmount <= _eps ? 'Paid' : (paidAmount <= _eps ? 'Due' : 'Partial');

    final invoiceNumber =
        'PUR-${DateTime.now().year}-${DateTime.now().microsecondsSinceEpoch}';
    final effectiveDate = purchaseDate ?? DateTime.now();
    late PurchaseDetail detail;

    Future<void> persistAndReceive() {
      return _inventoryService.runInTransaction(() async {
        final header = await _purchaseRepo.insert(
          Purchase(
            invoiceNumber: invoiceNumber,
            supplierId: supplierId,
            purchaseDate: effectiveDate,
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

        // Receive stock only for received purchases (Draft/Ordered hold no stock).
        if (status == 'Received') {
          for (final item in computedItems) {
            await _inventoryService.addStock(
              businessId: businessId,
              productId: item.productId,
              warehouseId: warehouseId,
              quantity: item.quantity,
              purchasePrice: item.unitPrice,
              referenceType: 'purchase',
              referenceId: header.id,
              note: 'Purchase ${header.invoiceNumber}',
              actorId: actorId,
            );
          }
        }
        detail = PurchaseDetail(
          purchase: header,
          items: computedItems
              .map((i) => i.copyWith(purchaseId: header.id))
              .toList(),
          payments: payments,
        );

        // Transactional outbox (Event Catalog §4.2): purchase + items +
        // payments snapshot, inside the same transaction.
        _changeLog?.recordChange(
          entityType: 'purchase',
          entityId: header.id!,
          operation: ChangeOperation.insert,
          payload: {
            'id': header.id,
            'invoice_number': header.invoiceNumber,
            'supplier_id': header.supplierId,
            'purchase_date': header.purchaseDate?.toIso8601String(),
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
      });
    }

    try {
      await persistAndReceive();
    } on InventoryServiceException catch (e) {
      throw PurchaseServiceException(e.code, e.message);
    }

    // Accounting auto-posting (Architecture Book §13.5, §14.2):
    // createPurchase → inventory → accounting → event.
    await _postAccounting(detail, actorId);

    _audit.logAction(
      userId: actorId,
      entityType: 'purchase',
      entityId: detail.purchase.id!,
      action: 'create',
      newValue:
          'invoice=${detail.purchase.invoiceNumber}; total=${detail.purchase.grandTotal}; '
          'paid=${detail.purchase.paidAmount}; status=${detail.purchase.status}',
      businessId: businessId,
    );

    // Publish AFTER commit (Architecture Book §16.2 transactional safety).
    _events.publish(PurchaseCompleted(
      purchaseId: detail.purchase.id!,
      invoiceNumber: detail.purchase.invoiceNumber!,
      supplierId: detail.purchase.supplierId,
      grandTotal: detail.purchase.grandTotal,
      paidAmount: detail.purchase.paidAmount,
      dueAmount: detail.purchase.dueAmount,
      paymentStatus: detail.purchase.paymentStatus,
      businessId: businessId,
    ));
    return detail;
  }

  /// Edit the header of an editable (Draft/Ordered) purchase.
  Future<Purchase> updatePurchase({
    required int businessId,
    required int id,
    int? supplierId,
    int? warehouseId,
    String? status,
    String? note,
    required int actorId,
  }) async {
    final existing = await _ownedPurchase(businessId, id);
    if (!_editableStatuses.contains(existing.status)) {
      throw const PurchaseServiceException(
          'not_editable', 'Only Draft or Ordered purchases can be updated');
    }
    if (status != null && !_editableStatuses.contains(status)) {
      throw const PurchaseServiceException(
          'invalid_status', 'Status must remain Draft or Ordered');
    }
    final updated = await _purchaseRepo.update(existing.copyWith(
      supplierId: supplierId ?? existing.supplierId,
      warehouseId: warehouseId ?? existing.warehouseId,
      status: status ?? existing.status,
      note: note ?? existing.note,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'purchase',
      entityId: id,
      action: 'update',
      oldValue: 'status=${existing.status}; note=${existing.note}',
      newValue: 'status=${updated.status}; note=${updated.note}',
      businessId: businessId,
    );
    _changeLog?.recordChange(
      entityType: 'purchase',
      entityId: id,
      operation: ChangeOperation.update,
      payload: updated.toJson(),
      oldValues: {
        'supplier_id': existing.supplierId,
        'warehouse_id': existing.warehouseId,
        'status': existing.status,
        'note': existing.note,
      },
      businessId: businessId,
    );
    return updated;
  }

  /// Cancel a purchase (soft tombstone: `status = 'Cancelled'`). Received
  /// purchases with payments cannot be cancelled.
  Future<void> deletePurchase({
    required int businessId,
    required int id,
    required int actorId,
  }) async {
    final existing = await _ownedPurchase(businessId, id);
    if (existing.status == 'Received' && existing.paidAmount > _eps) {
      throw const PurchaseServiceException(
          'not_cancellable', 'Paid purchases cannot be cancelled');
    }
    await _purchaseRepo.cancel(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'purchase',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
    _changeLog?.recordChange(
      entityType: 'purchase',
      entityId: id,
      operation: ChangeOperation.update,
      payload: {'id': id, 'status': 'Cancelled'},
      oldValues: {'status': existing.status},
      businessId: businessId,
    );
  }

  // -- Internals ---------------------------------------------------------------

  Future<Purchase> _ownedPurchase(int businessId, int id) async {
    final purchase = await _purchaseRepo.findById(id);
    if (purchase == null || purchase.businessId != businessId) {
      throw const PurchaseServiceException('not_found', 'Purchase not found');
    }
    return purchase;
  }

  /// Accounting auto-posting (Architecture Book §13.5, §14.2):
  /// `createPurchase → inventory → accounting → event`.
  ///
  /// Posts a posted journal for a Received purchase:
  ///   DR Inventory (subtotal) + DR Tax Paid (tax)  →  CR Cash (paid) + CR AP (due)
  /// Silently skips when chart-of-accounts rows for the business cannot be
  /// resolved or when the journal service was not injected.
  Future<void> _postAccounting(PurchaseDetail detail, int actorId) async {
    final journalService = _journalService;
    final lookup = _accountLookup;
    final purchase = detail.purchase;
    if (journalService == null || lookup == null) return;
    if (purchase.status != 'Received') return;

    final inventory = await lookup(purchase.businessId, 'Inventory');
    final cash = await lookup(purchase.businessId, 'Cash');
    final payable = await lookup(purchase.businessId, 'Accounts Payable');
    final taxPaid = purchase.taxAmount > _eps
        ? await lookup(purchase.businessId, 'Tax Paid')
        : 0;

    if (inventory == 0 || (cash == 0 && payable == 0)) return;

    final subtotal = purchase.grandTotal - purchase.taxAmount;
    final paid = purchase.paidAmount;
    final due = purchase.dueAmount;
    final creditTarget = cash != 0 ? cash : payable;

    final lines = <JournalLine>[
      JournalLine(
        accountId: inventory,
        debit: subtotal,
        description: 'Purchase ${purchase.invoiceNumber}',
      ),
      if (purchase.taxAmount > _eps && taxPaid != 0)
        JournalLine(
          accountId: taxPaid,
          debit: purchase.taxAmount,
          description: 'Tax on ${purchase.invoiceNumber}',
        ),
      if (paid > _eps)
        JournalLine(
          accountId: creditTarget,
          credit: paid,
          description: 'Payment on ${purchase.invoiceNumber}',
        ),
      if (due > _eps && payable != 0 && payable != creditTarget)
        JournalLine(
          accountId: payable,
          credit: due,
          description: 'Amount due on ${purchase.invoiceNumber}',
        )
      else if (due > _eps)
        JournalLine(
          accountId: creditTarget,
          credit: due,
          description: 'Amount due on ${purchase.invoiceNumber}',
        ),
    ];
    if (lines.length < 2) return;

    await journalService.createAndPost(
      businessId: purchase.businessId,
      entryDate: purchase.purchaseDate ?? DateTime.now(),
      reference: purchase.invoiceNumber,
      note: 'Auto-posted from purchase #${purchase.id}',
      lines: lines,
      actorId: actorId,
    );
  }
}
