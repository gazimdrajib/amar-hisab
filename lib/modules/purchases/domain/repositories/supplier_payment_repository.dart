import '../entities/supplier_payment.dart';

abstract class SupplierPaymentRepository {
  Future<List<SupplierPayment>> findByPurchase(int purchaseId);
  Future<SupplierPayment> insert(SupplierPayment payment);
}
