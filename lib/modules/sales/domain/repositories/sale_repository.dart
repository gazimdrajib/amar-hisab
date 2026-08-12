import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_payment.dart';

/// Composite detail of a sale: header + line items + payments.
class SaleDetail {
  const SaleDetail({
    required this.sale,
    this.items = const [],
    this.payments = const [],
  });

  final Sale sale;
  final List<SaleItem> items;
  final List<SalePayment> payments;

  Map<String, dynamic> toJson() => {
        ...sale.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };
}

abstract class SaleRepository {
  /// Insert header + items + payments; returns the id-filled header.
  /// Caller manages the surrounding transaction.
  Future<Sale> insert(Sale sale, List<SaleItem> items,
      List<SalePayment> payments);

  Future<Sale?> findById(int id);
  Future<SaleDetail?> getDetail(int id);

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
  });

  /// Mutable draft/hold fields + note.
  Future<Sale> update(Sale sale);

  /// Soft-cancel: sets `status = 'Cancelled'`.
  Future<void> cancel(int id);

  /// Recompute paid/due/payment_status from the payments ledger.
  Future<Sale> refreshPaymentTotals(int saleId);

  /// Append one due-collection payment for an existing sale.
  /// Caller manages the surrounding transaction (transactional outbox).
  Future<SalePayment> insertPayment(SalePayment payment);
}
