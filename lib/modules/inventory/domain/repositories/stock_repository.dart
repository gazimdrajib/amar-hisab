import '../entities/stock.dart';

abstract class StockRepository {
  Future<Stock?> find(int businessId, int productId, int warehouseId);
  Future<List<Stock>> findByProduct(int businessId, int productId);
  Future<List<Stock>> findByWarehouse(int businessId, int warehouseId);

  /// Insert or update the unique (business, product, warehouse) aggregate,
  /// setting `quantity = current + delta`.
  Future<Stock> upsertAdd(
      int businessId, int productId, int warehouseId, double delta);
}
