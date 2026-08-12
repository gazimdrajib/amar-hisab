import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Consistent JSON response envelope helpers used by every controller.
///
/// * Success: `{ "success": true, "data": ... }` (optional `message`).
/// * Error:   `{ "success": false, "error": { "code": ..., "message": ..., "details": ... } }`.
class ResponseEnvelope {
  ResponseEnvelope._();

  static const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

  static Response success(dynamic data, {String? message, int status = 200}) {
    final body = <String, dynamic>{
      'success': true,
      if (message != null) 'message': message,
      'data': data,
    };
    return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
  }

  static Response created(dynamic data, {String? message}) =>
      success(data, message: message, status: 201);

  static Response error(
    String code,
    String message, {
    int status = 400,
    dynamic details,
  }) {
    final body = <String, dynamic>{
      'success': false,
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
    };
    return Response(status, body: jsonEncode(body), headers: _jsonHeaders);
  }

  static Response badRequest(String message, {dynamic details}) =>
      error('bad_request', message, status: 400, details: details);

  static Response unauthorized([String message = 'Authentication required']) =>
      error('unauthorized', message, status: 401);

  static Response forbidden([String message = 'Insufficient permissions']) =>
      error('forbidden', message, status: 403);

  static Response notFound([String message = 'Resource not found']) =>
      error('not_found', message, status: 404);

  static Response conflict(String message, {dynamic details}) =>
      error('conflict', message, status: 409, details: details);

  static Response internalError([String message = 'Internal server error']) =>
      error('internal_error', message, status: 500);
}
