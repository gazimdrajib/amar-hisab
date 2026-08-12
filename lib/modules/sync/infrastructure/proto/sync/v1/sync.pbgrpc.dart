//
//  Generated code. Do not modify.
//  source: sync/v1/sync.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'sync.pb.dart' as $0;

export 'sync.pb.dart';

@$pb.GrpcServiceName('amarhisab.sync.v1.SyncService')
class SyncServiceClient extends $grpc.Client {
  static final _$pushBatch = $grpc.ClientMethod<$0.PushBatchRequest, $0.PushBatchResponse>(
      '/amarhisab.sync.v1.SyncService/PushBatch',
      ($0.PushBatchRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PushBatchResponse.fromBuffer(value));
  static final _$pullChanges = $grpc.ClientMethod<$0.PullRequest, $0.ChangeEvent>(
      '/amarhisab.sync.v1.SyncService/PullChanges',
      ($0.PullRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChangeEvent.fromBuffer(value));
  static final _$syncStream = $grpc.ClientMethod<$0.ChangeEvent, $0.ChangeEvent>(
      '/amarhisab.sync.v1.SyncService/SyncStream',
      ($0.ChangeEvent value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChangeEvent.fromBuffer(value));

  SyncServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.PushBatchResponse> pushBatch($0.PushBatchRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$pushBatch, request, options: options);
  }

  $grpc.ResponseStream<$0.ChangeEvent> pullChanges($0.PullRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$pullChanges, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseStream<$0.ChangeEvent> syncStream($async.Stream<$0.ChangeEvent> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$syncStream, request, options: options);
  }
}

@$pb.GrpcServiceName('amarhisab.sync.v1.SyncService')
abstract class SyncServiceBase extends $grpc.Service {
  $core.String get $name => 'amarhisab.sync.v1.SyncService';

  SyncServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PushBatchRequest, $0.PushBatchResponse>(
        'PushBatch',
        pushBatch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PushBatchRequest.fromBuffer(value),
        ($0.PushBatchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PullRequest, $0.ChangeEvent>(
        'PullChanges',
        pullChanges_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.PullRequest.fromBuffer(value),
        ($0.ChangeEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangeEvent, $0.ChangeEvent>(
        'SyncStream',
        syncStream,
        true,
        true,
        ($core.List<$core.int> value) => $0.ChangeEvent.fromBuffer(value),
        ($0.ChangeEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.PushBatchResponse> pushBatch_Pre($grpc.ServiceCall call, $async.Future<$0.PushBatchRequest> request) async {
    return pushBatch(call, await request);
  }

  $async.Stream<$0.ChangeEvent> pullChanges_Pre($grpc.ServiceCall call, $async.Future<$0.PullRequest> request) async* {
    yield* pullChanges(call, await request);
  }

  $async.Future<$0.PushBatchResponse> pushBatch($grpc.ServiceCall call, $0.PushBatchRequest request);
  $async.Stream<$0.ChangeEvent> pullChanges($grpc.ServiceCall call, $0.PullRequest request);
  $async.Stream<$0.ChangeEvent> syncStream($grpc.ServiceCall call, $async.Stream<$0.ChangeEvent> request);
}
