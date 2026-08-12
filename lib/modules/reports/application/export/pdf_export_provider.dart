import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/report_table.dart';
import 'report_export_provider.dart';

/// PDF export via the `pdf` package.
class PdfExportProvider extends ReportExportProvider {
  const PdfExportProvider();

  @override
  String get format => 'pdf';

  @override
  String get mimeType => 'application/pdf';

  @override
  String get extension => 'pdf';

  @override
  Future<Uint8List> generate({
    required String title,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    List<SummaryItem> summary = const [],
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated ${DateTime.now().toUtc().toIso8601String()}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          if (summary.isNotEmpty) ...[
            pw.TableHelper.fromTextArray(
              cellHeight: 20,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              headers: const ['Summary', 'Value'],
              data: [
                for (final s in summary)
                  [s.label, _format(s.value, s.isNumeric)],
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          pw.TableHelper.fromTextArray(
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey100),
            cellHeight: 18,
            columnWidths: {
              for (var i = 0; i < columns.length; i++)
                i: columns[i].isNumeric
                    ? const pw.FixedColumnWidth(70)
                    : const pw.FlexColumnWidth(),
            },
            cellAlignments: {
              for (var i = 0; i < columns.length; i++)
                i: columns[i].isNumeric
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
            },
            headers: [for (final c in columns) c.label],
            data: [
              for (final row in rows)
                [
                  for (final c in columns)
                    _format(row[c.key], c.isNumeric),
                ],
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  String _format(Object? value, bool isNumeric) {
    if (value == null) return '';
    if (isNumeric && value is num) {
      return ((value * 100).roundToDouble() / 100).toStringAsFixed(2);
    }
    return '$value';
  }
}
