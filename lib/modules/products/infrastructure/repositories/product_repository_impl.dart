import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db);

  final Database _db;

  // -- Mapper ---------------------------------------------------------------
  Product _fromRow(Map<String, Object?> r) {
    DateTime? dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
    double d(Object? v) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
    return Product(
      id: r['id'] as int?,
      businessId: r['business_id'] as int,
      sku: r['sku'] as String,
      barcode: r['barcode'] as String?,
      name: r['name'] as String,
      description: r['description'] as String?,
      categoryId: r['category_id'] as int?,
      brandId: r['brand_id'] as int?,
      unitId: r['unit_id'] as int?,
      purchasePrice: d(r['purchase_price']),
      sellingPrice: d(r['selling_price']),
      taxRate: d(r['tax_rate']),
      minStockLevel: d(r['min_stock_level']),
      isActive: (r['is_active'] as int? ?? 1) == 1,
      createdAt: dt(r['created_at']),
      updatedAt: dt(r['updated_at']),
    );
  }

  @override
  Future<List<Product>> findAll(int businessId,
      {bool includeInactive = false}) async {
    final rows = _db.select(
      'SELECT * FROM products WHERE business_id = ? '
      '${includeInactive ? '' : 'AND is_active = 1'} '
      'ORDER BY name ASC;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Product?> findById(int id) async {
    final rows = _db.select('SELECT * FROM products WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Product?> findBySku(int businessId, String sku) async {
    final rows = _db.select(
      'SELECT * FROM products WHERE business_id = ? AND sku = ?;',
      [businessId, sku],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<Product?> findByBarcode(int businessId, String barcode) async {
    final rows = _db.select(
      'SELECT * FROM products WHERE business_id = ? AND barcode = ?;',
      [businessId, barcode],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<Product>> search(int businessId, String query) async {
    final like = '%$query%';
    final rows = _db.select(
      'SELECT * FROM products WHERE business_id = ? AND is_active = 1 AND '
      '(name LIKE ? OR sku LIKE ? OR barcode LIKE ?) ORDER BY name ASC;',
      [businessId, like, like, like],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Product> insert(Product product) async {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      'INSERT INTO products '
      '(business_id, sku, barcode, name, description, category_id, brand_id, '
      ' unit_id, purchase_price, selling_price, tax_rate, min_stock_level, '
      ' is_active, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        product.businessId,
        product.sku,
        product.barcode,
        product.name,
        product.description,
        product.categoryId,
        product.brandId,
        product.unitId,
        product.purchasePrice,
        product.sellingPrice,
        product.taxRate,
        product.minStockLevel,
        product.isActive ? 1 : 0,
        now,
        now,
      ],
    );
    return (await findById(_db.lastInsertRowId))!;
  }

  @override
  Future<Product> update(Product product) async {
    _db.execute(
      'UPDATE products SET sku = ?, barcode = ?, name = ?, description = ?, '
      'category_id = ?, brand_id = ?, unit_id = ?, purchase_price = ?, '
      'selling_price = ?, tax_rate = ?, min_stock_level = ?, is_active = ?, '
      'updated_at = ? WHERE id = ?;',
      [
        product.sku,
        product.barcode,
        product.name,
        product.description,
        product.categoryId,
        product.brandId,
        product.unitId,
        product.purchasePrice,
        product.sellingPrice,
        product.taxRate,
        product.minStockLevel,
        product.isActive ? 1 : 0,
        DateTime.now().toUtc().toIso8601String(),
        product.id,
      ],
    );
    return (await findById(product.id!))!;
  }

  @override
  Future<void> deactivate(int id) async {
    _db.execute(
      'UPDATE products SET is_active = 0, updated_at = ? WHERE id = ?;',
      [DateTime.now().toUtc().toIso8601String(), id],
    );
  }
}
