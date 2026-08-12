import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/ledger_service.dart';

/// REST controller for financial reports (Architecture Book Ã‚Â§14.2).
///
/// Routes (mounted under `/api/v1/accounting/`):
///  * `GET /trial-balance`        Ã¢â‚¬â€œ trial balance       (`report:read`)
///  * `GET /profit-loss`          Ã¢â‚¬â€œ profit & loss        (`report:read`)
///  * `GET /balance-sheet`        Ã¢â‚¬â€œ balance sheet        (`report:read`)
///  * `GET /ledger/<accountId>`   Ã¢â‚¬â€œ account ledger       (`report:read`)
class LedgerController {
  LedgerController(this._service, this._checker);

  final LedgerService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.get('/trial-balance',
        requirePermission(_checker, 'report', 'read')(_trialBalance));
    r.get('/profit-loss',
        requirePermission(_checker, 'report', 'read')(_profitLoss));
    r.get('/balance-sheet',
        requirePermission(_checker, 'report', 'read')(_balanceSheet));
    r.get('/ledger/<accountId|[0-9]+>',
        requirePermission(_checker, 'report', 'read')(
            (req) => _ledger(req, req.requiredParam('accountId'))));
    return r;
  }

  Future<Response> _trialBalance(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final rows = await _service.getTrialBalance(
      auth.businessId,
      asOfDate: q['as_of_date'] ?? q['asOfDate'],
    );
    return ResponseEnvelope.success(rows);
  }

  Future<Response> _profitLoss(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final result = await _service.getProfitLoss(
      auth.businessId,
      fromDate: q['from_date'] ?? q['fromDate'],
      toDate: q['to_date'] ?? q['toDate'],
    );
    return ResponseEnvelope.success(result);
  }

  Future<Response> _balanceSheet(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final result = await _service.getBalanceSheet(
      auth.businessId,
      asOfDate: q['as_of_date'] ?? q['asOfDate'],
    );
    return ResponseEnvelope.success(result);
  }

  Future<Response> _ledger(Request request, String accountId) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final rows = await _service.getLedger(
      auth.businessId,
      int.parse(accountId),
      fromDate: q['from_date'] ?? q['fromDate'],
      toDate: q['to_date'] ?? q['toDate'],
    );
    return ResponseEnvelope.success(rows);
  }
}
