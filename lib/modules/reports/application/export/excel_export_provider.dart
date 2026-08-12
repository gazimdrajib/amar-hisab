import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/report_table.dart';
import 'report_export_provider.dart';

/// Excel (.xlsx) export via the `excel` package.
class ExcelExportProvider extends ReportExportProvider {
  const ExcelExportProvider();

  @override
  String get format => 'excel';

  @override
  String get mimeType =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  String get extension => 'xlsx';

  @override
  Future<Uint8List> generate({
    required String title,
    required List<ReportColumn> columns,
    required List<Map<String, dynamic>> rows,
    List<SummaryItem> summary = const [],
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Title row (bold, merged across the column count).
    final titleCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);
    sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(
            columnIndex: columns.length - 1, rowIndex: 0));

    // Optional summary block: one row per summary item (label + value).
    var row = 2;
    for (final s in summary) {
      final labelCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      labelCell
        ..value = TextCellValue(s.label)
        ..cellStyle = CellStyle(bold: true);
      _writeValue(sheet, 1, row, s.value, s.isNumeric);
      row++;
    }
    if (summary.isNotEmpty) row++; // blank separator row

    // Header row.
    for (var c = 0; c < columns.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.value = TextCellValue(columns[c].label);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#DDEBF7'),
      );
    }

    // Data rows.
    for (var r = 0; r < rows.length; r++) {
      final dataRow = row + 1 + r;
      for (var c = 0; c < columns.length; c++) {
        final col = columns[c];
        _writeValue(sheet, c, dataRow, rows[r][col.key], col.isNumeric);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Excel export failed: encoder returned null');
    }
    return Uint8List.fromList(bytes);
  }

  void _writeValue(
      Sheet sheet, int column, int row, Object? value, bool isNumeric) {
    final cell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row));
    if (value == null) {
      cell.value = TextCellValue('');
      return;
    }
    if (isNumeric && value is num) {
      cell.value = DoubleCellValue(
          (value * 100).roundToDouble() / 100);
      return;
    }
    cell.value = TextCellValue('$value');
  }
}
