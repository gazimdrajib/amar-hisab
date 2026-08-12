//
//  Generated code. Do not modify.
//  source: sync/v1/sync.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class PushBatchRequest extends $pb.GeneratedMessage {
  factory PushBatchRequest({
    $core.String? deviceId,
    $fixnum.Int64? lastSyncedSequence,
    $core.Iterable<ChangeEvent>? changes,
  }) {
    final $result = create();
    if (deviceId != null) {
      $result.deviceId = deviceId;
    }
    if (lastSyncedSequence != null) {
      $result.lastSyncedSequence = lastSyncedSequence;
    }
    if (changes != null) {
      $result.changes.addAll(changes);
    }
    return $result;
  }
  PushBatchRequest._() : super();
  factory PushBatchRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PushBatchRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PushBatchRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'amarhisab.sync.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aInt64(2, _omitFieldNames ? '' : 'lastSyncedSequence')
    ..pc<ChangeEvent>(3, _omitFieldNames ? '' : 'changes', $pb.PbFieldType.PM, subBuilder: ChangeEvent.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PushBatchRequest clone() => PushBatchRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PushBatchRequest copyWith(void Function(PushBatchRequest) updates) => super.copyWith((message) => updates(message as PushBatchRequest)) as PushBatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushBatchRequest create() => PushBatchRequest._();
  PushBatchRequest createEmptyInstance() => create();
  static $pb.PbList<PushBatchRequest> createRepeated() => $pb.PbList<PushBatchRequest>();
  @$core.pragma('dart2js:noInline')
  static PushBatchRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushBatchRequest>(create);
  static PushBatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastSyncedSequence => $_getI64(1);
  @$pb.TagNumber(2)
  set lastSyncedSequence($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLastSyncedSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastSyncedSequence() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<ChangeEvent> get changes => $_getList(2);
}

class PushBatchResponse extends $pb.GeneratedMessage {
  factory PushBatchResponse({
    $core.bool? success,
    $fixnum.Int64? acceptedSequence,
    $core.Iterable<Conflict>? conflicts,
  }) {
    final $result = create();
    if (success != null) {
      $result.success = success;
    }
    if (acceptedSequence != null) {
      $result.acceptedSequence = acceptedSequence;
    }
    if (conflicts != null) {
      $result.conflicts.addAll(conflicts);
    }
    return $result;
  }
  PushBatchResponse._() : super();
  factory PushBatchResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PushBatchResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PushBatchResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'amarhisab.sync.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aInt64(2, _omitFieldNames ? '' : 'acceptedSequence')
    ..pc<Conflict>(3, _omitFieldNames ? '' : 'conflicts', $pb.PbFieldType.PM, subBuilder: Conflict.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PushBatchResponse clone() => PushBatchResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PushBatchResponse copyWith(void Function(PushBatchResponse) updates) => super.copyWith((message) => updates(message as PushBatchResponse)) as PushBatchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushBatchResponse create() => PushBatchResponse._();
  PushBatchResponse createEmptyInstance() => create();
  static $pb.PbList<PushBatchResponse> createRepeated() => $pb.PbList<PushBatchResponse>();
  @$core.pragma('dart2js:noInline')
  static PushBatchResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushBatchResponse>(create);
  static PushBatchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get acceptedSequence => $_getI64(1);
  @$pb.TagNumber(2)
  set acceptedSequence($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAcceptedSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearAcceptedSequence() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<Conflict> get conflicts => $_getList(2);
}

class Conflict extends $pb.GeneratedMessage {
  factory Conflict({
    $core.String? changeId,
    $core.String? reason,
    $core.List<$core.int>? localVersion,
    $core.List<$core.int>? remoteVersion,
  }) {
    final $result = create();
    if (changeId != null) {
      $result.changeId = changeId;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    if (localVersion != null) {
      $result.localVersion = localVersion;
    }
    if (remoteVersion != null) {
      $result.remoteVersion = remoteVersion;
    }
    return $result;
  }
  Conflict._() : super();
  factory Conflict.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Conflict.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Conflict', package: const $pb.PackageName(_omitMessageNames ? '' : 'amarhisab.sync.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'changeId')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'localVersion', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'remoteVersion', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Conflict clone() => Conflict()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Conflict copyWith(void Function(Conflict) updates) => super.copyWith((message) => updates(message as Conflict)) as Conflict;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Conflict create() => Conflict._();
  Conflict createEmptyInstance() => create();
  static $pb.PbList<Conflict> createRepeated() => $pb.PbList<Conflict>();
  @$core.pragma('dart2js:noInline')
  static Conflict getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Conflict>(create);
  static Conflict? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get changeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set changeId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChangeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChangeId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get localVersion => $_getN(2);
  @$pb.TagNumber(3)
  set localVersion($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLocalVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocalVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get remoteVersion => $_getN(3);
  @$pb.TagNumber(4)
  set remoteVersion($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRemoteVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearRemoteVersion() => clearField(4);
}

class PullRequest extends $pb.GeneratedMessage {
  factory PullRequest({
    $core.String? deviceId,
    $fixnum.Int64? lastRemoteSequence,
    $core.String? businessId,
  }) {
    final $result = create();
    if (deviceId != null) {
      $result.deviceId = deviceId;
    }
    if (lastRemoteSequence != null) {
      $result.lastRemoteSequence = lastRemoteSequence;
    }
    if (businessId != null) {
      $result.businessId = businessId;
    }
    return $result;
  }
  PullRequest._() : super();
  factory PullRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PullRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PullRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'amarhisab.sync.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aInt64(2, _omitFieldNames ? '' : 'lastRemoteSequence')
    ..aOS(3, _omitFieldNames ? '' : 'businessId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PullRequest clone() => PullRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PullRequest copyWith(void Function(PullRequest) updates) => super.copyWith((message) => updates(message as PullRequest)) as PullRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullRequest create() => PullRequest._();
  PullRequest createEmptyInstance() => create();
  static $pb.PbList<PullRequest> createRepeated() => $pb.PbList<PullRequest>();
  @$core.pragma('dart2js:noInline')
  static PullRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PullRequest>(create);
  static PullRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastRemoteSequence => $_getI64(1);
  @$pb.TagNumber(2)
  set lastRemoteSequence($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLastRemoteSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastRemoteSequence() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get businessId => $_getSZ(2);
  @$pb.TagNumber(3)
  set businessId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBusinessId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBusinessId() => clearField(3);
}

class ChangeEvent extends $pb.GeneratedMessage {
  factory ChangeEvent({
    $core.String? changeId,
    $core.String? entityType,
    $fixnum.Int64? entityId,
    $core.String? operation,
    $core.List<$core.int>? payload,
    $core.List<$core.int>? oldValues,
    $fixnum.Int64? timestampMs,
    $fixnum.Int64? sequence,
    $core.String? deviceId,
  }) {
    final $result = create();
    if (changeId != null) {
      $result.changeId = changeId;
    }
    if (entityType != null) {
      $result.entityType = entityType;
    }
    if (entityId != null) {
      $result.entityId = entityId;
    }
    if (operation != null) {
      $result.operation = operation;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    if (oldValues != null) {
      $result.oldValues = oldValues;
    }
    if (timestampMs != null) {
      $result.timestampMs = timestampMs;
    }
    if (sequence != null) {
      $result.sequence = sequence;
    }
    if (deviceId != null) {
      $result.deviceId = deviceId;
    }
    return $result;
  }
  ChangeEvent._() : super();
  factory ChangeEvent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChangeEvent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChangeEvent', package: const $pb.PackageName(_omitMessageNames ? '' : 'amarhisab.sync.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'changeId')
    ..aOS(2, _omitFieldNames ? '' : 'entityType')
    ..aInt64(3, _omitFieldNames ? '' : 'entityId')
    ..aOS(4, _omitFieldNames ? '' : 'operation')
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'oldValues', $pb.PbFieldType.OY)
    ..aInt64(7, _omitFieldNames ? '' : 'timestampMs')
    ..aInt64(8, _omitFieldNames ? '' : 'sequence')
    ..aOS(9, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChangeEvent clone() => ChangeEvent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChangeEvent copyWith(void Function(ChangeEvent) updates) => super.copyWith((message) => updates(message as ChangeEvent)) as ChangeEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangeEvent create() => ChangeEvent._();
  ChangeEvent createEmptyInstance() => create();
  static $pb.PbList<ChangeEvent> createRepeated() => $pb.PbList<ChangeEvent>();
  @$core.pragma('dart2js:noInline')
  static ChangeEvent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChangeEvent>(create);
  static ChangeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get changeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set changeId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChangeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChangeId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get entityType => $_getSZ(1);
  @$pb.TagNumber(2)
  set entityType($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEntityType() => $_has(1);
  @$pb.TagNumber(2)
  void clearEntityType() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get entityId => $_getI64(2);
  @$pb.TagNumber(3)
  set entityId($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEntityId() => $_has(2);
  @$pb.TagNumber(3)
  void clearEntityId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get operation => $_getSZ(3);
  @$pb.TagNumber(4)
  set operation($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasOperation() => $_has(3);
  @$pb.TagNumber(4)
  void clearOperation() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get payload => $_getN(4);
  @$pb.TagNumber(5)
  set payload($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayload() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get oldValues => $_getN(5);
  @$pb.TagNumber(6)
  set oldValues($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasOldValues() => $_has(5);
  @$pb.TagNumber(6)
  void clearOldValues() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get timestampMs => $_getI64(6);
  @$pb.TagNumber(7)
  set timestampMs($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasTimestampMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimestampMs() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sequence => $_getI64(7);
  @$pb.TagNumber(8)
  set sequence($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasSequence() => $_has(7);
  @$pb.TagNumber(8)
  void clearSequence() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get deviceId => $_getSZ(8);
  @$pb.TagNumber(9)
  set deviceId($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDeviceId() => $_has(8);
  @$pb.TagNumber(9)
  void clearDeviceId() => clearField(9);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
