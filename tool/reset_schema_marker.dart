// One-off helper: drop the schemaVersion > 1 row left behind by a previous
// failed boot so runMigrations replays createAll cleanly (idempotent because
// every statement is CREATE TABLE IF NOT EXISTS).
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(File('data/amar_hisab.db').absolute.path);
  db.execute('DELETE FROM schemaVersion WHERE version > 1;');
  final remaining = db.select('SELECT * FROM schemaVersion;');
  stdout.writeln('schemaVersion rows remaining: ${remaining.length}');
  db.dispose();
}
