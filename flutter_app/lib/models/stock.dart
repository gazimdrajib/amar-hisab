/// Warehouse and stock-related models (camelCase per backend).
class Warehouse {
  final int id;
  final int businessId;
  final String name;
  final String? location;
  final bool isActive;

  const Warehouse({
    required this.id,
    this.businessId = 0,
    required this.name,
    this.location,
    this.isActive = true,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
        id: (json['id'] as num).toInt(),
        businessId: (json['businessId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        location: json['location']?.toString(),
        isActive: json['isActive'] == true || json['isActive'] == 1,
      );
}

class StockEntry {
  final int id;
  final int businessId;
  final int productId;
  final int warehouseId;
  final double quantity;
  final DateTime? updatedAt;

  const StockEntry({
    required this.id,
    this.businessId = 0,
    required this.productId,
    required this.warehouseId,
    this.quantity = 0,
    this.updatedAt,
  });

  factory StockEntry.fromJson(Map<String, dynamic> json) => StockEntry(
        id: (json['id'] as num).toInt(),
        businessId: (json['businessId'] as num?)?.toInt() ?? 0,
        productId: (json['productId'] as num).toInt(),
        warehouseId: (json['warehouseId'] as num).toInt(),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );
}

class StockMovement {
  final int id;
  final int productId;
  final int warehouseId;
  final String movementType;
  final double quantity;
  final String? referenceType;
  final String? note;
  final DateTime? createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.warehouseId,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.note,
    this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: (json['id'] as num).toInt(),
        productId: (json['productId'] as num?)?.toInt() ?? 0,
        warehouseId: (json['warehouseId'] as num?)?.toInt() ?? 0,
        movementType: json['movementType']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        referenceType: json['referenceType']?.toString(),
        note: json['note']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

/// One row of the inventory report (snake_case keys from the report service).
class InventoryReportRow {
  final String sku;
  final String product;
  final String warehouse;
  final double quantity;
  final double sellingPrice;
  final double purchasePrice;
  final double stockValue;
  final bool isLowStock;

  const InventoryReportRow({
    required this.sku,
    required this.product,
    required this.warehouse,
    required this.quantity,
    this.sellingPrice = 0,
    this.purchasePrice = 0,
    this.stockValue = 0,
    this.isLowStock = false,
  });

  factory InventoryReportRow.fromJson(Map<String, dynamic> json) =>
      InventoryReportRow(
        sku: json['sku']?.toString() ?? '',
        product: json['product']?.toString() ?? '',
        warehouse: json['warehouse']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
        purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
        stockValue: (json['stock_value'] as num?)?.toDouble() ?? 0,
        isLowStock: json['low_stock']?.toString().toLowerCase() == 'yes',
      );
}
