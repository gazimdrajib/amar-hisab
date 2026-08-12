import 'dart:typed_data';

import '../../domain/entities/report_table.dart';

/// Strategy abstraction for report file generation (Architecture Book §12 –
/// `ExportPlugin`). Concrete providers generate Excel or PDF files from a
/// flattened table + optional summary block.
abstract class ReportExportProvider {
  const ReportExportProvider();

  /// One-word format identifier, used in `report.export.<format>` events.
  String get format;

  /// MIME type of the generated file.
  String get mimeType;

  /// File extension (without dot) of the generated file.
  String get extension;

  /// Render [title], [columns], [rows] and optional [summary] into bytes.
  /// Async because the `pdf` package renders documents asynchronously.
  Future<Uint8List> generate({
    required String title,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    List<SummaryItem> summary = const [],
  });
}
