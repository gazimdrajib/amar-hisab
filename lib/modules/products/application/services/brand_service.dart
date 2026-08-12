import '../../../../core/services/audit_service.dart';
import '../../domain/entities/brand.dart';
import '../../domain/repositories/brand_repository.dart';
import 'category_service.dart' show ProductServiceException;

class BrandService {
  BrandService(this._repo, this._audit);

  final BrandRepository _repo;
  final AuditService _audit;

  Future<List<Brand>> list(int businessId, {bool includeInactive = false}) =>
      _repo.findAll(businessId, includeInactive: includeInactive);

  Future<Brand?> getById(int id) => _repo.findById(id);

  Future<Brand> create({
    required int businessId,
    required String name,
    String? description,
    required int actorId,
  }) async {
    final existing = await _repo.findByName(businessId, name);
    if (existing != null) {
      throw ProductServiceException('duplicate', 'Brand already exists');
    }
    final created = await _repo.insert(Brand(
      businessId: businessId,
      name: name,
      description: description,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'brand',
      entityId: created.id!,
      action: 'create',
      newValue: 'name=${created.name}',
      businessId: businessId,
    );
    return created;
  }

  Future<Brand> update({
    required int id,
    required int businessId,
    String? name,
    String? description,
    bool? isActive,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw ProductServiceException('not_found', 'Brand not found');
    }
    final updated = await _repo.update(existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      isActive: isActive ?? existing.isActive,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'brand',
      entityId: id,
      action: 'update',
      newValue: 'name=${updated.name}',
      businessId: businessId,
    );
    return updated;
  }

  Future<void> delete({
    required int id,
    required int businessId,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw ProductServiceException('not_found', 'Brand not found');
    }
    await _repo.deactivate(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'brand',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
