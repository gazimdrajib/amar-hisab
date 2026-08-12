// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PurchaseItem _$PurchaseItemFromJson(Map<String, dynamic> json) {
  return _PurchaseItem.fromJson(json);
}

/// @nodoc
mixin _$PurchaseItem {
  int? get id => throw _privateConstructorUsedError;
  int? get purchaseId => throw _privateConstructorUsedError;
  int get productId => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  double get unitPrice => throw _privateConstructorUsedError;
  double get discountPercent => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  double get taxPercent => throw _privateConstructorUsedError;
  double get taxAmount => throw _privateConstructorUsedError;
  double get lineTotal => throw _privateConstructorUsedError;

  /// Serializes this PurchaseItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseItemCopyWith<PurchaseItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseItemCopyWith<$Res> {
  factory $PurchaseItemCopyWith(
          PurchaseItem value, $Res Function(PurchaseItem) then) =
      _$PurchaseItemCopyWithImpl<$Res, PurchaseItem>;
  @useResult
  $Res call(
      {int? id,
      int? purchaseId,
      int productId,
      double quantity,
      double unitPrice,
      double discountPercent,
      double discountAmount,
      double taxPercent,
      double taxAmount,
      double lineTotal});
}

/// @nodoc
class _$PurchaseItemCopyWithImpl<$Res, $Val extends PurchaseItem>
    implements $PurchaseItemCopyWith<$Res> {
  _$PurchaseItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? purchaseId = freezed,
    Object? productId = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? discountPercent = null,
    Object? discountAmount = null,
    Object? taxPercent = null,
    Object? taxAmount = null,
    Object? lineTotal = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      purchaseId: freezed == purchaseId
          ? _value.purchaseId
          : purchaseId // ignore: cast_nullable_to_non_nullable
              as int?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      discountPercent: null == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      taxPercent: null == taxPercent
          ? _value.taxPercent
          : taxPercent // ignore: cast_nullable_to_non_nullable
              as double,
      taxAmount: null == taxAmount
          ? _value.taxAmount
          : taxAmount // ignore: cast_nullable_to_non_nullable
              as double,
      lineTotal: null == lineTotal
          ? _value.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseItemImplCopyWith<$Res>
    implements $PurchaseItemCopyWith<$Res> {
  factory _$$PurchaseItemImplCopyWith(
          _$PurchaseItemImpl value, $Res Function(_$PurchaseItemImpl) then) =
      __$$PurchaseItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int? purchaseId,
      int productId,
      double quantity,
      double unitPrice,
      double discountPercent,
      double discountAmount,
      double taxPercent,
      double taxAmount,
      double lineTotal});
}

/// @nodoc
class __$$PurchaseItemImplCopyWithImpl<$Res>
    extends _$PurchaseItemCopyWithImpl<$Res, _$PurchaseItemImpl>
    implements _$$PurchaseItemImplCopyWith<$Res> {
  __$$PurchaseItemImplCopyWithImpl(
      _$PurchaseItemImpl _value, $Res Function(_$PurchaseItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? purchaseId = freezed,
    Object? productId = null,
    Object? quantity = null,
    Object? unitPrice = null,
    Object? discountPercent = null,
    Object? discountAmount = null,
    Object? taxPercent = null,
    Object? taxAmount = null,
    Object? lineTotal = null,
  }) {
    return _then(_$PurchaseItemImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      purchaseId: freezed == purchaseId
          ? _value.purchaseId
          : purchaseId // ignore: cast_nullable_to_non_nullable
              as int?,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      discountPercent: null == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      taxPercent: null == taxPercent
          ? _value.taxPercent
          : taxPercent // ignore: cast_nullable_to_non_nullable
              as double,
      taxAmount: null == taxAmount
          ? _value.taxAmount
          : taxAmount // ignore: cast_nullable_to_non_nullable
              as double,
      lineTotal: null == lineTotal
          ? _value.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseItemImpl implements _PurchaseItem {
  const _$PurchaseItemImpl(
      {this.id,
      this.purchaseId,
      required this.productId,
      this.quantity = 0,
      this.unitPrice = 0,
      this.discountPercent = 0,
      this.discountAmount = 0,
      this.taxPercent = 0,
      this.taxAmount = 0,
      this.lineTotal = 0});

  factory _$PurchaseItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseItemImplFromJson(json);

  @override
  final int? id;
  @override
  final int? purchaseId;
  @override
  final int productId;
  @override
  @JsonKey()
  final double quantity;
  @override
  @JsonKey()
  final double unitPrice;
  @override
  @JsonKey()
  final double discountPercent;
  @override
  @JsonKey()
  final double discountAmount;
  @override
  @JsonKey()
  final double taxPercent;
  @override
  @JsonKey()
  final double taxAmount;
  @override
  @JsonKey()
  final double lineTotal;

  @override
  String toString() {
    return 'PurchaseItem(id: $id, purchaseId: $purchaseId, productId: $productId, quantity: $quantity, unitPrice: $unitPrice, discountPercent: $discountPercent, discountAmount: $discountAmount, taxPercent: $taxPercent, taxAmount: $taxAmount, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.purchaseId, purchaseId) ||
                other.purchaseId == purchaseId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.taxPercent, taxPercent) ||
                other.taxPercent == taxPercent) &&
            (identical(other.taxAmount, taxAmount) ||
                other.taxAmount == taxAmount) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      purchaseId,
      productId,
      quantity,
      unitPrice,
      discountPercent,
      discountAmount,
      taxPercent,
      taxAmount,
      lineTotal);

  /// Create a copy of PurchaseItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseItemImplCopyWith<_$PurchaseItemImpl> get copyWith =>
      __$$PurchaseItemImplCopyWithImpl<_$PurchaseItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseItemImplToJson(
      this,
    );
  }
}

abstract class _PurchaseItem implements PurchaseItem {
  const factory _PurchaseItem(
      {final int? id,
      final int? purchaseId,
      required final int productId,
      final double quantity,
      final double unitPrice,
      final double discountPercent,
      final double discountAmount,
      final double taxPercent,
      final double taxAmount,
      final double lineTotal}) = _$PurchaseItemImpl;

  factory _PurchaseItem.fromJson(Map<String, dynamic> json) =
      _$PurchaseItemImpl.fromJson;

  @override
  int? get id;
  @override
  int? get purchaseId;
  @override
  int get productId;
  @override
  double get quantity;
  @override
  double get unitPrice;
  @override
  double get discountPercent;
  @override
  double get discountAmount;
  @override
  double get taxPercent;
  @override
  double get taxAmount;
  @override
  double get lineTotal;

  /// Create a copy of PurchaseItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseItemImplCopyWith<_$PurchaseItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
