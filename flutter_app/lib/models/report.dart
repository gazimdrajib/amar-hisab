/// Tabular report payload from GET /api/v1/reports/<name>.
/// Shape: { filters, columns: [{key, label, is_numeric}], rows: [...], summary: [{key, label, value, is_numeric}] }
class ReportTable {
  final Map<String, dynamic> filters;
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;
  final List<ReportSummaryItem> summary;

  const ReportTable({
    required this.filters,
    required this.columns,
    required this.rows,
    required this.summary,
  });

  factory ReportTable.fromJson(Map<String, dynamic> json) => ReportTable(
        filters: (json['filters'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v)) ??
            const {},
        columns: (json['columns'] as List?)
                ?.map((e) => ReportColumn.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        rows: (json['rows'] as List?)
                ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
                .toList() ??
            const [],
        summary: (json['summary'] as List?)
                ?.map((e) =>
                    ReportSummaryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  String summaryValue(String key, {String fallback = ''}) {
    for (final item in summary) {
      if (item.key == key) return item.value.toString();
    }
    return fallback;
  }

  double summaryNumber(String key) {
    for (final item in summary) {
      if (item.key == key) {
        return (item.value as num?)?.toDouble() ?? 0;
      }
    }
    return 0;
  }
}

class ReportColumn {
  final String key;
  final String label;
  final bool isNumeric;

  const ReportColumn({required this.key, required this.label, this.isNumeric = false});

  factory ReportColumn.fromJson(Map<String, dynamic> json) => ReportColumn(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        isNumeric: json['is_numeric'] == true,
      );
}

class ReportSummaryItem {
  final String key;
  final String label;
  final dynamic value;
  final bool isNumeric;

  const ReportSummaryItem({
    required this.key,
    required this.label,
    required this.value,
    this.isNumeric = false,
  });

  factory ReportSummaryItem.fromJson(Map<String, dynamic> json) =>
      ReportSummaryItem(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        value: json['value'],
        isNumeric: json['is_numeric'] == true,
      );
}
