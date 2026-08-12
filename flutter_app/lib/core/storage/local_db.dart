import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/sale.dart';
import '../../models/stock.dart';
import '../constants/app_config.dart';

/// SQLite local cache (sqflite). Lets the dashboard, POS and history screens
/// render instantly and stay usable while the network is unreachable.
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    databaseFactory = databaseFactoryFfi;
    String dbPath;
    if (kIsWeb) {
      dbPath = AppConfig.dbName;
    } else {
      final dir = await getApplicationSupportDirectory();
      dbPath = p.join(dir.path, AppConfig.dbName);
    }
    _db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppConfig.dbVersion,
        onCreate: _onCreate,
      ),
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        businessId INTEGER,
        sku TEXT,
        barcode TEXT,
        name TEXT,
        categoryId INTEGER,
        brandId INTEGER,
        unitId INTEGER,
        purchasePrice REAL,
        sellingPrice REAL,
        minStockLevel REAL,
        isActive INTEGER,
        syncedAt TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_products_name ON products(name COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY,
        invoiceNumber TEXT,
        warehouseId INTEGER,
        grandTotal REAL,
        paidAmount REAL,
        dueAmount REAL,
        status TEXT,
        paymentStatus TEXT,
        saleType TEXT,
        saleDate TEXT,
        raw TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY,
        invoiceNumber TEXT,
        warehouseId INTEGER,
        grandTotal REAL,
        status TEXT,
        purchaseDate TEXT,
        raw TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY,
        name TEXT,
        location TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE stock (
        id INTEGER PRIMARY KEY,
        productId INTEGER,
        warehouseId INTEGER,
        quantity REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ---------------- Products ----------------

  Future<void> cacheProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    await db.delete('products');
    for (final product in products) {
      batch.insert('products', {
        ...product.toJson()..remove('description'),
        'isActive': product.isActive ? 1 : 0,
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getProducts({String? search}) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: search == null || search.isEmpty
          ? null
          : 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
      whereArgs: search == null || search.isEmpty
          ? null
          : ['%$search%', '%$search%', '%$search%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map((row) => Product.fromJson({
              ...row,
              'isActive': (row['isActive'] as num?) == 1,
              'createdAt': null,
              'updatedAt': null,
            }))
        .toList();
  }

  Future<Product?> findByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query('products',
        where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromJson({
      ...rows.first,
      'isActive': (rows.first['isActive'] as num?) == 1,
    });
  }

  // ---------------- Sales / Purchases ----------------

  Future<void> cacheSales(List<Sale> sales) async {
    final db = await database;
    final batch = db.batch();
    await db.delete('sales');
    for (final sale in sales) {
      batch.insert('sales', {
        'id': sale.id,
        'invoiceNumber': sale.invoiceNumber,
        'warehouseId': sale.warehouseId,
        'grandTotal': sale.grandTotal,
        'paidAmount': sale.paidAmount,
        'dueAmount': sale.dueAmount,
        'status': sale.status,
        'paymentStatus': sale.paymentStatus,
        'saleType': sale.saleType,
        'saleDate': sale.saleDate.toIso8601String(),
        'raw': jsonEncode(sale.toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Sale>> getSales() async {
    final db = await database;
    final rows = await db.query('sales', orderBy: 'saleDate DESC');
    return rows
        .map((row) =>
            Sale.fromJson(jsonDecode(row['raw'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> cachePurchases(List<Purchase> purchases) async {
    final db = await database;
    final batch = db.batch();
    await db.delete('purchases');
    for (final purchase in purchases) {
      batch.insert('purchases', {
        'id': purchase.id,
        'invoiceNumber': purchase.invoiceNumber,
        'warehouseId': purchase.warehouseId,
        'grandTotal': purchase.grandTotal,
        'status': purchase.status,
        'purchaseDate': purchase.purchaseDate.toIso8601String(),
        'raw': jsonEncode(purchase.toJson()),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await database;
    final rows = await db.query('purchases', orderBy: 'purchaseDate DESC');
    return rows
        .map((row) => Purchase.fromJson(
            jsonDecode(row['raw'] as String) as Map<String, dynamic>))
        .toList();
  }

  // ---------------- Warehouses / Stock ----------------

  Future<void> cacheWarehouses(List<Warehouse> warehouses) async {
    final db = await database;
    await db.delete('warehouses');
    final batch = db.batch();
    for (final warehouse in warehouses) {
      batch.insert('warehouses', {
        'id': warehouse.id,
        'name': warehouse.name,
        'location': warehouse.location ?? '',
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Warehouse>> getWarehouses() async {
    final db = await database;
    final rows = await db.query('warehouses', orderBy: 'name');
    return rows
        .map((row) => Warehouse(
              id: row['id'] as int,
              businessId: 0,
              name: row['name']?.toString() ?? '',
              location: row['location']?.toString(),
              isActive: true,
            ))
        .toList();
  }

  Future<void> cacheStock(List<StockEntry> stock) async {
    final db = await database;
    await db.delete('stock');
    final batch = db.batch();
    for (final entry in stock) {
      batch.insert('stock', {
        'id': entry.id,
        'productId': entry.productId,
        'warehouseId': entry.warehouseId,
        'quantity': entry.quantity,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<StockEntry>> getStock() async {
    final db = await database;
    final rows = await db.query('stock');
    return rows
        .map((row) => StockEntry(
              id: row['id'] as int,
              businessId: 0,
              productId: row['productId'] as int,
              warehouseId: row['warehouseId'] as int,
              quantity: (row['quantity'] as num).toDouble(),
            ))
        .toList();
  }

  // ---------------- Sync metadata ----------------

  Future<void> setSyncTime(String key, DateTime time) async {
    final db = await database;
    await db.insert('sync_meta', {'key': key, 'value': time.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> getSyncTime(String key) async {
    final db = await database;
    final rows =
        await db.query('sync_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value']?.toString() ?? '');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
