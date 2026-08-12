import '../entities/posting_template.dart';

abstract class PostingTemplateRepository {
  Future<PostingTemplate> insert(PostingTemplate template);
  Future<PostingTemplate?> findById(int id);
  Future<PostingTemplate?> findByCode(
      int businessId, String templateCode);
  Future<List<PostingTemplate>> list(int businessId);
}
