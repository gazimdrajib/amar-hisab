import 'package:shelf/shelf.dart';

/// Path-parameter extraction for shelf_router routes.
///
/// `package:shelf_router` stores match parameters in the request context under
/// the key `shelf_router/params`. The public extension it ships
/// (`RouterParams`) is defined in `src/router.dart` and is **not** re-exported
/// by the package's public barrel for all consumers; when the analyzer cannot
/// see it, a controller that calls `req.params[...]` compiles (the analyzer
/// fall back to dynamic) but throws `NoSuchMethodError` at runtime.
///
/// To make this impossible, all controllers use THIS extension, which is
/// explicit, self-contained, and reads directly from the request context.
extension RouteParams on Request {
  /// Route parameters for the current shelf_router match, or an empty map.
  Map<String, String> get routeParams {
    final raw = context['shelf_router/params'];
    if (raw is Map<String, String>) return raw;
    if (raw is Map) {
      return {for (final e in raw.entries) '${e.key}': '${e.value}'};
    }
    return const <String, String>{};
  }

  /// Single path parameter lookup (never null-safe: throws if absent is
  /// intentional — callers guard with empty-string checks).
  ///
  /// Prefer named access: `request.param('id')`.
  String param(String name) => routeParams[name] ?? '';
}

/// `requiredParam` variant: throws [ArgumentError] when the parameter is not
/// present in the path (programming bug, not a user error).
extension RequiredRouteParams on Request {
  String requiredParam(String name) {
    final v = routeParams[name];
    if (v == null || v.isEmpty) {
      throw ArgumentError("missing path parameter '$name'");
    }
    return v;
  }
}
