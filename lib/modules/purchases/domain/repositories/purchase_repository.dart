import '../entities/purchase.dart';
import '../entities/purchase_item.dart';
import '../entities/supplier_payment.dart';

/// Composite detail of a purchase: header + line items + payments.
class PurchaseDetail {
  const PurchaseDetail({
    required this.purchase,
    this.items = const [],
    this.payments = const [],
  });

  final Purchase purchase;
  final List<PurchaseItem> items;
  final List<SupplierPayment> payments;

  Map<String, dynamic> toJson() => {
        ...purchase.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };
}

abstract class PurchaseRepository {
  /// Insert header + items + payments; returns the id-filled header.
  /// Caller manages the surrounding transaction.
  Future<Purchase> insert(Purchase purchase, List<PurchaseItem> items,
      List<SupplierPayment> payments);

  Future<Purchase?> findById(int id);
  Future<PurchaseDetail?> getDetail(int id);

  Future<List<Purchase>> list(
    int businessId, {
    int? supplierId,
    String? status,
    String? paymentStatus,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  });

  /// Mutable draft fields + note.
  Future<Purchase> update(Purchase purchase);

  /// Soft-cancel: sets `status = 'Cancelled'`.
  Future<void> cancel(int id);

  /// Recompute paid/due/payment_status from the supplier payments ledger.
  Future<Purchase> refreshPaymentTotals(int purchaseId);
}
