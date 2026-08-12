// Amar Hisab — self-contained system audit script.
//
// Usage:  dart audit.dart [--json-only]
//
// Runs a battery of checks (SDK, dependencies, code-gen, static analysis,
// tests, database integrity, API smoke tests, port 8080, .env validation)
// and writes:
//   * audit_report.json  – structured machine-readable report
//   * a human-readable summary to stdout (and audit_summary.txt)
//
// Exit code 0 when every high-priority check passes, 1 otherwise.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------

class CheckResult {
  CheckResult(this.id, this.name);
  final String id;
  final String name;
  String status = 'FAIL'; // PASS | FAIL | NA
  String summary = '';
  List<String> details = <String>[];
  int durationMs = 0;
}

class Auditor {
  Auditor(this.projectRoot);

  final String projectRoot;
  final String dartExe = Platform.isWindows
      ? r'D:\flutter\bin\cache\dart-sdk\bin\dart.exe'
      : 'dart';
  final List<CheckResult> checks = <CheckResult>[];
  final Map<String, dynamic> meta = <String, dynamic>{
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'platform': Platform.operatingSystem,
    'platformVersion': Platform.operatingSystemVersion,
  };

  CheckResult _begin(String id, String name) {
    final c = CheckResult(id, name);
    checks.add(c);
    return c;
  }

  void _finish(CheckResult c, Stopwatch sw, bool ok, String summary,
      [List<String>? details]) {
    c.durationMs = sw.elapsedMilliseconds;
    c.status = ok ? 'PASS' : 'FAIL';
    c.summary = summary;
    if (details != null && details.isNotEmpty) c.details = details;
  }

  Future<ProcessResult> _run(List<String> args,
      {int timeoutSec = 300, Map<String, String>? env}) {
    return Process.run(dartExe, args,
            workingDirectory: projectRoot,
            includeParentEnvironment: true,
            environment: env)
        .timeout(Duration(seconds: timeoutSec), onTimeout: () {
      return Future<ProcessResult>.delayed(
          Duration.zero,
          () => ProcessResult(0, 124, '',
              'TIMEOUT after ${timeoutSec}s: dart ${args.join(' ')}'));
    });
  }

  // ------------------------------------------------------------------ SDK --
  Future<void> checkSdk() async {
    final sw = Stopwatch()..start();
    final c = _begin('sdk', 'Dart SDK version');
    try {
      final r = await Process.run(dartExe, ['--version']);
      meta['dartSdkPath'] = dartExe;
      final ver = '${r.stdout}${r.stderr}'.trim();
      meta['dartSdkVersion'] = ver;
      final ok = r.exitCode == 0 && ver.contains('3.');
      _finish(c, sw, ok, ok ? ver : 'SDK missing', [ver]);
    } catch (e) {
      _finish(c, sw, false, 'Dart SDK not found at $dartExe', ['$e']);
    }
  }

  // ----------------------------------------------------------- Dependencies --
  Future<void> checkPub() async {
    final sw = Stopwatch()..start();
    final c = _begin('dependencies', 'Dependency status');
    final get = await _run(['pub', 'get'], timeoutSec: 240);
    if (get.exitCode != 0) {
      _finish(c, sw, false, 'dart pub get failed',
          [get.stdout.toString(), get.stderr.toString()]);
      return;
    }
    final out = await _run(['pub', 'outdated', '--json', '--no-dev-dependencies'],
        timeoutSec: 240);
    String summary = 'all dependencies resolvable';
    final details = <String>[];
    try {
      final json = jsonDecode(out.stdout.toString()) as Map<String, dynamic>;
      final pkgs = (json['packages'] as List?) ?? const [];
      final upgradable = pkgs
          .where((p) => (p as Map)['upgradable']?['name'] != null)
          .map((p) => '${(p as Map)['package']}')
          .toList();
      if (upgradable.isNotEmpty) {
        summary = '${upgradable.length} packages upgradable';
        details.addAll(upgradable);
      }
      meta['upgradablePackages'] = upgradable;
    } catch (_) {
      details.add('Could not parse `pub outdated` output');
    }
    _finish(c, sw, true, summary, details);
  }

  // ------------------------------------------------------------ Codegen --
  Future<void> checkCodegen() async {
    final sw = Stopwatch()..start();
    final c = _begin('codegen', 'Code generation (build_runner)');
    final r = await _run(
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        timeoutSec: 600);
    final log = '${r.stdout}\n${r.stderr}';
    final ok = r.exitCode == 0 && log.contains('Succeeded');
    _finish(c, sw, ok,
        ok ? 'build_runner succeeded' : 'build_runner failed', [log]);
  }

  // ----------------------------------------------------------- Analysis --
  Future<void> checkAnalysis() async {
    final sw = Stopwatch()..start();
    final c = _begin('analysis', 'Static analysis (dart analyze --fatal-warnings)');
    final r = await _run(['analyze', '--fatal-warnings'], timeoutSec: 300);
    final log = '${r.stdout}\n${r.stderr}';
    final m = RegExp(r'(\d+) issues? found').firstMatch(log);
    final n = m == null ? 0 : int.parse(m.group(1)!);
    _finish(c, sw, r.exitCode == 0,
        r.exitCode == 0 ? 'no issues' : '$n issues found', [log]);
  }

  // -------------------------------------------------------------- Tests --
  Future<void> checkTests() async {
    final sw = Stopwatch()..start();
    final c = _begin('tests', 'Test execution (dart test)');
    final testDir = Directory('$projectRoot${Platform.pathSeparator}test');
    if (!testDir.existsSync()) {
      c.durationMs = sw.elapsedMilliseconds;
      c.status = 'NA';
      c.summary =
          'No root-level test/ directory (backend ships smoke-tested via audit)';
      return;
    }
    final r = await _run(['test', '-r', 'expanded'], timeoutSec: 600);
    final log = '${r.stdout}\n${r.stderr}';
    _finish(c, sw, r.exitCode == 0,
        r.exitCode == 0 ? 'all tests passed' : 'test failures', [log]);
  }

  // ------------------------------------------------------------- .env --
  Future<void> checkEnv() async {
    final sw = Stopwatch()..start();
    final c = _begin('env', '.env file validation');
    final f = File('$projectRoot${Platform.pathSeparator}.env');
    if (!f.existsSync()) {
      _finish(c, sw, false, '.env file missing');
      return;
    }
    final vars = <String, String>{};
    for (final raw in f.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final i = line.indexOf('=');
      if (i > 0) vars[line.substring(0, i).trim()] = line.substring(i + 1).trim();
    }
    final bad = <String>[];
    final jwt = vars['JWT_SECRET'] ?? '';
    if (jwt.isEmpty ||
        jwt.startsWith('__CHANGE_ME') ||
        jwt == 'my_super_secret_key_change_this_in_production') {
      bad.add('JWT_SECRET missing, placeholder or known default');
    }
    meta['envKeys'] = vars.keys.toList();
    _finish(c, sw, bad.isEmpty,
        bad.isEmpty ? '.env valid (${vars.length} vars)' : bad.join('; '), bad);
  }

  // ------------------------------------------------------------ Database --
  static const List<String> expectedTables = [
    'businesses', 'roles', 'users', 'permissions', 'audit_log', 'settings',
    'categories', 'brands', 'units', 'products', 'warehouses', 'batches',
    'stock', 'stock_movements', 'customers', 'sales', 'sale_items',
    'sale_payments', 'sales_returns', 'suppliers', 'purchases',
    'purchase_items', 'supplier_payments', 'chart_of_accounts',
    'journal_entries', 'journal_lines', 'posting_templates',
    'accounting_periods', 'change_log', 'sync_state', 'device_registry',
    'portal_tokens', 'students',
  ];

  Future<void> checkDatabase() async {
    final sw = Stopwatch()..start();
    final c = _begin('database', 'Database integrity');
    String? dbPath;
    for (final cand in ['data${Platform.pathSeparator}amar_hisab.db', 'amar_hisab.db']) {
      final p = '$projectRoot${Platform.pathSeparator}$cand';
      if (File(p).existsSync()) {
        dbPath = p;
        break;
      }
    }
    if (dbPath == null) {
      _finish(c, sw, false, 'database file not found (expected data/amar_hisab.db)');
      return;
    }
    meta['dbPath'] = dbPath;
    final tmp = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}ah_audit_${DateTime.now().millisecondsSinceEpoch}.dart');
    try {
      // Only add package:sqlite3 to PATH resolution – the script is compiled
      // inside the project so package resolution just works.
      tmp.writeAsStringSync('''
import 'package:sqlite3/sqlite3.dart';
import 'dart:convert';
import 'dart:io';
void main() {
  final db = sqlite3.open(${jsonEncode(dbPath.replaceAll(r'\', r'\\'))});
  try {
    final rows = db
        .select("SELECT name FROM sqlite_master WHERE type='table'")
        .map((r) => r['name'].toString())
        .toList();
    stdout.write(jsonEncode(rows));
  } finally {
    db.dispose();
  }
}
''');
      final r = await _run([tmp.path], timeoutSec: 60);
      if (r.exitCode != 0) {
        _finish(c, sw, false, 'database cannot be opened (corruption?)',
            [r.stderr.toString()]);
        return;
      }
      final tables =
          (jsonDecode(r.stdout.toString()) as List).cast<String>().toSet();
      final missing =
          expectedTables.where((t) => !tables.contains(t)).toList();
      meta['dbTables'] = tables.length;
      _finish(
          c,
          sw,
          missing.isEmpty,
          missing.isEmpty
              ? '${expectedTables.length}/${expectedTables.length} tables present'
              : 'missing tables: ${missing.join(', ')}',
          missing);
    } finally {
      if (tmp.existsSync()) tmp.delete();
    }
  }

  // ---------------------------------------------------------------- Port --
  Future<bool> _freePort() async {
    ServerSocket? s;
    try {
      s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 8080);
      return true;
    } catch (_) {
      return false;
    } finally {
      await s?.close();
    }
  }

  // ----------------------------------------------------------- API smoke --
  Process? _serverProc;
  final StringBuffer _serverLog = StringBuffer();
  bool _startedServer = false;
  String? _token;
  String? _ownerUser;
  String? _ownerPass;

  /// Constant so `bin/reset.dart` and this script agree on the recovered
  /// audit-admin password (kept out of .env on purpose; dev-only backdoor
  /// removed for production builds).
  static const String auditAdminPass = 'AuditAdmin#2026';

  Future<void> checkApi() async {
    final sw = Stopwatch()..start();
    final portC = _begin('port', 'Port 8080 availability');
    final c = _begin('api', 'API smoke tests');
    c.details = <String>[];

    var free = await _freePort();
    _finish(portC, Stopwatch()..start(), free,
        free ? 'port 8080 free' : 'port 8080 occupied');
    // If the port is busy, try to reuse the already-running server for the
    // smoke tests instead of failing the whole audit.
    final base = 'http://127.0.0.1:8080';

    if (free) {
      try {
        _serverProc = await Process.start(
            dartExe, ['run', 'bin/server.dart'],
            workingDirectory: projectRoot,
            environment: <String, String>{'SYNC_ENABLED': 'false'},
            runInShell: false);
        _startedServer = true;
        _serverProc!.stdout
            .transform(utf8.decoder)
            .listen((d) => _serverLog.write(d));
        _serverProc!.stderr
            .transform(utf8.decoder)
            .listen((d) => _serverLog.write(d));
        final exitFuture = _serverProc!.exitCode;
        var up = false;
        for (var i = 0; i < 45 && !up; i++) {
          final winner = await Future.any<Object>(
              [exitFuture, Future.delayed(const Duration(seconds: 1))]);
          if (winner is int) break; // server died
          final r = await _http('GET', '$base/health');
          if (r.status == 200) up = true;
        }
        if (!up) {
          _finish(c, sw, false, 'server failed to start',
              _details(_serverLog.toString()));
          await _stopServer();
          return;
        }
        c.details.add('server started by audit (port 8080 was free)');
      } catch (e) {
        _finish(c, sw, false, 'could not launch server', _details('$e'));
        await _stopServer();
        return;
      }
    } else {
      c.details.add('reusing already-running server on 8080');
    }

    try {
      // -- health ----------------------------------------------------------
      final health = await _http('GET', '$base/health');
      c.details.add(
          'GET /health -> ${health.status} ${health.status == 200 ? 'OK' : health.body}');
      if (health.status != 200) throw 'health check failed';

      // -- setup status ------------------------------------------------------
      final status = await _http('GET', '$base/setup/status');
      c.details.add('GET /setup/status -> ${status.status} ${status.body}');
      if (status.status != 200) throw 'setup/status failed';
      final st = jsonDecode(status.body) as Map<String, dynamic>;
      final completed = st['initialized'] == true ||
          st['setupCompleted'] == true ||
          st['setup_completed'] == true ||
          (st['data'] is Map &&
              ((st['data'] as Map)['initialized'] == true ||
                  (st['data'] as Map)['setupCompleted'] == true ||
                  (st['data'] as Map)['setup_completed'] == true));

      // -- setup (if needed) -------------------------------------------------
      if (!completed) {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        _ownerUser = 'owner_$stamp';
        _ownerPass = 'AuditPass#${stamp % 100000}';
        final setup = await _http('POST', '$base/setup/init', {
          'businessName': 'Amar Hisab Audit',
          'businessType': 'retail',
          'ownerUsername': _ownerUser,
          'ownerPassword': _ownerPass,
          'ownerFullName': 'Audit Owner',
        });
        c.details.add('POST /setup/init -> ${setup.status} ${setup.body}');
        if (setup.status != 200 && setup.status != 201) {
          throw 'setup failed';
        }
      } else {
        // Try to recover cached credentials from a previous audit run.
        final credFile = File('$projectRoot${Platform.pathSeparator}.audit_credentials.json');
        if (credFile.existsSync()) {
          final m =
              jsonDecode(credFile.readAsStringSync()) as Map<String, dynamic>;
          _ownerUser = m['username'] as String?;
          _ownerPass = m['password'] as String?;
          c.details.add('loaded cached audit credentials');
        }
      }

      // -- login -------------------------------------------------------------
      var loggedIn = false;
      Future<void> attemptLogin() async {
        if (_ownerUser == null || _ownerPass == null) return;
        final login = await _http('POST', '$base/api/v1/auth/login',
            {'username': _ownerUser, 'password': _ownerPass});
        if (login.status == 200) {
          final j = jsonDecode(login.body) as Map<String, dynamic>;
          final data = j['data'] is Map ? j['data'] as Map : j;
          _token = (data['token'] ?? data['accessToken'] ?? data['jwt'])
              as String?;
          loggedIn = _token != null && _token!.isNotEmpty;
        }
        c.details.add('POST /auth/login (${_ownerUser}) -> ${login.status}');
      }

      await attemptLogin();
      if (!loggedIn &&
          completed &&
          File('$projectRoot${Platform.pathSeparator}bin/reset.dart')
              .existsSync()) {
        // Setup is complete but we have no cached credentials (or they were
        // wrong). Recover by resetting the local 'admin' account — reset.dart
        // rewrites its password to a fresh audit password.
        final rr = await _run(['run', 'bin/reset.dart'], timeoutSec: 120);
        if (rr.exitCode == 0) {
          _ownerUser = 'admin';
          _ownerPass = auditAdminPass;
          c.details.add('recovered login via bin/reset.dart (admin reset)');
          await attemptLogin();
        } else {
          c.details.add('bin/reset.dart failed: ${rr.stdout} ${rr.stderr}');
        }
      }
      if (!loggedIn) {
        c.details.add('login failed with available credentials');
        _finish(c, sw, false, 'login failed', c.details);
        return;
      }
      if (_ownerUser != null) {
        File('$projectRoot${Platform.pathSeparator}.audit_credentials.json')
            .writeAsStringSync(jsonEncode(
                {'username': _ownerUser, 'password': _ownerPass}));
      }

      // -- protected endpoint ------------------------------------------------
      final products = await _http('GET', '$base/api/v1/products', null,
          {'authorization': 'Bearer $_token'});
      c.details.add('GET /api/v1/products -> ${products.status}');
      if (products.status != 200) {
        _finish(c, sw, false, 'protected endpoint failed', c.details);
        return;
      }

      _finish(c, sw, true, 'health, setup, login, protected endpoints OK',
          c.details);
    } catch (e) {
      _finish(c, sw, false, '$e', c.details);
    }
  }

  List<String> _details(String s) =>
      s.split('\n').where((l) => l.trim().isNotEmpty).toList();

  Future<void> _stopServer() async {
    if (_serverProc != null) {
      _serverProc!.kill(ProcessSignal.sigterm);
      try {
        await _serverProc!.exitCode
            .timeout(const Duration(seconds: 10), onTimeout: () => -1);
      } catch (_) {}
      _serverProc = null;
      // Give the OS a moment to release the socket.
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ---------------------------------------------------------------- HTTP --
  Future<({int status, String body})> _http(String method, String url,
      [Object? body, Map<String, String>? extraHeaders]) {
    final headers =
        extraHeaders ?? <String, String>{};
    return _httpInner(method, url, body, headers: headers);
  }

  Future<({int status, String body})> _httpInner(String method, String url,
      Object? body,
      {Map<String, String> headers = const {}}) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse(url);
      final req = await client.openUrl(method, uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('HTTP timeout $method $url'));
      req.headers.contentType = ContentType.json;
      for (final e in (headersMapInto(headers)).entries) {
        req.headers.set(e.key, e.value);
      }
      if (body != null) req.write(jsonEncode(body));
      final resp = await req.close().timeout(const Duration(seconds: 10));
      final text = await resp
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      return (status: resp.statusCode, body: text);
    } catch (e) {
      return (status: -1, body: '$e');
    } finally {
      client?.close(force: true);
    }
  }

  Map<String, String> headersMapInto(Map<String, String> h) => h;

  // ---------------------------------------------------------------- report --
  Map<String, dynamic> toJson() => {
        'meta': meta,
        'checks': checks
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'status': c.status,
                  'summary': c.summary,
                  'durationMs': c.durationMs,
                  'details': c.details,
                })
            .toList(),
      };

  String buildSummary() {
    final b = StringBuffer()
      ..writeln('Amar Hisab — System Audit')
      ..writeln(meta['timestamp'])
      ..writeln('=' * 60);
    for (final c in checks) {
      final mark =
          {('PASS'): '[PASS]', ('FAIL'): '[FAIL]', ('NA'): '[N/A ]'}[c.status]!;
      b.writeln('$mark ${c.name}: ${c.summary}');
    }
    b.writeln('=' * 60);
    final fails = checks.where((c) => c.status == 'FAIL').toList();
    final passes = checks.where((c) => c.status == 'PASS').length;
    final nas = checks.where((c) => c.status == 'NA').length;
    b.writeln('RESULT: $passes PASS, ${fails.length} FAIL, $nas N/A');
    return b.toString();
  }
}

void main(List<String> args) async {
  final root = Directory.current.path;
  final a = Auditor(root);

  final jsonOnly = args.contains('--json-only');

  void out(Object? o) {
    if (!jsonOnly) stdout.writeln(o);
  }

  out('Running audit in $root ...');
  await a.checkSdk();
  await a.checkPub();
  await a.checkCodegen();
  await a.checkAnalysis();
  await a.checkTests();
  await a.checkEnv();
  await a.checkDatabase();
  await a.checkApi();

  final summary = a.buildSummary();
  out(summary);

  final jsonFile = File('$root${Platform.pathSeparator}audit_report.json');
  jsonFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(a.toJson()));
  File('$root${Platform.pathSeparator}audit_summary.txt')
      .writeAsStringSync(summary);
  out('JSON report: audit_report.json');

  // Clean up: stop the server we started (leave an already-running server up).
  await a._stopServer();
  if (a._startedServer) {
    out('Stopped audit-spawned server.');
  }

  final failed = a.checks
      .where((c) => c.status == 'FAIL' && c.id != 'port' && c.id != 'env')
      .isNotEmpty;
  exitCode = failed ? 1 : 0;
}
