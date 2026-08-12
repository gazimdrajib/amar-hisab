// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_return.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SaleReturn _$SaleReturnFromJson(Map<String, dynamic> json) {
  return _SaleReturn.fromJson(json);
}

/// @nodoc
mixin _$SaleReturn {
  int? get id => throw _privateConstructorUsedError;
  int get saleId => throw _privateConstructorUsedError;
  DateTime? get returnDate => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  bool get restock => throw _privateConstructorUsedError;
  double get refundAmount => throw _privateConstructorUsedError;
  String? get refundMethod => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SaleReturn to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaleReturn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaleReturnCopyWith<SaleReturn> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaleReturnCopyWith<$Res> {
  factory $SaleReturnCopyWith(
          SaleReturn value, $Res Function(SaleReturn) then) =
      _$SaleReturnCopyWithImpl<$Res, SaleReturn>;
  @useResult
  $Res call(
      {int? id,
      int saleId,
      DateTime? returnDate,
      String? reason,
      bool restock,
      double refundAmount,
      String? refundMethod,
      DateTime? createdAt});
}

/// @nodoc
class _$SaleReturnCopyWithImpl<$Res, $Val extends SaleReturn>
    implements $SaleReturnCopyWith<$Res> {
  _$SaleReturnCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaleReturn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? saleId = null,
    Object? returnDate = freezed,
    Object? reason = freezed,
    Object? restock = null,
    Object? refundAmount = null,
    Object? refundMethod = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      saleId: null == saleId
          ? _value.saleId
          : saleId // ignore: cast_nullable_to_non_nullable
              as int,
      returnDate: freezed == returnDate
          ? _value.returnDate
          : returnDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      restock: null == restock
          ? _value.restock
          : restock // ignore: cast_nullable_to_non_nullable
              as bool,
      refundAmount: null == refundAmount
          ? _value.refundAmount
          : refundAmount // ignore: cast_nullable_to_non_nullable
              as double,
      refundMethod: freezed == refundMethod
          ? _value.refundMethod
          : refundMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SaleReturnImplCopyWith<$Res>
    implements $SaleReturnCopyWith<$Res> {
  factory _$$SaleReturnImplCopyWith(
          _$SaleReturnImpl value, $Res Function(_$SaleReturnImpl) then) =
      __$$SaleReturnImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int saleId,
      DateTime? returnDate,
      String? reason,
      bool restock,
      double refundAmount,
      String? refundMethod,
      DateTime? createdAt});
}

/// @nodoc
class __$$SaleReturnImplCopyWithImpl<$Res>
    extends _$SaleReturnCopyWithImpl<$Res, _$SaleReturnImpl>
    implements _$$SaleReturnImplCopyWith<$Res> {
  __$$SaleReturnImplCopyWithImpl(
      _$SaleReturnImpl _value, $Res Function(_$SaleReturnImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaleReturn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? saleId = null,
    Object? returnDate = freezed,
    Object? reason = freezed,
    Object? restock = null,
    Object? refundAmount = null,
    Object? refundMethod = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$SaleReturnImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      saleId: null == saleId
          ? _value.saleId
          : saleId // ignore: cast_nullable_to_non_nullable
              as int,
      returnDate: freezed == returnDate
          ? _value.returnDate
          : returnDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      restock: null == restock
          ? _value.restock
          : restock // ignore: cast_nullable_to_non_nullable
              as bool,
      refundAmount: null == refundAmount
          ? _value.refundAmount
          : refundAmount // ignore: cast_nullable_to_non_nullable
              as double,
      refundMethod: freezed == refundMethod
          ? _value.refundMethod
          : refundMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SaleReturnImpl implements _SaleReturn {
  const _$SaleReturnImpl(
      {this.id,
      required this.saleId,
      this.returnDate,
      this.reason,
      this.restock = false,
      this.refundAmount = 0,
      this.refundMethod,
      this.createdAt});

  factory _$SaleReturnImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaleReturnImplFromJson(json);

  @override
  final int? id;
  @override
  final int saleId;
  @override
  final DateTime? returnDate;
  @override
  final String? reason;
  @override
  @JsonKey()
  final bool restock;
  @override
  @JsonKey()
  final double refundAmount;
  @override
  final String? refundMethod;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'SaleReturn(id: $id, saleId: $saleId, returnDate: $returnDate, reason: $reason, restock: $restock, refundAmount: $refundAmount, refundMethod: $refundMethod, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaleReturnImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saleId, saleId) || other.saleId == saleId) &&
            (identical(other.returnDate, returnDate) ||
                other.returnDate == returnDate) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.restock, restock) || other.restock == restock) &&
            (identical(other.refundAmount, refundAmount) ||
                other.refundAmount == refundAmount) &&
            (identical(other.refundMethod, refundMethod) ||
                other.refundMethod == refundMethod) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, saleId, returnDate, reason,
      restock, refundAmount, refundMethod, createdAt);

  /// Create a copy of SaleReturn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaleReturnImplCopyWith<_$SaleReturnImpl> get copyWith =>
      __$$SaleReturnImplCopyWithImpl<_$SaleReturnImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaleReturnImplToJson(
      this,
    );
  }
}

abstract class _SaleReturn implements SaleReturn {
  const factory _SaleReturn(
      {final int? id,
      required final int saleId,
      final DateTime? returnDate,
      final String? reason,
      final bool restock,
      final double refundAmount,
      final String? refundMethod,
      final DateTime? createdAt}) = _$SaleReturnImpl;

  factory _SaleReturn.fromJson(Map<String, dynamic> json) =
      _$SaleReturnImpl.fromJson;

  @override
  int? get id;
  @override
  int get saleId;
  @override
  DateTime? get returnDate;
  @override
  String? get reason;
  @override
  bool get restock;
  @override
  double get refundAmount;
  @override
  String? get refundMethod;
  @override
  DateTime? get createdAt;

  /// Create a copy of SaleReturn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaleReturnImplCopyWith<_$SaleReturnImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
