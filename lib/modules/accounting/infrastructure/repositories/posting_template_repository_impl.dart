import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/posting_template.dart';
import '../../domain/repositories/posting_template_repository.dart';

/// SQLite implementation of [PostingTemplateRepository].
class PostingTemplateRepositoryImpl implements PostingTemplateRepository {
  PostingTemplateRepositoryImpl(this._db);

  final Database _db;

  PostingTemplate _fromRow(Map<String, Object?> r) {
    return PostingTemplate(
      id: r['id'] as int?,
      templateCode: r['template_code'] as String,
      description: r['description'] as String?,
      businessId: r['business_id'] as int,
    );
  }

  @override
  Future<PostingTemplate> insert(PostingTemplate template) async {
    _db.execute(
      'INSERT INTO posting_templates (template_code, description, business_id) '
      'VALUES (?, ?, ?);',
      [template.templateCode, template.description, template.businessId],
    );
    return template.copyWith(id: _db.lastInsertRowId);
  }

  @override
  Future<PostingTemplate?> findById(int id) async {
    final rows =
        _db.select('SELECT * FROM posting_templates WHERE id = ?;', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<PostingTemplate?> findByCode(
      int businessId, String templateCode) async {
    final rows = _db.select(
      'SELECT * FROM posting_templates '
      'WHERE business_id = ? AND template_code = ?;',
      [businessId, templateCode],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<PostingTemplate>> list(int businessId) async {
    final rows = _db.select(
      'SELECT * FROM posting_templates WHERE business_id = ?;',
      [businessId],
    );
    return rows.map(_fromRow).toList();
  }
}
