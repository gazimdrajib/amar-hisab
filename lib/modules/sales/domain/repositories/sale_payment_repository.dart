import '../entities/sale_payment.dart';

abstract class SalePaymentRepository {
  Future<List<SalePayment>> findBySale(int saleId);
  Future<SalePayment> insert(SalePayment payment);
}
