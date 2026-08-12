import 'domain_event.dart';

/// Cross-module domain event catalogue (Event Catalog §3).
///
/// Module-scoped variants (`sales/domain/events/sales_events.dart`,
/// `purchases/domain/events/purchase_events.dart`,
/// `accounting/domain/events/accounting_events.dart`) already define
/// [SaleCompleted], [SaleReturned], [PurchaseCompleted] and [JournalPosted]
/// with their full payloads; this file adds the remaining catalog events
/// that have no natural single-module home so that any subscriber only needs
/// ONE import for the complete event vocabulary.
///
/// Every event extends [DomainEvent] and therefore carries `eventId`,
/// `timestamp` and `businessId`.

/// Fired when an additional payment (due collection) is recorded against an
/// existing sale (Event Catalog §3.1).
class PaymentReceived extends DomainEvent {
  PaymentReceived({
    required this.saleId,
    this.paymentId,
    required this.amount,
    required this.method,
    required super.businessId,
  });

  final int saleId;
  final int? paymentId;
  final double amount;
  final String method;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'saleId': saleId,
        'paymentId': paymentId,
        'amount': amount,
        'method': method,
      };
}

/// Fired when stock for a product/warehouse drops to or below its configured
/// minimum threshold (Event Catalog §3.3). Local alert only – no sync event.
class StockLow extends DomainEvent {
  StockLow({
    required this.productId,
    required this.warehouseId,
    required this.currentQuantity,
    required this.threshold,
    required super.businessId,
  });

  final int productId;
  final int warehouseId;
  final double currentQuantity;
  final double threshold;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'productId': productId,
        'warehouseId': warehouseId,
        'currentQuantity': currentQuantity,
        'threshold': threshold,
      };
}

/// Fired by the scheduled expiry checker when a batch is within its warning
/// window (Event Catalog §3.3). Local alert only – no sync event.
class BatchExpiring extends DomainEvent {
  BatchExpiring({
    required this.batchId,
    required this.productId,
    this.productName,
    this.batchNumber,
    this.expiryDate,
    required this.daysLeft,
    this.currentQuantity,
    required super.businessId,
  });

  final int batchId;
  final int productId;
  final String? productName;
  final String? batchNumber;
  final DateTime? expiryDate;
  final int daysLeft;
  final double? currentQuantity;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'batchId': batchId,
        'productId': productId,
        'productName': productName,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate?.toIso8601String(),
        'daysLeft': daysLeft,
        'currentQuantity': currentQuantity,
      };
}

/// Fired after a manual stock adjustment is approved and applied
/// (Event Catalog §3.3).
class StockAdjusted extends DomainEvent {
  StockAdjusted({
    required this.adjustmentId,
    required this.warehouseId,
    this.reason,
    this.totalDifference = 0,
    required super.businessId,
  });

  final int adjustmentId;
  final int warehouseId;
  final String? reason;
  final double totalDifference;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'adjustmentId': adjustmentId,
        'warehouseId': warehouseId,
        'reason': reason,
        'totalDifference': totalDifference,
      };
}

/// Fired when a student is enrolled into a batch (Event Catalog §3.5).
class StudentEnrolled extends DomainEvent {
  StudentEnrolled({
    required this.enrollmentId,
    required this.studentId,
    required this.batchId,
    this.studentName,
    this.batchName,
    required super.businessId,
  });

  final int enrollmentId;
  final int studentId;
  final int batchId;
  final String? studentName;
  final String? batchName;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'enrollmentId': enrollmentId,
        'studentId': studentId,
        'batchId': batchId,
        'studentName': studentName,
        'batchName': batchName,
      };
}

/// Fired when a student pays a fee installment (Event Catalog §3.5).
class FeeInstallmentPaid extends DomainEvent {
  FeeInstallmentPaid({
    required this.studentId,
    required this.enrollmentId,
    this.saleId,
    required this.amountPaid,
    required this.remainingDue,
    required super.businessId,
  });

  final int studentId;
  final int enrollmentId;
  final int? saleId;
  final double amountPaid;
  final double remainingDue;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'studentId': studentId,
        'enrollmentId': enrollmentId,
        'saleId': saleId,
        'amountPaid': amountPaid,
        'remainingDue': remainingDue,
      };
}

/// Fired when student attendance is recorded (Event Catalog §3.5).
class AttendanceMarked extends DomainEvent {
  AttendanceMarked({
    required this.enrollmentId,
    required this.date,
    required this.status,
    required super.businessId,
  });

  final int enrollmentId;
  final DateTime date;
  final String status;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'enrollmentId': enrollmentId,
        'date': date.toIso8601String(),
        'status': status,
      };
}

/// Fired when an accounting period is closed (Event Catalog §3.4). Owner-only.
class PeriodClosed extends DomainEvent {
  PeriodClosed({
    required this.periodStart,
    required this.periodEnd,
    required super.businessId,
  });

  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };
}

/// Fired when a payment is recorded to a supplier (Event Catalog §3.2).
class SupplierPaymentMade extends DomainEvent {
  SupplierPaymentMade({
    required this.paymentId,
    this.supplierId,
    this.purchaseId,
    required this.amount,
    required this.method,
    required super.businessId,
  });

  final int paymentId;
  final int? supplierId;
  final int? purchaseId;
  final double amount;
  final String method;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'paymentId': paymentId,
        'supplierId': supplierId,
        'purchaseId': purchaseId,
        'amount': amount,
        'method': method,
      };
}
