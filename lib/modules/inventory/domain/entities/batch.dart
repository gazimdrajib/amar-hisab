import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch.freezed.dart';
part 'batch.g.dart';

@freezed
class Batch with _$Batch {
  const factory Batch({
    int? id,
    required int businessId,
    required int productId,
    required int warehouseId,
    String? batchNumber,
    @Default(0) double purchasePrice,
    DateTime? expiryDate,
    required DateTime receivedAt,
    @Default(0) double quantity,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _Batch;

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
}
