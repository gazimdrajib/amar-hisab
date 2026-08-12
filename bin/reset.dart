// Amar Hisab — local development/admin reset helper.
//
// * Clears the `setup_completed` flag (when `--clear-setup` is passed) so the
//   first-run wizard can be re-executed.
// * Resets the password of the `admin` user (or the user passed with
//   `--user <name>`) to `--password <pwd>` (default: the audit admin
//   password). This is the documented recovery path used by `audit.dart`
//   when the original credentials have been lost during local development.
//
// NEVER run this against a production database.

import 'dart:io';

import 'package:amar_hisab/core/database/database_helper.dart';
import 'package:amar_hisab/core/utils/password_hasher.dart';

void main(List<String> args) {
  var user = 'admin';
  var password = 'AuditAdmin#2026';
  var clearSetup = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--user':
        if (i + 1 < args.length) user = args[++i];
      case '--password':
        if (i + 1 < args.length) password = args[++i];
      case '--clear-setup':
        clearSetup = true;
      case '--help':
        stdout.writeln('Usage: dart run bin/reset.dart '
            '[--user <name>] [--password <pwd>] [--clear-setup]');
        return;
    }
  }

  final helper = DatabaseHelper.instance;
  helper.runMigrations();
  final db = helper.db;

  if (password.length < 8) {
    stderr.writeln('Password must be at least 8 characters.');
    exit(2);
  }

  if (clearSetup) {
    db.execute('DELETE FROM settings WHERE key = ?', ['setup_completed']);
    stdout.writeln('Setup flag cleared.');
  }

  final rows = db
      .select('SELECT id FROM users WHERE username = ? LIMIT 1;', [user]);
  final hashed = PasswordHasher.hash(password);
  if (rows.isEmpty) {
    stdout.writeln("No user '$user' found; nothing to reset.");
  } else {
    db.execute(
      'UPDATE users SET password_hash = ?, salt = ?, updated_at = ? WHERE id = ?;',
      [hashed.hash, hashed.salt, DateTime.now().toUtc().toIso8601String(),
       rows.first['id']],
    );
    stdout.writeln("Password for '$user' has been reset.");
  }

  helper.close();
  exit(0);
}
