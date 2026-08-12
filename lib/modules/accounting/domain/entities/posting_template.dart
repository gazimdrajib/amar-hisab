import 'package:freezed_annotation/freezed_annotation.dart';

part 'posting_template.freezed.dart';
part 'posting_template.g.dart';

/// Auto-posting rule template (Database Book §3.5 – `posting_templates`).
@freezed
class PostingTemplate with _$PostingTemplate {
  const factory PostingTemplate({
    int? id,
    required String templateCode,
    String? description,
    required int businessId,
  }) = _PostingTemplate;

  factory PostingTemplate.fromJson(Map<String, dynamic> json) =>
      _$PostingTemplateFromJson(json);
}
