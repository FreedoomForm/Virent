// admin_export.dart — CSV export utility for admin panel (zero deps).
// Generates CSV string that can be copied or saved.
// To save: connect to platform file picker or send via share intent.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows an export dialog letting the user pick a format (csv/json/xlsx) and
/// which [fields] to include. When the user taps "Экспорт", [onExport] is
/// invoked with the chosen values.
Future<void> showAdminExportDialog(
  BuildContext context, {
  required String title,
  required List<String> fields,
  required Future<void> Function(String format, List<String> selectedFields) onExport,
}) async {
  final selected = <String>{...fields};
  String format = 'csv';
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Формат',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ['csv', 'json', 'xlsx'].map((f) {
                        return ChoiceChip(
                          label: Text(f.toUpperCase()),
                          selected: format == f,
                          onSelected: (s) {
                            if (s) setState(() => format = f);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Поля',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: fields.map((f) {
                        return FilterChip(
                          label: Text(f),
                          selected: selected.contains(f),
                          onSelected: (s) {
                            setState(() {
                              if (s) {
                                selected.add(f);
                              } else {
                                selected.remove(f);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        onExport(format, selected.toList());
                      },
                child: const Text('Экспорт'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Generates CSV from data and copies to clipboard.
/// User can paste into Excel / Google Sheets.
Future<void> exportCsv(
  BuildContext context,
  List<Map<String, dynamic>> data,
  String filename, {
  List<String>? columns,
}) async {
  final keys = columns ?? (data.isNotEmpty ? data.first.keys.toList() : <String>[]);
  final buffer = StringBuffer();
  buffer.writeln(keys.join(','));

  for (final row in data) {
    buffer.writeln(keys.map((k) {
      var v = '${row[k] ?? ''}';
      if (v.contains(',') || v.contains('"')) {
        v = '"${v.replaceAll('"', '""')}"';
      }
      return v;
    }).join(','));
  }

  await Clipboard.setData(ClipboardData(text: buffer.toString()));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV скопирован в буфер ($filename — ${data.length} строк)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Export button widget for admin tables.
class ExportCsvButton extends StatelessWidget {
  const ExportCsvButton({
    super.key,
    required this.data,
    required this.filename,
    this.columns,
    this.label = 'CSV',
  });

  final List<Map<String, dynamic>> data;
  final String filename;
  final List<String>? columns;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => exportCsv(context, data, filename, columns: columns),
      icon: const Icon(Icons.download, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
