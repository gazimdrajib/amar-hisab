/// Product entity — matches the backend freezed Product (camelCase keys).
class Product {
  final int id;
  final int businessId;
  final String sku;
  final String? barcode;
  final String name;
  final String? description;
  final int? categoryId;
  final int? brandId;
  final int? unitId;
  final double purchasePrice;
  final double sellingPrice;
  final double taxRate;
  final double minStockLevel;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    this.businessId = 0,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    this.categoryId,
    this.brandId,
    this.unitId,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.taxRate = 0,
    this.minStockLevel = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
  static int? _i(dynamic v) => v == null ? null : (v as num).toInt();
  static bool _b(dynamic v) => v == true || v == 1;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num).toInt(),
        businessId: (json['businessId'] as num?)?.toInt() ?? 0,
        sku: json['sku']?.toString() ?? '',
        barcode: json['barcode']?.toString(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        categoryId: _i(json['categoryId']),
        brandId: _i(json['brandId']),
        unitId: _i(json['unitId']),
        purchasePrice: _d(json['purchasePrice']),
        sellingPrice: _d(json['sellingPrice']),
        taxRate: _d(json['taxRate']),
        minStockLevel: _d(json['minStockLevel']),
        isActive: _b(json['isActive'] ?? true),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'sku': sku,
        'barcode': barcode,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'brandId': brandId,
        'unitId': unitId,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'taxRate': taxRate,
        'minStockLevel': minStockLevel,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // Request bodies for create/update (no read-only fields).
  Map<String, dynamic> toPayload() => {
        'sku': sku,
        'name': name,
        if (barcode != null) 'barcode': barcode,
        if (description != null) 'description': description,
        if (categoryId != null) 'categoryId': categoryId,
        if (brandId != null) 'brandId': brandId,
        if (unitId != null) 'unitId': unitId,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'taxRate': taxRate,
        'minStockLevel': minStockLevel,
      };
}

class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        parentId: (json['parentId'] as num?)?.toInt(),
        isActive: json['isActive'] == true || json['isActive'] == 1,
      );
}

class Brand {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  const Brand({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isActive: json['isActive'] == true || json['isActive'] == 1,
      );
}

class Unit {
  final int id;
  final String name;
  final String abbreviation;
  final bool isActive;

  const Unit({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.isActive = true,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        abbreviation: json['abbreviation']?.toString() ?? '',
        isActive: json['isActive'] == true || json['isActive'] == 1,
      );
}
