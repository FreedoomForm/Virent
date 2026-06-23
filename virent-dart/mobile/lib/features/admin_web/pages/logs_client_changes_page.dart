import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsClientChangesPage extends ConsumerWidget {
  const LogsClientChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsClientChangesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Colors.white,
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
                    Text('Показано 1 до 20 из 10,000 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _labeledInput('ClientID', 150),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1800,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 180, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('ID клиента', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Доступные тарифы', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 350, child: Text('Токен', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Бонусы', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Группы', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Активный', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Заблокирован', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Удален', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Новый', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Время создания лога', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _clientLog('e_2z3p4BotTmlSvbfvj0', '170471', '', 'RjiEvtF83T1ipoJptFarmCPED1c7oONoEx0j8K6f[...]', '380,700', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 12:06'),
                          _clientLog('cf2x3p4BotTmlSvbKvM9', '170471', '', 'RjiEvtF83T1ipoJptFarmCPED1c7oONoEx0j8K6f[...]', '706,500', '', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 12:03'),
                          _clientLog('a_4f354BotTmlSvbkuYU', '296601', '[21,24,34,40,41,42]', 'qxVW1H9t9cLvqEuhDePnEmasshQxF0SSp0U8vOcq[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:04'),
                          _clientLog('i_4e354BotTmlSvbyeSS', '157056', '[21,24,34]', 'Em9844NqzUzJz8kOklCmniMHIV5RzwpRukJXWvb[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:03'),
                          _clientLog('NP4e354BotTmlSvbpuR0', '296601', '[21,24,34,40,41,42]', 'qxVW1H9t9cLvqEuhDePnEmasshQxF0SSp0U8vOcq[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:03'),
                          _clientLog('tf4d354BotTmlSvb-eKP', '249529', '[18,21,22,24,34,39]', 'O5Plkj4D5nzMWKG3UENfLANyBV9MuND9pYicXl0O[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:02'),
                          _clientLog('hv4c354BotTmlSvbmt_k', '248798', '[18,21,22,24,34,39]', 'vsWi4YfGdDhHqLJiqnzSr7MdynC1lH5uLEqwbWO[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:00'),
                          _clientLog('lP4c354BotTmlSvbv_v', '232400', '[21,24,34,40,41,42]', '8NdliBtgAxyMNQcHnuKl8TTUddbsZrdURl7TA2a[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 09:00'),
                          _clientLog('ZP4a354BotTmlSvbBNnX', '232400', '[21,24,34,40,41,42]', '8NdliBtgAxyMNQcHnuKl8TTUddbsZrdURl7TA2a[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:58'),
                          _clientLog('N_4Z354BotTmlSvibhg9', '240529', '[21,24,34,40,41,42]', '5ol04GFvHEz7SKVbB7NfT1btnLuiQmzUXSSsPofs[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:57'),
                          _clientLog('Hv4Z354BotTmlSvbfNg_J', '249529', '[18,21,22,24,34,39]', 'O5Plkj4D5nzMWKG3UENfLANyBV9MuND9pYicXl0O[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:57'),
                          _clientLog('_v4Z354BotTmlSvbbtf4', '258151', '', '0ofiUSh06P8Wa7R9svsdqslpxS5Ac9bcGWsvVM[...]', '0', '', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:57'),
                          _clientLog('Jv4Z354BotTmlSvbHdcW', '249529', '[18,21,22,24,34,39]', 'O5Plkj4D5nzMWKG3UENfLANyBV9MuND9pYicXl0O[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:57'),
                          _clientLog('lf4Y354BotTmlSvbD9Uc', '249529', '[18,21,22,24,34,39]', 'O5Plkj4D5nzMWKG3UENfLANyBV9MuND9pYicXl0O[...]', '', '[]', 'Да', 'Нет', 'Нет', 'Нет', '19 июн 2026, 08:56'),
                        ],
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
      },
    );
  }

  Widget _clientLog(String id, String clientId, String tariffs, String token, String bonus, String groups, String isActive, String isBlocked, String isDeleted, String isNew, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(clientId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 150, child: Text(tariffs, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 350, child: Text(token, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(bonus, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(groups, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(isActive, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(isBlocked, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(isDeleted, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(isNew, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(date, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }
}
