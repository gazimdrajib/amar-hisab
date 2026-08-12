// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SalePayment _$SalePaymentFromJson(Map<String, dynamic> json) {
  return _SalePayment.fromJson(json);
}

/// @nodoc
mixin _$SalePayment {
  int? get id => throw _privateConstructorUsedError;
  int? get saleId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String? get reference => throw _privateConstructorUsedError;
  DateTime? get paymentDate => throw _privateConstructorUsedError;
  int? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this SalePayment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SalePayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SalePaymentCopyWith<SalePayment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SalePaymentCopyWith<$Res> {
  factory $SalePaymentCopyWith(
          SalePayment value, $Res Function(SalePayment) then) =
      _$SalePaymentCopyWithImpl<$Res, SalePayment>;
  @useResult
  $Res call(
      {int? id,
      int? saleId,
      double amount,
      String paymentMethod,
      String? reference,
      DateTime? paymentDate,
      int? createdBy});
}

/// @nodoc
class _$SalePaymentCopyWithImpl<$Res, $Val extends SalePayment>
    implements $SalePaymentCopyWith<$Res> {
  _$SalePaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SalePayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? saleId = freezed,
    Object? amount = null,
    Object? paymentMethod = null,
    Object? reference = freezed,
    Object? paymentDate = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      saleId: freezed == saleId
          ? _value.saleId
          : saleId // ignore: cast_nullable_to_non_nullable
              as int?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      reference: freezed == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentDate: freezed == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SalePaymentImplCopyWith<$Res>
    implements $SalePaymentCopyWith<$Res> {
  factory _$$SalePaymentImplCopyWith(
          _$SalePaymentImpl value, $Res Function(_$SalePaymentImpl) then) =
      __$$SalePaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int? saleId,
      double amount,
      String paymentMethod,
      String? reference,
      DateTime? paymentDate,
      int? createdBy});
}

/// @nodoc
class __$$SalePaymentImplCopyWithImpl<$Res>
    extends _$SalePaymentCopyWithImpl<$Res, _$SalePaymentImpl>
    implements _$$SalePaymentImplCopyWith<$Res> {
  __$$SalePaymentImplCopyWithImpl(
      _$SalePaymentImpl _value, $Res Function(_$SalePaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of SalePayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? saleId = freezed,
    Object? amount = null,
    Object? paymentMethod = null,
    Object? reference = freezed,
    Object? paymentDate = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_$SalePaymentImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      saleId: freezed == saleId
          ? _value.saleId
          : saleId // ignore: cast_nullable_to_non_nullable
              as int?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      reference: freezed == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentDate: freezed == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SalePaymentImpl implements _SalePayment {
  const _$SalePaymentImpl(
      {this.id,
      this.saleId,
      this.amount = 0,
      this.paymentMethod = 'Cash',
      this.reference,
      this.paymentDate,
      this.createdBy});

  factory _$SalePaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SalePaymentImplFromJson(json);

  @override
  final int? id;
  @override
  final int? saleId;
  @override
  @JsonKey()
  final double amount;
  @override
  @JsonKey()
  final String paymentMethod;
  @override
  final String? reference;
  @override
  final DateTime? paymentDate;
  @override
  final int? createdBy;

  @override
  String toString() {
    return 'SalePayment(id: $id, saleId: $saleId, amount: $amount, paymentMethod: $paymentMethod, reference: $reference, paymentDate: $paymentDate, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SalePaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.saleId, saleId) || other.saleId == saleId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, saleId, amount,
      paymentMethod, reference, paymentDate, createdBy);

  /// Create a copy of SalePayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SalePaymentImplCopyWith<_$SalePaymentImpl> get copyWith =>
      __$$SalePaymentImplCopyWithImpl<_$SalePaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SalePaymentImplToJson(
      this,
    );
  }
}

abstract class _SalePayment implements SalePayment {
  const factory _SalePayment(
      {final int? id,
      final int? saleId,
      final double amount,
      final String paymentMethod,
      final String? reference,
      final DateTime? paymentDate,
      final int? createdBy}) = _$SalePaymentImpl;

  factory _SalePayment.fromJson(Map<String, dynamic> json) =
      _$SalePaymentImpl.fromJson;

  @override
  int? get id;
  @override
  int? get saleId;
  @override
  double get amount;
  @override
  String get paymentMethod;
  @override
  String? get reference;
  @override
  DateTime? get paymentDate;
  @override
  int? get createdBy;

  /// Create a copy of SalePayment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SalePaymentImplCopyWith<_$SalePaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
