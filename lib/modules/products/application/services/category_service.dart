import '../../../../core/services/audit_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class ProductServiceException implements Exception {
  ProductServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class CategoryService {
  CategoryService(this._repo, this._audit);

  final CategoryRepository _repo;
  final AuditService _audit;

  Future<List<Category>> list(int businessId, {bool includeInactive = false}) =>
      _repo.findAll(businessId, includeInactive: includeInactive);

  Future<Category?> getById(int id) => _repo.findById(id);

  Future<Category> create({
    required int businessId,
    required String name,
    String? description,
    int? parentId,
    required int actorId,
  }) async {
    final existing = await _repo.findByName(businessId, name);
    if (existing != null) {
      throw ProductServiceException('duplicate', 'Category already exists');
    }
    final created = await _repo.insert(Category(
      businessId: businessId,
      name: name,
      description: description,
      parentId: parentId,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'category',
      entityId: created.id!,
      action: 'create',
      newValue: 'name=${created.name}',
      businessId: businessId,
    );
    return created;
  }

  Future<Category> update({
    required int id,
    required int businessId,
    String? name,
    String? description,
    int? parentId,
    bool? isActive,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw ProductServiceException('not_found', 'Category not found');
    }
    final updated = await _repo.update(existing.copyWith(
      name: name ?? existing.name,
      description: description ?? existing.description,
      parentId: parentId ?? existing.parentId,
      isActive: isActive ?? existing.isActive,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'category',
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
      throw ProductServiceException('not_found', 'Category not found');
    }
    await _repo.deactivate(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'category',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
