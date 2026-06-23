import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_table_page.dart';

class TechFeedbackPage extends ConsumerWidget {
  const TechFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminTablePage(
      title: 'Фидбек Техников',
      provider: techFeedbackProvider,
      searchMatcher: (item, query) { return item.values.any((v) => v != null && v.toString().toLowerCase().contains(query.toLowerCase())); },
      columns: const [
        DataColumn(label: Text('Id')),
        DataColumn(label: Text('Tech')),
        DataColumn(label: Text('Scooter')),
        DataColumn(label: Text('Message')),
        DataColumn(label: Text('Rating')),
        DataColumn(label: Text('Created')),
      ],
      buildRow: (item) {
        final id = (item['id'] ?? '-').toString();
        final tech = (item['tech'] ?? item['technician'] ?? item['tech_id'] ?? '-').toString();
        final scooter = (item['scooter'] ?? item['scooter_id'] ?? '-').toString();
        final message = (item['message'] ?? item['text'] ?? item['comment'] ?? '-').toString();
        final rating = (item['rating'] ?? '-').toString();
        final created = (item['created'] ?? item['created_at'] ?? '-').toString();
        return DataRow(cells: [
          DataCell(Text(id)),
          DataCell(Text(tech)),
          DataCell(Text(scooter)),
          DataCell(Text(message)),
          DataCell(Text(rating)),
          DataCell(Text(created)),
          DataCell(TextButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 14), label: const Text('Просмотр'))),
        ]);
      },
    );
  }
}

final _techFeedbackPageSearchProvider = StateProvider<String>((ref) => '');
