import '../../../../core/services/audit_service.dart';
import '../../domain/entities/unit.dart';
import '../../domain/repositories/unit_repository.dart';
import 'category_service.dart' show ProductServiceException;

class UnitService {
  UnitService(this._repo, this._audit);

  final UnitRepository _repo;
  final AuditService _audit;

  Future<List<Unit>> list(int businessId, {bool includeInactive = false}) =>
      _repo.findAll(businessId, includeInactive: includeInactive);

  Future<Unit?> getById(int id) => _repo.findById(id);

  Future<Unit> create({
    required int businessId,
    required String name,
    required String abbreviation,
    required int actorId,
  }) async {
    final existing =
        await _repo.findByAbbreviation(businessId, abbreviation);
    if (existing != null) {
      throw ProductServiceException('duplicate', 'Unit already exists');
    }
    final created = await _repo.insert(Unit(
      businessId: businessId,
      name: name,
      abbreviation: abbreviation,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'unit',
      entityId: created.id!,
      action: 'create',
      newValue: 'name=${created.name} (${created.abbreviation})',
      businessId: businessId,
    );
    return created;
  }

  Future<Unit> update({
    required int id,
    required int businessId,
    String? name,
    String? abbreviation,
    bool? isActive,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw ProductServiceException('not_found', 'Unit not found');
    }
    final updated = await _repo.update(existing.copyWith(
      name: name ?? existing.name,
      abbreviation: abbreviation ?? existing.abbreviation,
      isActive: isActive ?? existing.isActive,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'unit',
      entityId: id,
      action: 'update',
      newValue: 'name=${updated.name} (${updated.abbreviation})',
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
      throw ProductServiceException('not_found', 'Unit not found');
    }
    await _repo.deactivate(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'unit',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
