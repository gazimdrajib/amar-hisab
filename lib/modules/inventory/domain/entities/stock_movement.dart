import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_movement.freezed.dart';
part 'stock_movement.g.dart';

/// Immutable ledger record for every stock-impacting operation.
///
/// `movement_type` values: `add`, `deduct`, `transfer_out`, `transfer_in`,
/// `adjust`, `damage`, `sale`, `purchase`.
@freezed
class StockMovement with _$StockMovement {
  const factory StockMovement({
    int? id,
    required int businessId,
    required int productId,
    required int warehouseId,
    int? batchId,
    required String movementType,
    required double quantity,
    String? referenceType,
    int? referenceId,
    String? note,
    int? performedBy,
    DateTime? createdAt,
  }) = _StockMovement;

  factory StockMovement.fromJson(Map<String, dynamic> json) =>
      _$StockMovementFromJson(json);
}
