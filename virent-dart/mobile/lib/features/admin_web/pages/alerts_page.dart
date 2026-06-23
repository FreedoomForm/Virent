import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Тревоги', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                const SizedBox(height: 12),
                // Filters
                Row(
                  children: [
                    const Text('Самокат', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 120,
                      height: 32,
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(onTap: () {}, child: Icon(Icons.close, size: 16, color: Colors.grey[500])),
                    const SizedBox(width: 12),
                    const Text('Типы тревог:', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 140,
                      height: 32,
                      child: DropdownButtonFormField<String>(
                        value: null,
                        items: const [],
                        onChanged: (_) {},
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _filterButton('Открыта', const Color(0xFF2ECC71)),
                    const SizedBox(width: 6),
                    _filterButton('Закрыта', const Color(0xFFE67E22)),
                    const SizedBox(width: 6),
                    _filterButton('Группировать', const Color(0xFF3498DB)),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text('Сбросить фильтр', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 4),
                          Icon(Icons.close, size: 14, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1200,
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: const Row(
                        children: [
                          SizedBox(width: 50, child: Text('Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('scooterId', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('alertType', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Rows
                    Expanded(
                      ref.watch(alertsListProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Ошибка: $e")),
                        data: (items) => ListView(
                          children: items.map((item) => _alertRowFromItem(item)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () { /* action */ },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  Widget _alertRow(IconData icon, Color iconColor, String scooterId, String type, String time, String status, Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 50, child: Icon(icon, color: iconColor, size: 20)),
          SizedBox(width: 120, child: Text(scooterId, style: const TextStyle(fontSize: 12, color: Color(0xFFE67E22)))),
          Expanded(child: Text(type, style: const TextStyle(fontSize: 12, color: Color(0xFF333333)))),
          SizedBox(width: 200, child: Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF333333)))),
          SizedBox(width: 150, child: Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF333333)))),
        ],
      ),
    );
  }

  /// Builds a row from provider data item.
  Widget _alertRowFromItem(Map<String, dynamic> item) {
    return _alertRow(
      item['icon']?.toString() ?? '',
      item['iconColor']?.toString() ?? '',
      item['scooterId']?.toString() ?? '',
      item['type']?.toString() ?? '',
      item['time']?.toString() ?? '',
      item['status']?.toString() ?? '',
      item['bgColor']?.toString() ?? '',
    );
  }

}
