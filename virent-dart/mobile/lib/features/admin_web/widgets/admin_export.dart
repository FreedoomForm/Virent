// admin_export.dart — CSV export utility for admin panel (zero deps).
// Generates CSV string that can be copied or saved.
// To save: connect to platform file picker or send via share intent.

import 'package:flutter/material.dart';

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
