import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../../../../core/utils/request_extensions.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/middleware/auth_middleware.dart';
import '../../../../core/middleware/rbac_middleware.dart';
import '../../../../core/utils/response_envelope.dart';
import '../../application/services/journal_service.dart';
import '../../domain/entities/journal_line.dart';

/// REST controller for journal entries (Architecture Book Ã‚Â§13.5, Ã‚Â§14.2).
///
/// Routes (mounted under `/api/v1/accounting/journal/`):
///  * `POST /`            Ã¢â‚¬â€œ create draft journal  (`journal:create`)
///  * `GET  /`            Ã¢â‚¬â€œ list journals          (`journal:read`)
///  * `GET  /<id>`        Ã¢â‚¬â€œ journal detail         (`journal:read`)
///  * `POST /<id>/post`   Ã¢â‚¬â€œ post draft entry       (`journal:post`)
class JournalController {
  JournalController(this._service, this._checker);

  final JournalService _service;
  final PermissionChecker _checker;

  Router get router {
    final r = Router();
    r.post('/', requirePermission(_checker, 'journal', 'create')(_create));
    r.get('/', requirePermission(_checker, 'journal', 'read')(_list));
    r.get('/<id|[0-9]+>',
        requirePermission(_checker, 'journal', 'read')(
            (req) => _get(req, req.requiredParam('id'))));
    r.post('/<id|[0-9]+>/post',
        requirePermission(_checker, 'journal', 'post')(
            (req) => _post(req, req.requiredParam('id'))));
    return r;
  }

  Future<Response> _create(Request request) async {
    final auth = authContextOf(request)!;
    final body = await _jsonBody(request);
    if (body == null) return ResponseEnvelope.badRequest('Invalid JSON body');

    final rawLines = body['lines'];
    if (rawLines is! List || rawLines.isEmpty) {
      return ResponseEnvelope.badRequest(
          'Journal entry must contain a lines array');
    }
    double d(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final lines = <JournalLine>[
      for (final raw in rawLines)
        if (raw is Map)
          JournalLine(
            accountId: (raw['account_id'] as num?)?.toInt() ??
                (raw['accountId'] as num?)?.toInt() ??
                0,
            debit: d(raw['debit']),
            credit: d(raw['credit']),
            description: raw['description']?.toString(),
          ),
    ];
    if (lines.length != rawLines.length ||
        lines.any((l) => l.accountId == 0)) {
      return ResponseEnvelope.badRequest(
          'Every line requires a valid account_id');
    }

    final entryDate = DateTime.tryParse(
        '${body['entry_date'] ?? body['entryDate'] ?? ''}');
    if (entryDate == null) {
      return ResponseEnvelope.badRequest(
          'entry_date is required (ISO-8601)');
    }

    try {
      final entry = await _service.createJournal(
        businessId: auth.businessId,
        entryDate: entryDate,
        reference: body['reference']?.toString(),
        note: body['note']?.toString(),
        lines: lines,
        actorId: auth.userId,
      );
      return ResponseEnvelope.created(entry.toJson());
    } on JournalServiceException catch (e) {
      return _mapError(e);
    }
  }

  Future<Response> _list(Request request) async {
    final auth = authContextOf(request)!;
    final q = request.url.queryParameters;
    final entries = await _service.listJournals(
      auth.businessId,
      fromDate: q['from_date'] ?? q['fromDate'],
      toDate: q['to_date'] ?? q['toDate'],
      accountId: int.tryParse(q['account_id'] ?? q['accountId'] ?? ''),
      status: q['status'],
      limit: int.tryParse(q['limit'] ?? '') ?? 50,
      offset: int.tryParse(q['offset'] ?? '') ?? 0,
    );
    return ResponseEnvelope.success(
        entries.map((e) => e.toJson()).toList());
  }

  Future<Response> _get(Request request, String id) async {
    final auth = authContextOf(request)!;
    final detail =
        await _service.getJournal(auth.businessId, int.parse(id));
    if (detail == null) {
      return ResponseEnvelope.notFound('Journal entry not found');
    }
    return ResponseEnvelope.success(detail.toJson());
  }

  Future<Response> _post(Request request, String id) async {
    final auth = authContextOf(request)!;
    try {
      final posted = await _service.postJournal(
        businessId: auth.businessId,
        id: int.parse(id),
        actorId: auth.userId,
      );
      return ResponseEnvelope.success(posted.toJson());
    } on JournalServiceException catch (e) {
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

  Response _mapError(JournalServiceException e) {
    switch (e.code) {
      case 'not_found':
        return ResponseEnvelope.notFound(e.message);
      case 'already_posted':
        return ResponseEnvelope.conflict(e.message);
      case 'unbalanced':
      case 'empty_journal':
      case 'invalid_line':
      default:
        return ResponseEnvelope.badRequest(e.message);
    }
  }
}
