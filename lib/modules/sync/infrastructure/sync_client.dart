import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:grpc/grpc.dart';

import 'proto/sync/v1/sync.pbgrpc.dart' as pb;
import 'repositories/sync_repository.dart';

/// Converts one local outbox row to the wire format (Proto Book §4.1).
pb.ChangeEvent changeEventFromRow(Map<String, Object?> row) {
  final payload = row['payload'] as String?;
  final oldValues = row['old_values'] as String?;
  return pb.ChangeEvent(
    changeId: row['change_id'] as String,
    entityType: row['entity_type'] as String,
    entityId: fixnum.Int64((row['entity_id'] as num).toInt()),
    operation: row['operation'] as String,
    payload: payload == null ? const <int>[] : utf8.encode(payload),
    oldValues: oldValues == null ? const <int>[] : utf8.encode(oldValues),
    timestampMs: fixnum.Int64((row['timestamp_ms'] as num).toInt()),
    sequence: fixnum.Int64((row['sequence'] as num).toInt()),
    deviceId: row['device_id'] as String,
  );
}

/// Converts a wire `ChangeEvent` to the [RemoteChange] the applier expects.
RemoteChange remoteChangeFromEvent(pb.ChangeEvent event,
    {required int businessId}) {
  return RemoteChange(
    changeId: event.changeId,
    entityType: event.entityType,
    entityId: event.entityId.toInt(),
    operation: event.operation,
    payload: event.payload.isEmpty ? null : utf8.decode(event.payload),
    oldValues:
        event.oldValues.isEmpty ? null : utf8.decode(event.oldValues),
    timestampMs: event.timestampMs.toInt(),
    sequence: event.sequence.toInt(),
    deviceId: event.deviceId,
    businessId: businessId,
  );
}

/// Error raised by [SyncClient]. [transient] drives the engine's backoff:
/// transient failures retry; permanent ones (auth, malformed proto) stop the
/// cycle until configuration changes.
class SyncClientException implements Exception {
  const SyncClientException(this.message, {this.transient = true});

  final String message;
  final bool transient;

  @override
  String toString() =>
      'SyncClientException(transient: $transient): $message';
}

/// ChannelCredentials variant that exposes a caller-built [SecurityContext]
/// (the only way package:grpc 3.x presents a client certificate during the
/// TLS handshake – it reads `credentials.securityContext`).
class _MtlsChannelCredentials extends ChannelCredentials {
  _MtlsChannelCredentials(this._context)
      : super.secure(authority: null, onBadCertificate: null);

  final SecurityContext _context;

  @override
  SecurityContext? get securityContext => _context;
}

/// gRPC client for the Cloud Sync Service (Proto Contract Book §4).
///
/// The channel is secured with TLS 1.2+ (TLS 1.3 preferred) and each call
/// authenticates with a device JWT in the `authorization` metadata, or with
/// mTLS when `SYNC_CLIENT_CERT_PATH`/`SYNC_CLIENT_KEY_PATH` are provided
/// (Architecture Book §10.3: the local server verifies the cloud certificate
/// against the public CA; device identity is carried by JWT or client cert).
class SyncClient {
  SyncClient({
    String? host,
    int? port,
    String? deviceId,
    String? deviceToken,
  })  : host = host ?? Platform.environment['SYNC_HOST'] ?? '',
        port = port ??
            int.tryParse(Platform.environment['SYNC_PORT'] ?? '') ??
            443,
        deviceId = deviceId ?? '',
        deviceToken = deviceToken ??
            Platform.environment['SYNC_DEVICE_TOKEN'] ??
            '';

  /// Whether sync is configured at all. Sync is skipped when disabled or when
  /// no host is set (Architecture Book §6.4: entirely optional).
  static bool get isEnabled {
    final enabled = (Platform.environment['SYNC_ENABLED'] ?? '').toLowerCase();
    return enabled == 'true' || enabled == '1';
  }

  final String host;
  final int port;
  final String deviceId;

  /// Device JWT obtained from the cloud account portal (env
  /// `SYNC_DEVICE_TOKEN`). Never hard-coded.
  final String deviceToken;

  ClientChannel? _channel;
  pb.SyncServiceClient? _stub;

  pb.SyncServiceClient get _client {
    final channel = _channel ??= _buildChannel();
    return _stub ??= pb.SyncServiceClient(channel);
  }

  ClientChannel _buildChannel() {
    final certPath = Platform.environment['SYNC_CLIENT_CERT_PATH'];
    final keyPath = Platform.environment['SYNC_CLIENT_KEY_PATH'];
    final trustedRootsPath = Platform.environment['SYNC_CA_CERT_PATH'];

    ChannelCredentials credentials;
    if (certPath != null &&
        certPath.isNotEmpty &&
        keyPath != null &&
        keyPath.isNotEmpty) {
      // ── mTLS: device certificate + private key (Architecture Book §10.3).
      //
      // package:grpc 3.x does not support a private key directly on
      // ChannelCredentials.secure(), so we build a full SecurityContext
      // ourselves and expose it through a ChannelCredentials subclass –
      // ClientChannel reads `credentials.securityContext` for the TLS
      // handshake, so the client certificate IS presented (real mTLS).
      final context = SecurityContext();
      if (trustedRootsPath != null && trustedRootsPath.isNotEmpty) {
        context.setTrustedCertificates(trustedRootsPath);
      } else {
        context.setTrustedCertificatesBytes(
            File(Platform.environment['SYNC_CA_CERT_PATH'] ?? certPath)
                .readAsBytesSync());
      }
      context.useCertificateChain(certPath);
      context.usePrivateKey(keyPath);
      context.setAlpnProtocols(const ['h2'], false);
      credentials = _MtlsChannelCredentials(context);
    } else {
      // Server-only TLS (CA trust) + device JWT metadata auth.
      credentials = trustedRootsPath != null && trustedRootsPath.isNotEmpty
          ? ChannelCredentials.secure(
              certificates: File(trustedRootsPath).readAsBytesSync())
          : const ChannelCredentials.secure();
    }

    return ClientChannel(
      host,
      port: port,
      options: ChannelOptions(credentials: credentials),
    );
  }

  Map<String, String> get _metadata => {
        if (deviceToken.isNotEmpty) 'authorization': 'Bearer $deviceToken',
        if (deviceId.isNotEmpty) 'x-device-id': deviceId,
      };

  /// Push an ordered batch of pending changes (Proto Book §4.1).
  Future<pb.PushBatchResponse> pushBatch({
    required String deviceId,
    required int lastSyncedSequence,
    required List<Map<String, Object?>> changes,
  }) async {
    try {
      final request = pb.PushBatchRequest(
        deviceId: deviceId,
        lastSyncedSequence: fixnum.Int64(lastSyncedSequence),
        changes: changes.map(changeEventFromRow),
      );
      return await _client.pushBatch(request,
          options: CallOptions(metadata: _metadata));
    } on GrpcError catch (e) {
      throw _toClientException(e);
    }
  }

  /// Stream of remote changes with `sequence > lastRemoteSequence`.
  Stream<pb.ChangeEvent> pullChanges({
    required String deviceId,
    required int lastRemoteSequence,
    required String businessId,
  }) {
    try {
      final request = pb.PullRequest(
        deviceId: deviceId,
        lastRemoteSequence: fixnum.Int64(lastRemoteSequence),
        businessId: businessId,
      );
      return _client.pullChanges(request,
          options: CallOptions(metadata: _metadata));
    } on GrpcError catch (e) {
      throw _toClientException(e);
    }
  }

  SyncClientException _toClientException(GrpcError e) {
    final transient = switch (e.code) {
      StatusCode.unavailable ||
      StatusCode.deadlineExceeded ||
      StatusCode.resourceExhausted ||
      StatusCode.aborted ||
      StatusCode.internal =>
        true,
      _ => false,
    };
    return SyncClientException(
      'gRPC ${e.codeName}: ${e.message}',
      transient: transient,
    );
  }

  Future<void> dispose() async {
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
  }
}
