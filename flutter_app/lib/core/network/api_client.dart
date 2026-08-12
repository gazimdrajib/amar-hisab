import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import 'api_exception.dart';

/// Thin HTTP client that talks to the Dart Shelf backend.
/// Handles the JWT header and unwraps the ResponseEnvelope.
class ApiClient {
  final http.Client _client;
  String baseUrl;
  String? _token;

  /// Called when the backend answers 401 — used to force logout.
  VoidCallback? onUnauthorized;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated && hasToken) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final queryMap = query?.map((key, value) => MapEntry(key, '$value'));
    queryMap?.removeWhere((_, value) => value.isEmpty);
    return Uri.parse('$base$path')
        .replace(queryParameters: queryMap?.isNotEmpty == true ? queryMap : null);
  }

  Future<dynamic> get(String path,
          {Map<String, dynamic>? query, bool authenticated = true}) =>
      _send(() => _client.get(_uri(path, query),
          headers: _headers(authenticated: authenticated)));

  Future<dynamic> post(String path,
          {Object? body, bool authenticated = true}) =>
      _send(() => _client.post(_uri(path),
          headers: _headers(authenticated: authenticated),
          body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _client.put(_uri(path),
          headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers()));

  /// Binary download used by report export (server sends raw bytes, no envelope).
  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _toException(response);
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        code: 'network_error',
        message: 'Could not reach the server: $e',
      );
    }

    Map<String, dynamic> body;
    try {
      body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'parse_error',
        message: 'Invalid server response (${response.statusCode})',
      );
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException.fromJson(response.statusCode, body);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['success'] == true) return body['data'];
      // Graceful fallback when the envelope flag is missing.
      return body['data'] ?? body;
    }
    throw _toException(response, body);
  }

  ApiException _toException(http.Response response,
      [Map<String, dynamic>? body]) {
    final parsed = body ??
        (() {
          try {
            return jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{
              'error': {'code': 'http_${response.statusCode}', 'message': response.body}
            };
          }
        }());
    return ApiException.fromJson(response.statusCode, parsed);
  }

  void close() => _client.close();
}

/// Endpoints per the mounts in bin/server.dart.
class ApiEndpoints {
  ApiEndpoints._();
  static const String _v = AppConfig.apiPrefix;

  static const String health = '/health';
  static const String login = '$_v/auth/login';
  static const String me = '$_v/auth/me';

  static const String products = '$_v/products/';
  static String productSearch(String query) => '$_v/products/search/$query';
  static String product(int id) => '$_v/products/$id';

  static const String categories = '$_v/categories/';
  static const String brands = '$_v/brands/';
  static const String units = '$_v/units/';

  static const String warehouses = '$_v/warehouses/';
  static String warehouseStock(int warehouseId) =>
      '$_v/inventory/warehouse/$warehouseId';
  static String productStock(int productId) => '$_v/inventory/product/$productId';
  static String movements(int productId) => '$_v/inventory/movements/$productId';
  static const String inventoryAdd = '$_v/inventory/add';
  static const String inventoryDeduct = '$_v/inventory/deduct';
  static const String inventoryTransfer = '$_v/inventory/transfer';
  static const String inventoryAdjust = '$_v/inventory/adjust';

  static const String sales = '$_v/sales/';
  static String sale(int id) => '$_v/sales/$id';
  static String saleReturn(int id) => '$_v/sales/$id/return';

  static const String purchases = '$_v/purchases/';

  static String report(String name) => '$_v/reports/$name';
  static String reportExport(String name, String format) =>
      '$_v/reports/$name/export/$format';
}
