//
//  Generated code. Do not modify.
//  source: sync/v1/sync.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pushBatchRequestDescriptor instead')
const PushBatchRequest$json = {
  '1': 'PushBatchRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'last_synced_sequence', '3': 2, '4': 1, '5': 3, '10': 'lastSyncedSequence'},
    {'1': 'changes', '3': 3, '4': 3, '5': 11, '6': '.amarhisab.sync.v1.ChangeEvent', '10': 'changes'},
  ],
};

/// Descriptor for `PushBatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushBatchRequestDescriptor = $convert.base64Decode(
    'ChBQdXNoQmF0Y2hSZXF1ZXN0EhsKCWRldmljZV9pZBgBIAEoCVIIZGV2aWNlSWQSMAoUbGFzdF'
    '9zeW5jZWRfc2VxdWVuY2UYAiABKANSEmxhc3RTeW5jZWRTZXF1ZW5jZRI4CgdjaGFuZ2VzGAMg'
    'AygLMh4uYW1hcmhpc2FiLnN5bmMudjEuQ2hhbmdlRXZlbnRSB2NoYW5nZXM=');

@$core.Deprecated('Use pushBatchResponseDescriptor instead')
const PushBatchResponse$json = {
  '1': 'PushBatchResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'accepted_sequence', '3': 2, '4': 1, '5': 3, '10': 'acceptedSequence'},
    {'1': 'conflicts', '3': 3, '4': 3, '5': 11, '6': '.amarhisab.sync.v1.Conflict', '10': 'conflicts'},
  ],
};

/// Descriptor for `PushBatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushBatchResponseDescriptor = $convert.base64Decode(
    'ChFQdXNoQmF0Y2hSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEisKEWFjY2VwdG'
    'VkX3NlcXVlbmNlGAIgASgDUhBhY2NlcHRlZFNlcXVlbmNlEjkKCWNvbmZsaWN0cxgDIAMoCzIb'
    'LmFtYXJoaXNhYi5zeW5jLnYxLkNvbmZsaWN0Ugljb25mbGljdHM=');

@$core.Deprecated('Use conflictDescriptor instead')
const Conflict$json = {
  '1': 'Conflict',
  '2': [
    {'1': 'change_id', '3': 1, '4': 1, '5': 9, '10': 'changeId'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'local_version', '3': 3, '4': 1, '5': 12, '10': 'localVersion'},
    {'1': 'remote_version', '3': 4, '4': 1, '5': 12, '10': 'remoteVersion'},
  ],
};

/// Descriptor for `Conflict`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conflictDescriptor = $convert.base64Decode(
    'CghDb25mbGljdBIbCgljaGFuZ2VfaWQYASABKAlSCGNoYW5nZUlkEhYKBnJlYXNvbhgCIAEoCV'
    'IGcmVhc29uEiMKDWxvY2FsX3ZlcnNpb24YAyABKAxSDGxvY2FsVmVyc2lvbhIlCg5yZW1vdGVf'
    'dmVyc2lvbhgEIAEoDFINcmVtb3RlVmVyc2lvbg==');

@$core.Deprecated('Use pullRequestDescriptor instead')
const PullRequest$json = {
  '1': 'PullRequest',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'last_remote_sequence', '3': 2, '4': 1, '5': 3, '10': 'lastRemoteSequence'},
    {'1': 'business_id', '3': 3, '4': 1, '5': 9, '10': 'businessId'},
  ],
};

/// Descriptor for `PullRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pullRequestDescriptor = $convert.base64Decode(
    'CgtQdWxsUmVxdWVzdBIbCglkZXZpY2VfaWQYASABKAlSCGRldmljZUlkEjAKFGxhc3RfcmVtb3'
    'RlX3NlcXVlbmNlGAIgASgDUhJsYXN0UmVtb3RlU2VxdWVuY2USHwoLYnVzaW5lc3NfaWQYAyAB'
    'KAlSCmJ1c2luZXNzSWQ=');

@$core.Deprecated('Use changeEventDescriptor instead')
const ChangeEvent$json = {
  '1': 'ChangeEvent',
  '2': [
    {'1': 'change_id', '3': 1, '4': 1, '5': 9, '10': 'changeId'},
    {'1': 'entity_type', '3': 2, '4': 1, '5': 9, '10': 'entityType'},
    {'1': 'entity_id', '3': 3, '4': 1, '5': 3, '10': 'entityId'},
    {'1': 'operation', '3': 4, '4': 1, '5': 9, '10': 'operation'},
    {'1': 'payload', '3': 5, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'old_values', '3': 6, '4': 1, '5': 12, '10': 'oldValues'},
    {'1': 'timestamp_ms', '3': 7, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'sequence', '3': 8, '4': 1, '5': 3, '10': 'sequence'},
    {'1': 'device_id', '3': 9, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `ChangeEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeEventDescriptor = $convert.base64Decode(
    'CgtDaGFuZ2VFdmVudBIbCgljaGFuZ2VfaWQYASABKAlSCGNoYW5nZUlkEh8KC2VudGl0eV90eX'
    'BlGAIgASgJUgplbnRpdHlUeXBlEhsKCWVudGl0eV9pZBgDIAEoA1IIZW50aXR5SWQSHAoJb3Bl'
    'cmF0aW9uGAQgASgJUglvcGVyYXRpb24SGAoHcGF5bG9hZBgFIAEoDFIHcGF5bG9hZBIdCgpvbG'
    'RfdmFsdWVzGAYgASgMUglvbGRWYWx1ZXMSIQoMdGltZXN0YW1wX21zGAcgASgDUgt0aW1lc3Rh'
    'bXBNcxIaCghzZXF1ZW5jZRgIIAEoA1IIc2VxdWVuY2USGwoJZGV2aWNlX2lkGAkgASgJUghkZX'
    'ZpY2VJZA==');

