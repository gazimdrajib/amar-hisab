// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_line.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

JournalLine _$JournalLineFromJson(Map<String, dynamic> json) {
  return _JournalLine.fromJson(json);
}

/// @nodoc
mixin _$JournalLine {
  int? get id => throw _privateConstructorUsedError;
  int? get journalEntryId => throw _privateConstructorUsedError;
  int get accountId => throw _privateConstructorUsedError;
  double get debit => throw _privateConstructorUsedError;
  double get credit => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this JournalLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JournalLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalLineCopyWith<JournalLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalLineCopyWith<$Res> {
  factory $JournalLineCopyWith(
          JournalLine value, $Res Function(JournalLine) then) =
      _$JournalLineCopyWithImpl<$Res, JournalLine>;
  @useResult
  $Res call(
      {int? id,
      int? journalEntryId,
      int accountId,
      double debit,
      double credit,
      String? description});
}

/// @nodoc
class _$JournalLineCopyWithImpl<$Res, $Val extends JournalLine>
    implements $JournalLineCopyWith<$Res> {
  _$JournalLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? journalEntryId = freezed,
    Object? accountId = null,
    Object? debit = null,
    Object? credit = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      journalEntryId: freezed == journalEntryId
          ? _value.journalEntryId
          : journalEntryId // ignore: cast_nullable_to_non_nullable
              as int?,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as int,
      debit: null == debit
          ? _value.debit
          : debit // ignore: cast_nullable_to_non_nullable
              as double,
      credit: null == credit
          ? _value.credit
          : credit // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JournalLineImplCopyWith<$Res>
    implements $JournalLineCopyWith<$Res> {
  factory _$$JournalLineImplCopyWith(
          _$JournalLineImpl value, $Res Function(_$JournalLineImpl) then) =
      __$$JournalLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      int? journalEntryId,
      int accountId,
      double debit,
      double credit,
      String? description});
}

/// @nodoc
class __$$JournalLineImplCopyWithImpl<$Res>
    extends _$JournalLineCopyWithImpl<$Res, _$JournalLineImpl>
    implements _$$JournalLineImplCopyWith<$Res> {
  __$$JournalLineImplCopyWithImpl(
      _$JournalLineImpl _value, $Res Function(_$JournalLineImpl) _then)
      : super(_value, _then);

  /// Create a copy of JournalLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? journalEntryId = freezed,
    Object? accountId = null,
    Object? debit = null,
    Object? credit = null,
    Object? description = freezed,
  }) {
    return _then(_$JournalLineImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      journalEntryId: freezed == journalEntryId
          ? _value.journalEntryId
          : journalEntryId // ignore: cast_nullable_to_non_nullable
              as int?,
      accountId: null == accountId
          ? _value.accountId
          : accountId // ignore: cast_nullable_to_non_nullable
              as int,
      debit: null == debit
          ? _value.debit
          : debit // ignore: cast_nullable_to_non_nullable
              as double,
      credit: null == credit
          ? _value.credit
          : credit // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JournalLineImpl implements _JournalLine {
  const _$JournalLineImpl(
      {this.id,
      this.journalEntryId,
      required this.accountId,
      this.debit = 0,
      this.credit = 0,
      this.description});

  factory _$JournalLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$JournalLineImplFromJson(json);

  @override
  final int? id;
  @override
  final int? journalEntryId;
  @override
  final int accountId;
  @override
  @JsonKey()
  final double debit;
  @override
  @JsonKey()
  final double credit;
  @override
  final String? description;

  @override
  String toString() {
    return 'JournalLine(id: $id, journalEntryId: $journalEntryId, accountId: $accountId, debit: $debit, credit: $credit, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalLineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.journalEntryId, journalEntryId) ||
                other.journalEntryId == journalEntryId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.debit, debit) || other.debit == debit) &&
            (identical(other.credit, credit) || other.credit == credit) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, journalEntryId, accountId, debit, credit, description);

  /// Create a copy of JournalLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalLineImplCopyWith<_$JournalLineImpl> get copyWith =>
      __$$JournalLineImplCopyWithImpl<_$JournalLineImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JournalLineImplToJson(
      this,
    );
  }
}

abstract class _JournalLine implements JournalLine {
  const factory _JournalLine(
      {final int? id,
      final int? journalEntryId,
      required final int accountId,
      final double debit,
      final double credit,
      final String? description}) = _$JournalLineImpl;

  factory _JournalLine.fromJson(Map<String, dynamic> json) =
      _$JournalLineImpl.fromJson;

  @override
  int? get id;
  @override
  int? get journalEntryId;
  @override
  int get accountId;
  @override
  double get debit;
  @override
  double get credit;
  @override
  String? get description;

  /// Create a copy of JournalLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalLineImplCopyWith<_$JournalLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
