import '../entities/batch.dart';

abstract class BatchRepository {
  Future<List<Batch>> findByProduct(int businessId, int productId,
      {int? warehouseId});

  /// Active batches holding stock, oldest first (FIFO order).
  Future<List<Batch>> findFifoBatches(int businessId, int productId,
      int warehouseId);

  Future<Batch?> findById(int id);
  Future<Batch> insert(Batch batch);
  Future<Batch> update(Batch batch);
  Future<void> adjustQuantity(int id, double newQuantity);
}
