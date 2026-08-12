import 'dart:async';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../infrastructure/repositories/sync_repository.dart';
import '../../infrastructure/sync_client.dart';
import 'change_applier.dart';
import 'conflict_resolver.dart';

/// User-facing sync state (Architecture Book §17.2).
enum SyncEngineStatus { disabled, synced, syncing, offline, error }

/// Local side of the offline-first synchronisation protocol
/// (Architecture Book §17, Event Catalog §5).
///
///  * [syncOnce] – one push-then-pull cycle.
///  * [start] – periodic cycles (every [pushInterval], default 30 seconds)
///    with exponential backoff on failure: 5s, 25s, 125s … capped at 30 min
///    (Architecture Book §17.4).
///
/// Push: reads `change_log` rows with `sync_status = 'pending'` in sequence
/// order and ships them via [SyncClient.pushBatch]; accepted rows are marked
/// `synced`, conflicts `conflict`.
///
/// Pull: streams remote changes from the cloud and applies them through
/// [ChangeApplier]/[ConflictResolver]; after a clean pull the
/// `last_remote_sequence` cursor in `sync_state` advances.
class SyncEngine {
  SyncEngine({
    required Database db,
    required SyncClient client,
    required ChangeLogSource changeLog,
    String? businessId,
  })  : _client = client,
        _changeLog = changeLog,
        _syncRepository = SyncRepository(db),
        _applier = ChangeApplier(db, ConflictResolver(db), SyncRepository(db)),
        _businessId = businessId ?? _detectBusinessId(db);

  final SyncClient _client;
  final ChangeLogSource _changeLog;
  final SyncRepository _syncRepository;
  final ChangeApplier _applier;
  final String _businessId;

  Timer? _timer;
  bool _cycleRunning = false;

  /// Normal interval between sync cycles (Architecture Book §17.1).
  static const Duration pushInterval = Duration(seconds: 30);

  /// Base of the exponential backoff ladder: 5s → 25s → 125s …
  static const Duration _backoffBase = Duration(seconds: 5);

  /// Backoff cap (Architecture Book §17.4).
  static const Duration _backoffCap = Duration(minutes: 30);

  int _consecutiveFailures = 0;

  final _statusController = StreamController<SyncEngineStatus>.broadcast();
  SyncEngineStatus _status = SyncEngineStatus.disabled;

  /// Current engine status (drives the Settings → Cloud Sync indicator).
  SyncEngineStatus get status => _status;

  /// Status stream for UI listeners.
  Stream<SyncEngineStatus> get statusStream => _statusController.stream;

  String get deviceId => _changeLog.deviceId;

  bool get isConfigured =>
      SyncClient.isEnabled && _client.host.isNotEmpty;

  static String _detectBusinessId(Database db) {
    final rows = db.select('SELECT id FROM businesses ORDER BY id LIMIT 1;');
    final id = rows.isEmpty ? 1 : rows.first['id'] as int;
    return id.toString();
  }

  void _setStatus(SyncEngineStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  /// Start the periodic cycle. No-op when sync is not configured.
  void start() {
    if (!isConfigured || _timer != null) return;
    _setStatus(SyncEngineStatus.offline);
    // Kick off immediately, then on the interval.
    unawaited(syncOnce());
    _timer = Timer.periodic(pushInterval, (_) => unawaited(_maybeSync()));
  }

  Future<void> _maybeSync() async {
    final now = DateTime.now();
    if (_nextAttemptAt != null && now.isBefore(_nextAttemptAt!)) return;
    await syncOnce();
  }

  DateTime? _nextAttemptAt;

  /// One full cycle: push local changes, then pull remote changes.
  ///
  /// Returns `true` when both directions succeeded. Backoff scheduling:
  /// failure → wait 5s × 5^n (n = consecutive failures, capped at 30 min).
  Future<bool> syncOnce() async {
    if (!isConfigured) {
      _setStatus(SyncEngineStatus.disabled);
      return false;
    }
    if (_cycleRunning) return true; // re-entrancy guard
    _cycleRunning = true;
    _setStatus(SyncEngineStatus.syncing);
    try {
      final pushed = await pushChanges();
      final pulled = await pullChanges();
      _consecutiveFailures = 0;
      _nextAttemptAt = null;
      _setStatus(SyncEngineStatus.synced);
      return pushed && pulled;
    } on SyncClientException catch (e) {
      stderr.writeln('[sync] ${e.transient ? "transient" : "permanent"} '
          'error: ${e.message}');
      _scheduleBackoff();
      _setStatus(e.transient ? SyncEngineStatus.offline : SyncEngineStatus.error);
      return false;
    } catch (e) {
      stderr.writeln('[sync] unexpected error: $e');
      _scheduleBackoff();
      _setStatus(SyncEngineStatus.error);
      return false;
    } finally {
      _cycleRunning = false;
    }
  }

  void _scheduleBackoff() {
    final exponent = _consecutiveFailures.clamp(0, 10);
    // 5s, 25s, 125s, … = 5s × 5^n (Architecture Book §17.4).
    var delay =
        Duration(milliseconds: _backoffBase.inMilliseconds * _pow5(exponent));
    if (delay > _backoffCap) delay = _backoffCap;
    _consecutiveFailures++;
    _nextAttemptAt = DateTime.now().add(delay);
  }

  static int _pow5(int n) {
    var value = 1;
    for (var i = 0; i < n && value < 2000000; i++) {
      value *= 5;
    }
    return value;
  }

  /// Collect pending changes, batch them and push to the cloud
  /// (Event Catalog §5.1 step 4).
  Future<bool> pushChanges() async {
    final deviceId = _client.deviceId.isNotEmpty
        ? _client.deviceId
        : _changeLog.deviceId;
    final batch = _syncRepository.pendingChanges(deviceId, limit: 500);
    if (batch.isEmpty) return true;

    final lastSynced = _syncRepository.lastSyncedSequence(deviceId);
    final response = await _client.pushBatch(
      deviceId: deviceId,
      lastSyncedSequence: lastSynced,
      changes: batch,
    );

    if (response.success) {
      _syncRepository.markChangesSynced(
          batch.map((row) => row['change_id'] as String));
      final maxSequence = batch.fold<int>(
          0, (m, row) => (row['sequence'] as int) > m ? row['sequence'] as int : m);
      final accepted = response.acceptedSequence.toInt();
      if (accepted > 0) {
        _syncRepository.savePushCursor(
            deviceId, accepted > maxSequence ? accepted : maxSequence);
      } else {
        _syncRepository.savePushCursor(deviceId, maxSequence);
      }
    }
    if (response.conflicts.isNotEmpty) {
      _syncRepository.markChangesConflict(
          response.conflicts.map((c) => c.changeId));
    }
    return response.success;
  }

  /// Pull remote changes and apply them locally (Event Catalog §5.2).
  Future<bool> pullChanges() async {
    final deviceId = _client.deviceId.isNotEmpty
        ? _client.deviceId
        : _changeLog.deviceId;
    final cursor = _syncRepository.lastRemoteSequence(deviceId);
    var maxApplied = cursor;

    final stream = _client.pullChanges(
      deviceId: deviceId,
      lastRemoteSequence: cursor,
      businessId: _businessId,
    );

    await for (final event in stream) {
      final remote = remoteChangeFromEvent(event,
          businessId: int.tryParse(_businessId) ?? 1);
      _applier.apply(remote);
      final seq = event.sequence.toInt();
      if (seq > maxApplied) maxApplied = seq;
    }

    if (maxApplied > cursor) {
      _syncRepository.saveRemoteCursor(deviceId, maxApplied);
    }
    return true;
  }

  /// Stop the periodic timer and release resources.
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    if (!_statusController.isClosed) await _statusController.close();
  }
}

/// Minimal surface of [ChangeLogService] the engine needs (keeps the engine
/// testable without dragging in the whole service).
abstract class ChangeLogSource {
  String get deviceId;
}
