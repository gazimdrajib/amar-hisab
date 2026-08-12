/// Sale header — matches backend camelCase Sale JSON.
class Sale {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final DateTime saleDate;
  final String saleType;
  final int warehouseId;
  final double totalAmount;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final String paymentStatus;
  final String? note;
  final int businessId;
  final int? createdBy;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.saleDate,
    this.saleType = 'POS',
    required this.warehouseId,
    this.totalAmount = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.grandTotal = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.status = 'Completed',
    this.paymentStatus = 'Due',
    this.note,
    this.businessId = 0,
    this.createdBy,
  });

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: (json['id'] as num).toInt(),
        invoiceNumber: json['invoiceNumber']?.toString() ?? '',
        customerId: (json['customerId'] as num?)?.toInt(),
        saleDate:
            DateTime.tryParse(json['saleDate']?.toString() ?? '') ?? DateTime.now(),
        saleType: json['saleType']?.toString() ?? 'POS',
        warehouseId: (json['warehouseId'] as num?)?.toInt() ?? 0,
        totalAmount: _d(json['totalAmount']),
        discountPercent: _d(json['discountPercent']),
        discountAmount: _d(json['discountAmount']),
        taxPercent: _d(json['taxPercent']),
        taxAmount: _d(json['taxAmount']),
        grandTotal: _d(json['grandTotal']),
        paidAmount: _d(json['paidAmount']),
        dueAmount: _d(json['dueAmount']),
        status: json['status']?.toString() ?? 'Completed',
        paymentStatus: json['paymentStatus']?.toString() ?? 'Due',
        note: json['note']?.toString(),
        businessId: (json['businessId'] as num?)?.toInt() ?? 0,
        createdBy: (json['createdBy'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'saleDate': saleDate.toIso8601String(),
        'saleType': saleType,
        'warehouseId': warehouseId,
        'totalAmount': totalAmount,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'taxPercent': taxPercent,
        'taxAmount': taxAmount,
        'grandTotal': grandTotal,
        'paidAmount': paidAmount,
        'dueAmount': dueAmount,
        'status': status,
        'paymentStatus': paymentStatus,
        'note': note,
        'businessId': businessId,
        'createdBy': createdBy,
      };
}

class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double lineTotal;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    this.quantity = 1,
    this.unitPrice = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.lineTotal = 0,
  });

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        id: (json['id'] as num?)?.toInt(),
        saleId: (json['saleId'] as num?)?.toInt(),
        productId: (json['productId'] as num).toInt(),
        quantity: _d(json['quantity']),
        unitPrice: _d(json['unitPrice']),
        discountPercent: _d(json['discountPercent']),
        discountAmount: _d(json['discountAmount']),
        taxPercent: _d(json['taxPercent']),
        taxAmount: _d(json['taxAmount']),
        lineTotal: _d(json['lineTotal']),
      );
}

class SalePayment {
  final int? id;
  final double amount;
  final String paymentMethod;
  final String? reference;
  final DateTime? paymentDate;

  const SalePayment({
    this.id,
    required this.amount,
    this.paymentMethod = 'Cash',
    this.reference,
    this.paymentDate,
  });

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
        id: (json['id'] as num?)?.toInt(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
        reference: json['reference']?.toString(),
        paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? ''),
      );
}

/// Full sale with line items + payments — response of GET /sales/<id>.
class SaleDetail extends Sale {
  final List<SaleItem> items;
  final List<SalePayment> payments;

  SaleDetail({
    required Sale sale,
    required this.items,
    required this.payments,
  }) : super(
          id: sale.id,
          invoiceNumber: sale.invoiceNumber,
          customerId: sale.customerId,
          saleDate: sale.saleDate,
          saleType: sale.saleType,
          warehouseId: sale.warehouseId,
          totalAmount: sale.totalAmount,
          discountPercent: sale.discountPercent,
          discountAmount: sale.discountAmount,
          taxPercent: sale.taxPercent,
          taxAmount: sale.taxAmount,
          grandTotal: sale.grandTotal,
          paidAmount: sale.paidAmount,
          dueAmount: sale.dueAmount,
          status: sale.status,
          paymentStatus: sale.paymentStatus,
          note: sale.note,
          businessId: sale.businessId,
          createdBy: sale.createdBy,
        );

  factory SaleDetail.fromJson(Map<String, dynamic> json) => SaleDetail(
        sale: Sale.fromJson(json),
        items: (json['items'] as List?)
                ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        payments: (json['payments'] as List?)
                ?.map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
