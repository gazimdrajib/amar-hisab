// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'posting_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PostingTemplate _$PostingTemplateFromJson(Map<String, dynamic> json) {
  return _PostingTemplate.fromJson(json);
}

/// @nodoc
mixin _$PostingTemplate {
  int? get id => throw _privateConstructorUsedError;
  String get templateCode => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get businessId => throw _privateConstructorUsedError;

  /// Serializes this PostingTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostingTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostingTemplateCopyWith<PostingTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostingTemplateCopyWith<$Res> {
  factory $PostingTemplateCopyWith(
          PostingTemplate value, $Res Function(PostingTemplate) then) =
      _$PostingTemplateCopyWithImpl<$Res, PostingTemplate>;
  @useResult
  $Res call(
      {int? id, String templateCode, String? description, int businessId});
}

/// @nodoc
class _$PostingTemplateCopyWithImpl<$Res, $Val extends PostingTemplate>
    implements $PostingTemplateCopyWith<$Res> {
  _$PostingTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostingTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? templateCode = null,
    Object? description = freezed,
    Object? businessId = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      templateCode: null == templateCode
          ? _value.templateCode
          : templateCode // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostingTemplateImplCopyWith<$Res>
    implements $PostingTemplateCopyWith<$Res> {
  factory _$$PostingTemplateImplCopyWith(_$PostingTemplateImpl value,
          $Res Function(_$PostingTemplateImpl) then) =
      __$$PostingTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id, String templateCode, String? description, int businessId});
}

/// @nodoc
class __$$PostingTemplateImplCopyWithImpl<$Res>
    extends _$PostingTemplateCopyWithImpl<$Res, _$PostingTemplateImpl>
    implements _$$PostingTemplateImplCopyWith<$Res> {
  __$$PostingTemplateImplCopyWithImpl(
      _$PostingTemplateImpl _value, $Res Function(_$PostingTemplateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostingTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? templateCode = null,
    Object? description = freezed,
    Object? businessId = null,
  }) {
    return _then(_$PostingTemplateImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      templateCode: null == templateCode
          ? _value.templateCode
          : templateCode // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostingTemplateImpl implements _PostingTemplate {
  const _$PostingTemplateImpl(
      {this.id,
      required this.templateCode,
      this.description,
      required this.businessId});

  factory _$PostingTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostingTemplateImplFromJson(json);

  @override
  final int? id;
  @override
  final String templateCode;
  @override
  final String? description;
  @override
  final int businessId;

  @override
  String toString() {
    return 'PostingTemplate(id: $id, templateCode: $templateCode, description: $description, businessId: $businessId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostingTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateCode, templateCode) ||
                other.templateCode == templateCode) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, templateCode, description, businessId);

  /// Create a copy of PostingTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostingTemplateImplCopyWith<_$PostingTemplateImpl> get copyWith =>
      __$$PostingTemplateImplCopyWithImpl<_$PostingTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostingTemplateImplToJson(
      this,
    );
  }
}

abstract class _PostingTemplate implements PostingTemplate {
  const factory _PostingTemplate(
      {final int? id,
      required final String templateCode,
      final String? description,
      required final int businessId}) = _$PostingTemplateImpl;

  factory _PostingTemplate.fromJson(Map<String, dynamic> json) =
      _$PostingTemplateImpl.fromJson;

  @override
  int? get id;
  @override
  String get templateCode;
  @override
  String? get description;
  @override
  int get businessId;

  /// Create a copy of PostingTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostingTemplateImplCopyWith<_$PostingTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
