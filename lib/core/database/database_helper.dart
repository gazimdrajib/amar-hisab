import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'schema_v1.dart';

/// SQLite-backed database helper.
///
/// Opens (creating if needed) a SQLite database in **WAL** journal mode,
/// tracks schema versions in the `schemaVersion` table, and applies
/// migrations through [runMigrations]. Loaded from DB_PATH env (default
/// `data/amar_hisab.db`).
class DatabaseHelper {
  DatabaseHelper._();

  static DatabaseHelper? _instance;

  /// Shared singleton accessor.
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Database? _db;

  /// Lazily-opened database connection shared by the whole application.
  Database get db {
    final existing = _db;
    if (existing != null) return existing;
    final created = _open();
    _db = created;
    return created;
  }

  Database _open() {
    final dbPath = Platform.environment['DB_PATH'] ?? p.join('data', 'amar_hisab.db');
    final dir = p.dirname(dbPath);
    if (dir.isNotEmpty) {
      Directory(dir).createSync(recursive: true);
    }
    final database = sqlite3.open(dbPath);
    // WAL mode + sane pragmas (safe defaults for server usage).
    database.execute('PRAGMA journal_mode = WAL;');
    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('PRAGMA synchronous = NORMAL;');
    database.execute('PRAGMA busy_timeout = 5000;');
    return database;
  }

  /// Ensure the schemaVersion table exists, then apply migrations.
  ///
  /// Applies [SchemaV1.createAll] idempotently (`CREATE TABLE IF NOT EXISTS`)
  /// whenever the recorded version is behind [SchemaV1.schemaVersion].
  /// Additive releases (e.g. Phase 9's sync tables) bump [SchemaV1.schemaVersion]
  /// so existing databases get the new tables without touching the old ones.
  /// History is kept as one row per applied version (ON CONFLICT REPLACE on the
  /// current row + a full downgrade guard).
  void runMigrations() {
    final d = db;
    d.execute('''
      CREATE TABLE IF NOT EXISTS schemaVersion (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      );
    ''');
    final applied = d.select('SELECT MAX(version) AS v FROM schemaVersion;');
    final current = (applied.isEmpty ? 0 : (applied.first['v'] as int?) ?? 0);

    if (current >= SchemaV1.schemaVersion) return; // no-op on up-to-date DBs

    d.execute('BEGIN IMMEDIATE;');
    try {
      SchemaV1.createAll(d);
      d.execute(
        'INSERT INTO schemaVersion (version, applied_at) VALUES (?, ?) '
        'ON CONFLICT(version) DO UPDATE SET applied_at = excluded.applied_at;',
        [SchemaV1.schemaVersion, DateTime.now().toUtc().toIso8601String()],
      );
      d.execute('COMMIT;');
    } catch (_) {
      d.execute('ROLLBACK;');
      rethrow;
    }
  }

  /// Close the underlying database (mainly for tests / shutdown).
  void close() {
    _db?.dispose();
    _db = null;
  }
}
