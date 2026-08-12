import 'dart:typed_data';

import '../../../../core/services/audit_service.dart';
import '../../domain/entities/report_table.dart';
import '../export/report_export_provider.dart';

/// Error raised by [ReportExportService]; carries a machine-readable [code]
/// the controller maps to an HTTP status.
class ReportExportServiceException implements Exception {
  const ReportExportServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ReportExportServiceException($code): $message';
}

/// Result of a successful export: the raw bytes plus everything the
/// controller needs to build the download response.
class ExportedReport {
  const ExportedReport({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

/// Resolves the export format to a [ReportExportProvider] and renders the
/// report (Architecture Book §12 – ExportPlugin architecture).
class ReportExportService {
  ReportExportService(this._audit, this._providers);

  final AuditService _audit;
  final Map<String, ReportExportProvider> _providers;

  /// Available format keys (e.g. `excel`, `pdf`).
  Iterable<String> get availableFormats => _providers.keys;

  /// Generate a downloadable export. Throws [ReportExportServiceException]
  /// with code `unsupported_format` when [format] is unknown.
  Future<ExportedReport> export({
    required String format,
    required String reportType,
    required String title,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    List<SummaryItem> summary = const [],
    int? businessId,
    int? actorId,
  }) async {
    final provider = _providers[format];
    if (provider == null) {
      throw ReportExportServiceException(
        'unsupported_format',
        "Export format '$format' is not supported "
            '(available: ${availableFormats.join(', ')})',
      );
    }

    final bytes = await provider.generate(
      title: title,
      columns: columns,
      rows: rows,
      summary: summary,
    );

    _audit.logAction(
      userId: actorId,
      entityType: 'report',
      entityId: 0,
      action: 'export:$reportType:$format',
      businessId: businessId,
    );

    return ExportedReport(
      bytes: bytes,
      fileName:
          '${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.${provider.extension}',
      mimeType: provider.mimeType,
    );
  }
}
