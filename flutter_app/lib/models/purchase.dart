/// Purchase header — mirrors backend Purchase JSON (camelCase).
class Purchase {
  final int id;
  final String invoiceNumber;
  final int? supplierId;
  final DateTime purchaseDate;
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
  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.invoiceNumber,
    this.supplierId,
    required this.purchaseDate,
    required this.warehouseId,
    this.totalAmount = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    this.grandTotal = 0,
    this.paidAmount = 0,
    this.dueAmount = 0,
    this.status = 'Received',
    this.paymentStatus = 'Due',
    this.note,
    this.businessId = 0,
    this.items = const [],
  });

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: (json['id'] as num).toInt(),
        invoiceNumber: json['invoiceNumber']?.toString() ?? '',
        supplierId: (json['supplierId'] as num?)?.toInt(),
        purchaseDate:
            DateTime.tryParse(json['purchaseDate']?.toString() ?? '') ??
                DateTime.now(),
        warehouseId: (json['warehouseId'] as num?)?.toInt() ?? 0,
        totalAmount: _d(json['totalAmount']),
        discountPercent: _d(json['discountPercent']),
        discountAmount: _d(json['discountAmount']),
        taxPercent: _d(json['taxPercent']),
        taxAmount: _d(json['taxAmount']),
        grandTotal: _d(json['grandTotal']),
        paidAmount: _d(json['paidAmount']),
        dueAmount: _d(json['dueAmount']),
        status: json['status']?.toString() ?? 'Received',
        paymentStatus: json['paymentStatus']?.toString() ?? 'Due',
        note: json['note']?.toString(),
        businessId: (json['businessId'] as num?)?.toInt() ?? 0,
        items: (json['items'] as List?)
                ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'supplierId': supplierId,
        'purchaseDate': purchaseDate.toIso8601String(),
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
      };
}

class PurchaseItem {
  final int? id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const PurchaseItem({
    this.id,
    required this.productId,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
        id: (json['id'] as num?)?.toInt(),
        productId: (json['productId'] as num).toInt(),
        quantity: _d(json['quantity']),
        unitPrice: _d(json['unitPrice']),
        lineTotal: _d(json['lineTotal']),
      );
}
