import '../../../../core/events/domain_event.dart';

/// Fired after a sale invoice is committed (Event Catalog – `SaleCompleted`).
class SaleCompleted extends DomainEvent {
  SaleCompleted({
    required this.saleId,
    required this.invoiceNumber,
    this.customerId,
    required this.grandTotal,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    required this.saleType,
    required super.businessId,
  });

  final int saleId;
  final String invoiceNumber;
  final int? customerId;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final String saleType;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'saleId': saleId,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'grandTotal': grandTotal,
        'paidAmount': paidAmount,
        'dueAmount': dueAmount,
        'paymentStatus': paymentStatus,
        'saleType': saleType,
      };
}

/// Fired when a sales return is processed (Event Catalog – `SaleReturned`).
class SaleReturned extends DomainEvent {
  SaleReturned({
    required this.returnId,
    required this.originalSaleId,
    required this.totalCredit,
    required this.restock,
    required super.businessId,
  });

  final int returnId;
  final int originalSaleId;
  final double totalCredit;
  final bool restock;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'returnId': returnId,
        'originalSaleId': originalSaleId,
        'totalCredit': totalCredit,
        'restock': restock,
      };
}
