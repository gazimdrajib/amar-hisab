import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

/// In-process Prometheus metrics registry for the Amar Hisab backend.
///
/// Collects a small set of counters plus DB-derived gauges and exposes them
/// through `GET /metrics` in Prometheus text exposition format.
///
/// Architecture Book §11.7 (Observability).
class MetricsRegistry {
  MetricsRegistry._();

  static final MetricsRegistry instance = MetricsRegistry._();

  final Map<String, double> _counters = <String, double>{};

  /// Increment a named counter. Labels are baked into `name` for simplicity.
  void inc(String name, [double by = 1]) {
    _counters[name] = (_counters[name] ?? 0) + by;
  }

  /// Snapshot of all registered counters.
  Map<String, double> snapshot() => Map.unmodifiable(_counters);

  /// Render the metrics in Prometheus text exposition format.
  String toPrometheusText() {
    final now = (DateTime.now().millisecondsSinceEpoch / 1000).toStringAsFixed(0);
    final buffer = StringBuffer();

    buffer.writeln('# HELP amar_hisab_counters Custom counters from the Amar Hisab backend.');
    buffer.writeln('# TYPE amar_hisab_counters counter');

    for (final entry in _counters.entries) {
      buffer.writeln('amar_hisab_counters{name="${_escape(entry.key)}"} '
          '${entry.value} $now');
    }

    return buffer.toString();
  }

  String _escape(String label) =>
      label.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}

/// Compose a Prometheus response including DB-derived gauges.
String buildMetricsPayload(Database db, DateTime bootTime) {
  final buffer = StringBuffer();
  final now = (DateTime.now().millisecondsSinceEpoch / 1000).toStringAsFixed(0);
  final uptimeSeconds =
      DateTime.now().toUtc().difference(bootTime).inSeconds;

  buffer.writeln(MetricsRegistry.instance.toPrometheusText());

  buffer.writeln('# HELP amar_hisab_uptime_seconds Time since the backend booted.');
  buffer.writeln('# TYPE amar_hisab_uptime_seconds gauge');
  buffer.writeln('amar_hisab_uptime_seconds $uptimeSeconds $now');

  // Sales
  try {
    final salesToday = db.select(
      'SELECT COUNT(*) AS c, COALESCE(SUM(grand_total), 0) AS t '
      "FROM sales WHERE date(created_at) = date('now');",
    ).first;
    buffer
      ..writeln('# HELP amar_hisab_sales_today_count Sales created today.')
      ..writeln('# TYPE amar_hisab_sales_today_count gauge')
      ..writeln('amar_hisab_sales_today_count ${salesToday['c']} $now')
      ..writeln('# HELP amar_hisab_sales_today_amount Total revenue today.')
      ..writeln('# TYPE amar_hisab_sales_today_amount gauge')
      ..writeln('amar_hisab_sales_today_amount ${salesToday['t']} $now');
  } catch (_) {/* sales table may not exist yet in dev */}

  // Low stock / expiring batches
  try {
    final lowStock = db.select(
      'SELECT COUNT(*) AS c FROM stock s '
      'JOIN products p ON p.id = s.product_id AND p.business_id = s.business_id '
      'WHERE s.quantity <= p.min_stock_level AND p.min_stock_level > 0;',
    ).first['c'];
    final expiring = db.select(
      'SELECT COUNT(*) AS c FROM batches WHERE expiry_date IS NOT NULL '
      "AND expiry_date <= date('now', '+30 days');",
    ).first['c'];
    buffer
      ..writeln('# HELP amar_hisab_low_stock_items Items at or below reorder level.')
      ..writeln('# TYPE amar_hisab_low_stock_items gauge')
      ..writeln('amar_hisab_low_stock_items $lowStock $now')
      ..writeln('# HELP amar_hisab_expiring_batches Batches expiring <= 30 days.')
      ..writeln('# TYPE amar_hisab_expiring_batches gauge')
      ..writeln('amar_hisab_expiring_batches $expiring $now');
  } catch (_) {/* optional */}

  // Sync pending count (only if the sync schema exists).
  try {
    final pending = db.select(
      'SELECT COUNT(*) AS c FROM change_log WHERE sync_status = \'pending\';',
    ).first['c'];
    buffer
      ..writeln('# HELP amar_hisab_sync_pending Pending changes in the sync queue.')
      ..writeln('# TYPE amar_hisab_sync_pending gauge')
      ..writeln('amar_hisab_sync_pending $pending $now');
  } catch (_) {/* sync disabled */}

  // Node info
  buffer
    ..writeln('# HELP amar_hisab_info Node build info.')
    ..writeln('# TYPE amar_hisab_info gauge')
    ..writeln('amar_hisab_info{version="1.0.0",platform="${Platform.operatingSystem}"} 1 $now');

  return buffer.toString();
}

/// JSON variant for the legacy /health endpoint and the health_check.sh script.
Map<String, dynamic> buildMetricsJson(Database db, DateTime bootTime) {
  final result = <String, dynamic>{
    'counters': MetricsRegistry.instance.snapshot(),
    'uptimeSeconds':
        DateTime.now().toUtc().difference(bootTime).inSeconds,
  };

  try {
    final salesToday = db.select(
      'SELECT COUNT(*) AS c, COALESCE(SUM(grand_total), 0) AS t '
      "FROM sales WHERE date(created_at) = date('now');",
    ).first;
    result['salesTodayCount'] = salesToday['c'];
    result['salesTodayAmount'] = salesToday['t'];
  } catch (_) {/* table missing */}

  try {
    final pending = db.select(
      'SELECT COUNT(*) AS c FROM change_log WHERE sync_status = \'pending\';',
    ).first;
    result['syncPending'] = pending['c'];
  } catch (_) {/* sync disabled */}

  result['ts'] = DateTime.now().toUtc().toIso8601String();
  return result;
}

/// Minimal HTTP handler for `GET /metrics`.
Future<Response> metricsHandler(Request request, Database db, DateTime bootTime) async {
  final accept = request.headers['accept'] ?? '';
  if (accept.contains('application/json')) {
    return Response.ok(
      jsonEncode(buildMetricsJson(db, bootTime)),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
  return Response.ok(
    buildMetricsPayload(db, bootTime),
    headers: {'content-type': 'text/plain; version=0.0.4; charset=utf-8'},
  );
}
