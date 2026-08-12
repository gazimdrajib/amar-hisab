import '../entities/warehouse.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> findAll(int businessId, {bool includeInactive = false});
  Future<Warehouse?> findById(int id);
  Future<Warehouse?> findByName(int businessId, String name);
  Future<Warehouse> insert(Warehouse warehouse);
  Future<Warehouse> update(Warehouse warehouse);
  Future<void> deactivate(int id);
}
