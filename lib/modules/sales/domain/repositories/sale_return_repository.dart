import '../entities/sale_return.dart';

abstract class SaleReturnRepository {
  Future<SaleReturn> insert(SaleReturn saleReturn);
  Future<List<SaleReturn>> findBySale(int saleId);
  Future<SaleReturn?> findById(int id);
}
