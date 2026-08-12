import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath =
      Platform.environment['DB_PATH'] ?? p.join('data', 'amar_hisab.db');
  final db = sqlite3.open(dbPath);

  try {
    db.execute('BEGIN IMMEDIATE;');

    // Remove only the setup marker so /setup/initialize can run again.
    db.execute("DELETE FROM settings WHERE key = 'setup_completed';");

    final usersExisted = db
        .select("SELECT COUNT(*) AS count FROM sqlite_master WHERE type = 'table' AND name = 'users';")
        .first['count'] == 1;
    if (usersExisted) {
      db.execute('DELETE FROM users;');
    }

    // The setup controller blocks when any business row exists, so reset the
    // whole setup state instead of only the flag.
    db
      ..execute('DELETE FROM permissions;')
      ..execute('DELETE FROM roles;')
      ..execute('DELETE FROM settings;')
      ..execute('DELETE FROM businesses;')
      ..execute(
        "DELETE FROM sqlite_sequence WHERE name IN ('businesses', 'roles', 'permissions', 'users', 'settings');",
      );

    db.execute('COMMIT;');
    stdout.writeln('Setup state reset successfully.');
  } catch (error) {
    try {
      db.execute('ROLLBACK;');
    } catch (_) {
      // Ignore rollback errors when the transaction was not active.
    }
    stderr.writeln('Failed to reset setup state: $error');
    exitCode = 1;
  } finally {
    db.dispose();
  }
}
