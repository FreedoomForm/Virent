import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsAuthPage extends ConsumerWidget {
  const LogsAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
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
                    Text('Entries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
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
                  color: const Color(0xFFFAFAFA),
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
                  child: ListView(
                    children: [
                      _authRow('1072280', '296601', '998910087575', '172.64.198.105', '19 июн 2026, 13:59', '213214', true),
                      _authRow('1072279', '', '998910087575', '172.64.200.120', '19 июн 2026, 13:59', '213214', true),
                      _authRow('1072278', '296600', '998907316009', '172.64.200.120', '19 июн 2026, 13:09', '659616', true),
                      _authRow('1072277', '', '998907316009', '162.158.172.91', '19 июн 2026, 13:09', '659616', true),
                      _authRow('1072276', '296599', '998901853058', '162.158.172.91', '19 июн 2026, 13:04', '902002', true),
                      _authRow('1072275', '', '998901853058', '162.158.102.31', '19 июн 2026, 13:03', '902002', true),
                      _authRow('1072274', '242437', '998503013388', '162.158.102.31', '19 июн 2026, 12:45', '924820', true),
                      _authRow('1072273', '242437', '998503013388', '172.64.198.105', '19 июн 2026, 12:45', '924820', true),
                      _authRow('1072272', '286338', '998901896027', '172.70.46.127', '19 июн 2026, 12:31', '568184', true),
                      _authRow('1072271', '286338', '998901896027', '104.23.221.144', '19 июн 2026, 12:30', '568184', true),
                      _authRow('1072270', '296598', '998900394115', '162.158.172.91', '19 июн 2026, 12:20', '237563', true),
                      _authRow('1072269', '', '998900394115', '162.158.102.30', '19 июн 2026, 12:20', '912730', false),
                      _authRow('1072268', '', '998900394115', '162.158.102.30', '19 июн 2026, 12:19', '237563', true),
                      _authRow('1072267', '', '998900394115', '162.158.172.91', '19 июн 2026, 12:19', '912730', true),
                      _authRow('1072266', '296597', '998954932910', '172.69.155.209', '19 июн 2026, 12:07', '877799', true),
                      _authRow('1072265', '', '998954932910', '172.69.155.209', '19 июн 2026, 12:07', '877799', true),
                      _authRow('1072264', '296596', '998946371010', '172.64.200.120', '19 июн 2026, 11:53', '606734', true),
                      _authRow('1072263', '', '998946371010', '172.64.198.105', '19 июн 2026, 11:53', '606734', true),
                      _authRow('1072262', '296595', '998933849227', '172.64.200.120', '19 июн 2026, 10:25', '116738', true),
                      _authRow('1072261', '', '998933849227', '172.69.155.209', '19 июн 2026, 10:25', '116738', true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _authRow(String id, String client, String phone, String ip, String time, String smsCode, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD9E2EF)))),
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
}
