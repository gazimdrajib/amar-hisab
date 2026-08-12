// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supplier_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SupplierPayment _$SupplierPaymentFromJson(Map<String, dynamic> json) {
  return _SupplierPayment.fromJson(json);
}

/// @nodoc
mixin _$SupplierPayment {
  int? get id => throw _privateConstructorUsedError;
  int? get supplierId => throw _privateConstructorUsedError;
  int? get purchaseId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String? get reference => throw _privateConstructorUsedError;
  DateTime? get paymentDate => throw _privateConstructorUsedError;
  int? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this SupplierPayment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SupplierPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SupplierPaymentCopyWith<SupplierPayment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupplierPaymentCopyWith<$Res> {
  factory $SupplierPaymentCopyWith(
          SupplierPayment value, $Res Function(SupplierPayment) then) =
      _$SupplierPaymentCopyWithImpl<$Res, SupplierPayment>;
  @useResult
  $Res call(
      {int? id,
      int? supplierId,
      int? purchaseId,
      double amount,
      String paymentMethod,
      String? reference,
      DateTime? paymentDate,
      int? createdBy});
}

/// @nodoc
class _$SupplierPaymentCopyWithImpl<$Res, $Val extends SupplierPayment>
    implements $SupplierPaymentCopyWith<$Res> {
  _$SupplierPaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SupplierPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? supplierId = freezed,
    Object? purchaseId = freezed,
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
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as int?,
      purchaseId: freezed == purchaseId
          ? _value.purchaseId
          : purchaseId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SupplierPaymentImplCopyWith<$Res>
    implements $SupplierPaymentCopyWith<$Res> {
  factory _$$SupplierPaymentImplCopyWith(_$SupplierPaymentImpl value,
          $Res Function(_$SupplierPaymentImpl) then) =
      __$$SupplierPaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int? supplierId,
      int? purchaseId,
      double amount,
      String paymentMethod,
      String? reference,
      DateTime? paymentDate,
      int? createdBy});
}

/// @nodoc
class __$$SupplierPaymentImplCopyWithImpl<$Res>
    extends _$SupplierPaymentCopyWithImpl<$Res, _$SupplierPaymentImpl>
    implements _$$SupplierPaymentImplCopyWith<$Res> {
  __$$SupplierPaymentImplCopyWithImpl(
      _$SupplierPaymentImpl _value, $Res Function(_$SupplierPaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of SupplierPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? supplierId = freezed,
    Object? purchaseId = freezed,
    Object? amount = null,
    Object? paymentMethod = null,
    Object? reference = freezed,
    Object? paymentDate = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_$SupplierPaymentImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      supplierId: freezed == supplierId
          ? _value.supplierId
          : supplierId // ignore: cast_nullable_to_non_nullable
              as int?,
      purchaseId: freezed == purchaseId
          ? _value.purchaseId
          : purchaseId // ignore: cast_nullable_to_non_nullable
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
class _$SupplierPaymentImpl implements _SupplierPayment {
  const _$SupplierPaymentImpl(
      {this.id,
      this.supplierId,
      this.purchaseId,
      this.amount = 0,
      this.paymentMethod = 'Cash',
      this.reference,
      this.paymentDate,
      this.createdBy});

  factory _$SupplierPaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupplierPaymentImplFromJson(json);

  @override
  final int? id;
  @override
  final int? supplierId;
  @override
  final int? purchaseId;
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
    return 'SupplierPayment(id: $id, supplierId: $supplierId, purchaseId: $purchaseId, amount: $amount, paymentMethod: $paymentMethod, reference: $reference, paymentDate: $paymentDate, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupplierPaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.purchaseId, purchaseId) ||
                other.purchaseId == purchaseId) &&
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
  int get hashCode => Object.hash(runtimeType, id, supplierId, purchaseId,
      amount, paymentMethod, reference, paymentDate, createdBy);

  /// Create a copy of SupplierPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SupplierPaymentImplCopyWith<_$SupplierPaymentImpl> get copyWith =>
      __$$SupplierPaymentImplCopyWithImpl<_$SupplierPaymentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SupplierPaymentImplToJson(
      this,
    );
  }
}

abstract class _SupplierPayment implements SupplierPayment {
  const factory _SupplierPayment(
      {final int? id,
      final int? supplierId,
      final int? purchaseId,
      final double amount,
      final String paymentMethod,
      final String? reference,
      final DateTime? paymentDate,
      final int? createdBy}) = _$SupplierPaymentImpl;

  factory _SupplierPayment.fromJson(Map<String, dynamic> json) =
      _$SupplierPaymentImpl.fromJson;

  @override
  int? get id;
  @override
  int? get supplierId;
  @override
  int? get purchaseId;
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

  /// Create a copy of SupplierPayment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SupplierPaymentImplCopyWith<_$SupplierPaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
