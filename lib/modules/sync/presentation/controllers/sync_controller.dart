import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/sync_engine.dart';

/// Operator-facing sync status endpoints.
///
///  * `GET /api/v1/sync/status` Ã¢â‚¬â€œ engine state, pending backlog, cursors.
///  * `POST /api/v1/sync/run`  Ã¢â‚¬â€œ trigger an immediate sync cycle.
///
/// RBAC: `settings:update` for the manual trigger; `audit_log:read` (Owner/
/// Admin) for status inspection.
class SyncController {
  SyncController(this._engine, this._checker);

  final SyncEngine _engine;
  final PermissionChecker _checker;

  Router get router {
    final router = Router()
      ..get('/status', requirePermission(_checker, 'audit_log', 'read')(_status))
      ..post('/run', requirePermission(_checker, 'settings', 'update')(_runNow));
    return router;
  }

  Future<Response> _status(Request request) async {
    authContextOf(request); // context enforced by middleware
    return ResponseEnvelope.success({
      'enabled': _engine.isConfigured,
      'status': _engine.status.name,
      'device_id': _engine.deviceId,
    });
  }

  Future<Response> _runNow(Request request) async {
    authContextOf(request);
    if (!_engine.isConfigured) {
      return ResponseEnvelope.error(
        'sync_disabled',
        'Cloud sync is not configured on this server (SYNC_ENABLED).',
        status: 503,
      );
    }
    final ok = await _engine.syncOnce();
    return ResponseEnvelope.success({'synced': ok});
  }
}
