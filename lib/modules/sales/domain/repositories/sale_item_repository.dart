import '../entities/sale_item.dart';

abstract class SaleItemRepository {
  Future<List<SaleItem>> findBySale(int saleId);
  Future<SaleItem> insert(SaleItem item);
}
