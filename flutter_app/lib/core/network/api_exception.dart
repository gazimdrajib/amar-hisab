/// Exception thrown for non-2xx responses from the Amar Hisab Shelf API.
///
/// The backend wraps every error in ResponseEnvelope:
/// `{ "success": false, "error": { "code": "...", "message": "..." } }`
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiException.fromJson(int statusCode, Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return ApiException(
        statusCode: statusCode,
        code: (error['code'] ?? 'unknown').toString(),
        message: (error['message'] ?? 'Request failed').toString(),
        details: error['details'],
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: 'unknown',
      message: json['message']?.toString() ?? 'Request failed ($statusCode)',
    );
  }

  bool get isUnauthorized => statusCode == 401 || code == 'unauthorized';

  @override
  String toString() => message;
}
