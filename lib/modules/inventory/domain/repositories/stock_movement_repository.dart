import '../entities/stock_movement.dart';

abstract class StockMovementRepository {
  Future<StockMovement> insert(StockMovement movement);
  Future<List<StockMovement>> findByProduct(int businessId, int productId,
      {int limit = 200});
  Future<List<StockMovement>> findByWarehouse(int businessId, int warehouseId,
      {int limit = 200});
}
