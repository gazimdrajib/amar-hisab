import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_token.freezed.dart';
part 'student_token.g.dart';

/// Portal (QR self-service) token row from `portal_tokens`
/// (Database Book Phase 9 / Proto Contract Book §3.8).
@freezed
class StudentToken with _$StudentToken {
  const factory StudentToken({
    int? id,
    required int businessId,

    /// The opaque token embedded in the QR URL (`/public/qr/{token}/...`).
    required String token,

    /// Scope of the token: `student`, `batch` or `business`.
    @Default('qr') String type,

    /// Set for `student` tokens; null for batch/business QR tokens that can
    /// list many student IDs.
    int? studentId,

    /// Batch scope for `batch` tokens.
    int? batchId,

    /// SHA-256 hash of the student login secret (null for QR-only tokens).
    String? secretHash,

    DateTime? expiresAt,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _StudentToken;

  factory StudentToken.fromJson(Map<String, dynamic> json) =>
      _$StudentTokenFromJson(json);
}
