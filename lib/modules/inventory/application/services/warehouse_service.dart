import '../../../../core/services/audit_service.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';

class InventoryServiceException implements Exception {
  InventoryServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class WarehouseService {
  WarehouseService(this._repo, this._audit);

  final WarehouseRepository _repo;
  final AuditService _audit;

  Future<List<Warehouse>> list(int businessId, {bool includeInactive = false}) =>
      _repo.findAll(businessId, includeInactive: includeInactive);

  Future<Warehouse?> getById(int id) => _repo.findById(id);

  Future<Warehouse> create({
    required int businessId,
    required String name,
    String? location,
    required int actorId,
  }) async {
    final existing = await _repo.findByName(businessId, name);
    if (existing != null) {
      throw InventoryServiceException('duplicate', 'Warehouse already exists');
    }
    final created = await _repo.insert(Warehouse(
      businessId: businessId,
      name: name,
      location: location,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'warehouse',
      entityId: created.id!,
      action: 'create',
      newValue: 'name=${created.name}',
      businessId: businessId,
    );
    return created;
  }

  Future<Warehouse> update({
    required int id,
    required int businessId,
    String? name,
    String? location,
    bool? isActive,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw InventoryServiceException('not_found', 'Warehouse not found');
    }
    final updated = await _repo.update(existing.copyWith(
      name: name ?? existing.name,
      location: location ?? existing.location,
      isActive: isActive ?? existing.isActive,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'warehouse',
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
      throw InventoryServiceException('not_found', 'Warehouse not found');
    }
    await _repo.deactivate(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'warehouse',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
