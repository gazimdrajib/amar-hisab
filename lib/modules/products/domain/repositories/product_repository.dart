import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> findAll(int businessId, {bool includeInactive = false});
  Future<Product?> findById(int id);
  Future<Product?> findBySku(int businessId, String sku);
  Future<Product?> findByBarcode(int businessId, String barcode);
  Future<List<Product>> search(int businessId, String query);
  Future<Product> insert(Product product);
  Future<Product> update(Product product);
  Future<void> deactivate(int id);
}
