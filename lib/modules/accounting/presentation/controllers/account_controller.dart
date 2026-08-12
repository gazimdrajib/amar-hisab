import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/account_service.dart';

/// REST controller for the chart of accounts (Architecture Book Ã‚Â§14.2).
///
/// Routes (mounted under `/api/v1/accounting/accounts/`):
///  * `POST   /`      Ã¢â‚¬â€œ create account  (`account:create`)
///  * `GET    /`      Ã¢â‚¬â€œ list accounts   (`account:read`)
///  * `GET    /<id>`  Ã¢â‚¬â€œ account detail  (`account:read`)
///  * `PUT    /<id>`  Ã¢â‚¬â€œ update account  (`account:update`)
///  * `DELETE /<id>`  Ã¢â‚¬â€œ soft delete     (`account:delete`)
class AccountController {
  AccountController(this._service, this._checker);

  final AccountService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.post('/', requirePermission(_checker, 'account', 'create')(_create));
    r.get('/', requirePermission(_checker, 'account', 'read')(_list));
    r.get('/<id|[0-9]+>',
        requirePermission(_checker, 'account', 'read')(
            (req) => _get(req, req.requiredParam('id'))));
    r.put('/<id|[0-9]+>',
        requirePermission(_checker, 'account', 'update')(
            (req) => _update(req, req.requiredParam('id'))));
    r.delete('/<id|[0-9]+>',
        requirePermission(_checker, 'account', 'delete')(
            (req) => _delete(req, req.requiredParam('id'))));
    return r;
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');

    final code = (body['account_code'] ?? body['accountCode'])?.toString();
    final name = (body['account_name'] ?? body['accountName'])?.toString();
    final type = (body['account_type'] ?? body['accountType'])?.toString();
    if (code == null || code.isEmpty) {
      return ResponseEnvelope.badRequest('account_code is required');
    }
    if (name == null || name.isEmpty) {
      return ResponseEnvelope.badRequest('account_name is required');
    }
    if (type == null || type.isEmpty) {
      return ResponseEnvelope.badRequest('account_type is required');
    }

    try {
      final account = await _service.createAccount(
        businessId: auth.businessId,
        accountCode: code,
        accountName: name,
        accountType: type,
        parentId: (body['parent_id'] as num?)?.toInt() ??
            (body['parentId'] as num?)?.toInt(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(account.toJson());
    } on AccountServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final accounts = await _service.listAccounts(
      auth.businessId,
      accountType: q['account_type'] ?? q['accountType'],
      activeOnly: q['active_only'] == null && q['activeOnly'] == null
          ? null
          : (q['active_only'] ?? q['activeOnly']) == 'true',
    );
    return ResponseEnvelope.success(
        accounts.map((a) => a.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      final account =
          await _service.getAccount(auth.businessId, int.parse(id));
      return ResponseEnvelope.success(account.toJson());
    } on AccountServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _update(Request request, String id) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');

    try {
      final account = await _service.updateAccount(
        businessId: auth.businessId,
        id: int.parse(id),
        accountName:
            (body['account_name'] ?? body['accountName'])?.toString(),
        accountType:
            (body['account_type'] ?? body['accountType'])?.toString(),
        parentId: (body['parent_id'] as num?)?.toInt() ??
            (body['parentId'] as num?)?.toInt(),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(account.toJson());
    } on AccountServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _delete(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      await _service.deleteAccount(
        businessId: auth.businessId,
        id: int.parse(id),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(null, message: 'Account deactivated');
    } on AccountServiceException catch (e) {
      return _mapError(e);
    }
  }

  // -- Helpers ---------------------------------------------------------------

  Future<Map<String, dynamic>?> _jsonBody(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Response _mapError(AccountServiceException e) {
    switch (e.code) {
      case 'not_found':
        return ResponseEnvelope.notFound(e.message);
      case 'duplicate_code':
      case 'system_account':
        return ResponseEnvelope.conflict(e.message);
      default:
        return ResponseEnvelope.badRequest(e.message);
    }
  }
}
