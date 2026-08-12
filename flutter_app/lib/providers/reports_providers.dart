import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/api_client.dart';
import '../models/report.dart';
import 'app_providers.dart';

class ReportQuery {
  final DateTime? from;
  final DateTime? to;

  const ReportQuery({this.from, this.to});

  Map<String, dynamic> toParams() => {
        if (from != null) 'from': DateFormat('yyyy-MM-dd').format(from!),
        if (to != null) 'to': DateFormat('yyyy-MM-dd').format(to!),
      };

  @override
  bool operator ==(Object other) =>
      other is ReportQuery && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Name can be 'sales', 'purchases', 'inventory', 'financial'.
final reportProvider = FutureProvider.autoDispose
    .family<ReportTable, ({String name, ReportQuery query})>(
        (ref, args) async {
  final data = await ref
      .read(apiClientProvider)
      .get(ApiEndpoints.report(args.name), query: args.query.toParams())
      as Map<String, dynamic>;
  return ReportTable.fromJson(data);
});

/// Downloaded export file details.
class ExportedFile {
  final String path;
  final Uint8List bytes;
  final String filename;
  const ExportedFile({required this.path, required this.bytes, required this.filename});
}

/// GET /reports/<name>/export/<excel|pdf> — server returns raw bytes.
final reportExportProvider = FutureProvider.autoDispose
    .family<ExportedFile, ({String name, String format, ReportQuery query})>(
        (ref, args) async {
  final bytes = await ref.read(apiClientProvider).getBytes(
      ApiEndpoints.reportExport(args.name, args.format),
      query: args.query.toParams());

  final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final ext = args.format == 'excel' ? 'xlsx' : 'pdf';
  final filename = '${args.name}_report_$stamp.$ext';

  if (kIsWeb) {
    return ExportedFile(path: filename, bytes: bytes, filename: filename);
  }
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes);
  return ExportedFile(path: file.path, bytes: bytes, filename: filename);
});
