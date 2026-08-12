// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounting_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AccountingPeriod _$AccountingPeriodFromJson(Map<String, dynamic> json) {
  return _AccountingPeriod.fromJson(json);
}

/// @nodoc
mixin _$AccountingPeriod {
  int? get id => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  bool get isClosed => throw _privateConstructorUsedError;
  int get businessId => throw _privateConstructorUsedError;

  /// Serializes this AccountingPeriod to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountingPeriodCopyWith<AccountingPeriod> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountingPeriodCopyWith<$Res> {
  factory $AccountingPeriodCopyWith(
          AccountingPeriod value, $Res Function(AccountingPeriod) then) =
      _$AccountingPeriodCopyWithImpl<$Res, AccountingPeriod>;
  @useResult
  $Res call(
      {int? id,
      DateTime startDate,
      DateTime endDate,
      bool isClosed,
      int businessId});
}

/// @nodoc
class _$AccountingPeriodCopyWithImpl<$Res, $Val extends AccountingPeriod>
    implements $AccountingPeriodCopyWith<$Res> {
  _$AccountingPeriodCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? isClosed = null,
    Object? businessId = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AccountingPeriodImplCopyWith<$Res>
    implements $AccountingPeriodCopyWith<$Res> {
  factory _$$AccountingPeriodImplCopyWith(_$AccountingPeriodImpl value,
          $Res Function(_$AccountingPeriodImpl) then) =
      __$$AccountingPeriodImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      DateTime startDate,
      DateTime endDate,
      bool isClosed,
      int businessId});
}

/// @nodoc
class __$$AccountingPeriodImplCopyWithImpl<$Res>
    extends _$AccountingPeriodCopyWithImpl<$Res, _$AccountingPeriodImpl>
    implements _$$AccountingPeriodImplCopyWith<$Res> {
  __$$AccountingPeriodImplCopyWithImpl(_$AccountingPeriodImpl _value,
      $Res Function(_$AccountingPeriodImpl) _then)
      : super(_value, _then);

  /// Create a copy of AccountingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? isClosed = null,
    Object? businessId = null,
  }) {
    return _then(_$AccountingPeriodImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isClosed: null == isClosed
          ? _value.isClosed
          : isClosed // ignore: cast_nullable_to_non_nullable
              as bool,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountingPeriodImpl implements _AccountingPeriod {
  const _$AccountingPeriodImpl(
      {this.id,
      required this.startDate,
      required this.endDate,
      this.isClosed = false,
      required this.businessId});

  factory _$AccountingPeriodImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountingPeriodImplFromJson(json);

  @override
  final int? id;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  @JsonKey()
  final bool isClosed;
  @override
  final int businessId;

  @override
  String toString() {
    return 'AccountingPeriod(id: $id, startDate: $startDate, endDate: $endDate, isClosed: $isClosed, businessId: $businessId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountingPeriodImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.isClosed, isClosed) ||
                other.isClosed == isClosed) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, startDate, endDate, isClosed, businessId);

  /// Create a copy of AccountingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountingPeriodImplCopyWith<_$AccountingPeriodImpl> get copyWith =>
      __$$AccountingPeriodImplCopyWithImpl<_$AccountingPeriodImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountingPeriodImplToJson(
      this,
    );
  }
}

abstract class _AccountingPeriod implements AccountingPeriod {
  const factory _AccountingPeriod(
      {final int? id,
      required final DateTime startDate,
      required final DateTime endDate,
      final bool isClosed,
      required final int businessId}) = _$AccountingPeriodImpl;

  factory _AccountingPeriod.fromJson(Map<String, dynamic> json) =
      _$AccountingPeriodImpl.fromJson;

  @override
  int? get id;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  bool get isClosed;
  @override
  int get businessId;

  /// Create a copy of AccountingPeriod
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountingPeriodImplCopyWith<_$AccountingPeriodImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
