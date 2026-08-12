import '../../../../core/events/domain_event.dart';

/// Fired after a purchase invoice is committed
/// (Event Catalog §3.2 – `PurchaseCompleted`).
class PurchaseCompleted extends DomainEvent {
  PurchaseCompleted({
    required this.purchaseId,
    required this.invoiceNumber,
    this.supplierId,
    required this.grandTotal,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    required super.businessId,
  });

  final int purchaseId;
  final String invoiceNumber;
  final int? supplierId;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'purchaseId': purchaseId,
        'invoiceNumber': invoiceNumber,
        'supplierId': supplierId,
        'grandTotal': grandTotal,
        'paidAmount': paidAmount,
        'dueAmount': dueAmount,
        'paymentStatus': paymentStatus,
      };
}
