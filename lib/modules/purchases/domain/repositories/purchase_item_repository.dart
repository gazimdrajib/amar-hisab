import '../entities/purchase_item.dart';

abstract class PurchaseItemRepository {
  Future<List<PurchaseItem>> findByPurchase(int purchaseId);
  Future<PurchaseItem> insert(PurchaseItem item);
}
