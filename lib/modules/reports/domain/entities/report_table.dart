/// A typed column description used by report projections.
///
/// `key` is the JSON key used in row maps, `label` the human-friendly column
/// header used by Excel/PDF export.
class ReportColumn {
  const ReportColumn(this.key, this.label, {this.isNumeric = false});

  /// JSON key of the cell value in each row map.
  final String key;

  /// Human-friendly column header for export.
  final String label;

  /// Numeric columns are right-aligned and formatted with 2 decimals in
  /// Excel/PDF export.
  final bool isNumeric;

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'is_numeric': isNumeric,
      };
}

/// A tabular report result: ordered columns plus row maps.
class ReportTable {
  const ReportTable({required this.columns, required this.rows});

  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;

  Map<String, dynamic> toJson() => {
        'columns': columns.map((c) => c.toJson()).toList(),
        'rows': rows,
      };
}

/// A scalar summary block (key/label + value + numeric flag).
class SummaryItem {
  const SummaryItem(this.key, this.label, this.value, {this.isNumeric = true});

  final String key;
  final String label;
  final Object? value;
  final bool isNumeric;

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'is_numeric': isNumeric,
      };
}
