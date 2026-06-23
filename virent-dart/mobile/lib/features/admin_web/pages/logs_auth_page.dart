import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsAuthPage extends ConsumerWidget {
  const LogsAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                    SizedBox(width: 12),
                    Text('Показано 1 до 20 из 452,999 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                SizedBox(
                  width: 200,
                  height: 32,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск:',
                      hintStyle: const TextStyle(fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 100, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Ip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 250, child: Text('Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Sms code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Is success', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  ref.watch(auditLogProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Ошибка: $e")),
                    data: (items) => ListView(
                      children: items.map((item) => _authRowFromItem(item)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _authRow(String id, String client, String phone, String ip, String time, String smsCode, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(client, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(phone, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(ip, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 250, child: Text(time, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(smsCode, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 250),
              child: Icon(
                isSuccess ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: isSuccess ? Colors.green.shade400 : Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row from provider data item.
  Widget _authRowFromItem(Map<String, dynamic> item) {
    return _authRow(
      item['id']?.toString() ?? '',
      item['client']?.toString() ?? '',
      item['phone']?.toString() ?? '',
      item['ip']?.toString() ?? '',
      item['time']?.toString() ?? '',
      item['smsCode']?.toString() ?? '',
      item['isSuccess']?.toString() ?? '',
    );
  }

}
