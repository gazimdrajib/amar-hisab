import '../entities/brand.dart';

abstract class BrandRepository {
  Future<List<Brand>> findAll(int businessId, {bool includeInactive = false});
  Future<Brand?> findById(int id);
  Future<Brand?> findByName(int businessId, String name);
  Future<Brand> insert(Brand brand);
  Future<Brand> update(Brand brand);
  Future<void> deactivate(int id);
}
