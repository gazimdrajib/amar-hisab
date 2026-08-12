// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StudentToken _$StudentTokenFromJson(Map<String, dynamic> json) {
  return _StudentToken.fromJson(json);
}

/// @nodoc
mixin _$StudentToken {
  int? get id => throw _privateConstructorUsedError;
  int get businessId => throw _privateConstructorUsedError;

  /// The opaque token embedded in the QR URL (`/public/qr/{token}/...`).
  String get token => throw _privateConstructorUsedError;

  /// Scope of the token: `student`, `batch` or `business`.
  String get type => throw _privateConstructorUsedError;

  /// Set for `student` tokens; null for batch/business QR tokens that can
  /// list many student IDs.
  int? get studentId => throw _privateConstructorUsedError;

  /// Batch scope for `batch` tokens.
  int? get batchId => throw _privateConstructorUsedError;

  /// SHA-256 hash of the student login secret (null for QR-only tokens).
  String? get secretHash => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StudentToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudentToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudentTokenCopyWith<StudentToken> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentTokenCopyWith<$Res> {
  factory $StudentTokenCopyWith(
          StudentToken value, $Res Function(StudentToken) then) =
      _$StudentTokenCopyWithImpl<$Res, StudentToken>;
  @useResult
  $Res call(
      {int? id,
      int businessId,
      String token,
      String type,
      int? studentId,
      int? batchId,
      String? secretHash,
      DateTime? expiresAt,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class _$StudentTokenCopyWithImpl<$Res, $Val extends StudentToken>
    implements $StudentTokenCopyWith<$Res> {
  _$StudentTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudentToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? businessId = null,
    Object? token = null,
    Object? type = null,
    Object? studentId = freezed,
    Object? batchId = freezed,
    Object? secretHash = freezed,
    Object? expiresAt = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int?,
      batchId: freezed == batchId
          ? _value.batchId
          : batchId // ignore: cast_nullable_to_non_nullable
              as int?,
      secretHash: freezed == secretHash
          ? _value.secretHash
          : secretHash // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentTokenImplCopyWith<$Res>
    implements $StudentTokenCopyWith<$Res> {
  factory _$$StudentTokenImplCopyWith(
          _$StudentTokenImpl value, $Res Function(_$StudentTokenImpl) then) =
      __$$StudentTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int businessId,
      String token,
      String type,
      int? studentId,
      int? batchId,
      String? secretHash,
      DateTime? expiresAt,
      bool isActive,
      DateTime? createdAt});
}

/// @nodoc
class __$$StudentTokenImplCopyWithImpl<$Res>
    extends _$StudentTokenCopyWithImpl<$Res, _$StudentTokenImpl>
    implements _$$StudentTokenImplCopyWith<$Res> {
  __$$StudentTokenImplCopyWithImpl(
      _$StudentTokenImpl _value, $Res Function(_$StudentTokenImpl) _then)
      : super(_value, _then);

  /// Create a copy of StudentToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? businessId = null,
    Object? token = null,
    Object? type = null,
    Object? studentId = freezed,
    Object? batchId = freezed,
    Object? secretHash = freezed,
    Object? expiresAt = freezed,
    Object? isActive = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$StudentTokenImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: freezed == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as int?,
      batchId: freezed == batchId
          ? _value.batchId
          : batchId // ignore: cast_nullable_to_non_nullable
              as int?,
      secretHash: freezed == secretHash
          ? _value.secretHash
          : secretHash // ignore: cast_nullable_to_non_nullable
              as String?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentTokenImpl implements _StudentToken {
  const _$StudentTokenImpl(
      {this.id,
      required this.businessId,
      required this.token,
      this.type = 'qr',
      this.studentId,
      this.batchId,
      this.secretHash,
      this.expiresAt,
      this.isActive = true,
      this.createdAt});

  factory _$StudentTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentTokenImplFromJson(json);

  @override
  final int? id;
  @override
  final int businessId;

  /// The opaque token embedded in the QR URL (`/public/qr/{token}/...`).
  @override
  final String token;

  /// Scope of the token: `student`, `batch` or `business`.
  @override
  @JsonKey()
  final String type;

  /// Set for `student` tokens; null for batch/business QR tokens that can
  /// list many student IDs.
  @override
  final int? studentId;

  /// Batch scope for `batch` tokens.
  @override
  final int? batchId;

  /// SHA-256 hash of the student login secret (null for QR-only tokens).
  @override
  final String? secretHash;
  @override
  final DateTime? expiresAt;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'StudentToken(id: $id, businessId: $businessId, token: $token, type: $type, studentId: $studentId, batchId: $batchId, secretHash: $secretHash, expiresAt: $expiresAt, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentTokenImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.batchId, batchId) || other.batchId == batchId) &&
            (identical(other.secretHash, secretHash) ||
                other.secretHash == secretHash) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, businessId, token, type,
      studentId, batchId, secretHash, expiresAt, isActive, createdAt);

  /// Create a copy of StudentToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentTokenImplCopyWith<_$StudentTokenImpl> get copyWith =>
      __$$StudentTokenImplCopyWithImpl<_$StudentTokenImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentTokenImplToJson(
      this,
    );
  }
}

abstract class _StudentToken implements StudentToken {
  const factory _StudentToken(
      {final int? id,
      required final int businessId,
      required final String token,
      final String type,
      final int? studentId,
      final int? batchId,
      final String? secretHash,
      final DateTime? expiresAt,
      final bool isActive,
      final DateTime? createdAt}) = _$StudentTokenImpl;

  factory _StudentToken.fromJson(Map<String, dynamic> json) =
      _$StudentTokenImpl.fromJson;

  @override
  int? get id;
  @override
  int get businessId;

  /// The opaque token embedded in the QR URL (`/public/qr/{token}/...`).
  @override
  String get token;

  /// Scope of the token: `student`, `batch` or `business`.
  @override
  String get type;

  /// Set for `student` tokens; null for batch/business QR tokens that can
  /// list many student IDs.
  @override
  int? get studentId;

  /// Batch scope for `batch` tokens.
  @override
  int? get batchId;

  /// SHA-256 hash of the student login secret (null for QR-only tokens).
  @override
  String? get secretHash;
  @override
  DateTime? get expiresAt;
  @override
  bool get isActive;
  @override
  DateTime? get createdAt;

  /// Create a copy of StudentToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudentTokenImplCopyWith<_$StudentTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
