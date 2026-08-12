import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_exception.dart';
import '../../providers/reports_providers.dart';
import '../../widgets/common.dart';

/// Reports for sales / purchases / inventory with filters + Excel/PDF export.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _report = 'sales';
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  bool _exporting = false;

  ReportQuery get _query => ReportQuery(from: _from, to: _to);

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final file = await ref.read(reportExportProvider(
              (name: _report, format: format, query: _query))
          .future);
      if (!mounted) return;
      if (file.bytes.isNotEmpty && !file.path.startsWith('blob:')) {
        await Share.shareXFiles([XFile(file.path)],
            text: 'Amar Hisab $_report report');
      }
      if (!mounted) return;
      showSnack(context, 'Exported ${file.filename}');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = (name: _report, query: _query);
    final report = ref.watch(reportProvider(params));
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export to Excel',
            onPressed: _exporting ? null : () => _export('excel'),
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.table_view_outlined),
          ),
          IconButton(
            tooltip: 'Export to PDF',
            onPressed: _exporting ? null : () => _export('pdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sales', label: Text('Sales')),
                  ButtonSegment(value: 'purchases', label: Text('Purchases')),
                  ButtonSegment(value: 'inventory', label: Text('Inventory')),
                ],
                selected: {_report},
                onSelectionChanged: (s) =>
                    setState(() => _report = s.first),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickFrom,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(df.format(_from)),
              ),
              const Text(' — '),
              TextButton.icon(
                onPressed: _pickTo,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(df.format(_to)),
              ),
            ]),
          ),
          Expanded(
            child: report.when(
              data: (table) => Column(
                children: [
                  if (table.summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: table.summary
                                .map((s) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(s.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        Text('${s.value}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: table.rows.isEmpty
                        ? const EmptyView(
                            icon: Icons.bar_chart,
                            title: 'No data in the selected period')
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: table.columns
                                    .map((c) => DataColumn(
                                        label: Text(c.label),
                                        numeric: c.isNumeric))
                                    .toList(),
                                rows: table.rows
                                    .map((row) => DataRow(
                                          cells: table.columns
                                              .map((c) => DataCell(Text(
                                                  '${row[c.key] ?? ''}')))
                                              .toList(),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(reportProvider(params))),
            ),
          ),
        ],
      ),
    );
  }
}
