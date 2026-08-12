import '../../../../core/services/audit_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'category_service.dart' show ProductServiceException;

class ProductService {
  ProductService(this._repo, this._audit);

  final ProductRepository _repo;
  final AuditService _audit;

  Future<List<Product>> list(int businessId, {bool includeInactive = false}) =>
      _repo.findAll(businessId, includeInactive: includeInactive);

  Future<Product?> getById(int id) => _repo.findById(id);

  Future<List<Product>> search(int businessId, String query) =>
      _repo.search(businessId, query);

  Future<Product> create({
    required int businessId,
    required String sku,
    String? barcode,
    required String name,
    String? description,
    int? categoryId,
    int? brandId,
    int? unitId,
    double purchasePrice = 0,
    double sellingPrice = 0,
    double taxRate = 0,
    double minStockLevel = 0,
    required int actorId,
  }) async {
    final existing = await _repo.findBySku(businessId, sku);
    if (existing != null) {
      throw ProductServiceException('duplicate', 'SKU already exists');
    }
    final created = await _repo.insert(Product(
      businessId: businessId,
      sku: sku,
      barcode: barcode,
      name: name,
      description: description,
      categoryId: categoryId,
      brandId: brandId,
      unitId: unitId,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      taxRate: taxRate,
      minStockLevel: minStockLevel,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'product',
      entityId: created.id!,
      action: 'create',
      newValue: 'sku=${created.sku}; name=${created.name}; '
          'price=${created.sellingPrice}',
      businessId: businessId,
    );
    return created;
  }

  Future<Product> update({
    required int id,
    required int businessId,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    int? categoryId,
    int? brandId,
    int? unitId,
    double? purchasePrice,
    double? sellingPrice,
    double? taxRate,
    double? minStockLevel,
    bool? isActive,
    required int actorId,
  }) async {
    final existing = await _repo.findById(id);
    if (existing == null || existing.businessId != businessId) {
      throw ProductServiceException('not_found', 'Product not found');
    }
    if (sku != null && sku != existing.sku) {
      final clash = await _repo.findBySku(businessId, sku);
      if (clash != null && clash.id != id) {
        throw ProductServiceException('duplicate', 'SKU already exists');
      }
    }
    final updated = await _repo.update(existing.copyWith(
      sku: sku ?? existing.sku,
      barcode: barcode ?? existing.barcode,
      name: name ?? existing.name,
      description: description ?? existing.description,
      categoryId: categoryId ?? existing.categoryId,
      brandId: brandId ?? existing.brandId,
      unitId: unitId ?? existing.unitId,
      purchasePrice: purchasePrice ?? existing.purchasePrice,
      sellingPrice: sellingPrice ?? existing.sellingPrice,
      taxRate: taxRate ?? existing.taxRate,
      minStockLevel: minStockLevel ?? existing.minStockLevel,
      isActive: isActive ?? existing.isActive,
    ));
    _audit.logAction(
      userId: actorId,
      entityType: 'product',
      entityId: id,
      action: 'update',
      oldValue: 'sku=${existing.sku}; price=${existing.sellingPrice}',
      newValue: 'sku=${updated.sku}; price=${updated.sellingPrice}',
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
      throw ProductServiceException('not_found', 'Product not found');
    }
    await _repo.deactivate(id);
    _audit.logAction(
      userId: actorId,
      entityType: 'product',
      entityId: id,
      action: 'delete',
      businessId: businessId,
    );
  }
}
