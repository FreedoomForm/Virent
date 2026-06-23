import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsScooterChangesPage extends ConsumerWidget {
  const LogsScooterChangesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsScooterChangesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Логи Изменений Самокатов', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 10,000 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _labeledInput('Номер', 150),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2000,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 150, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Номер самоката', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('ID текущего заказа', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('ID модели', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Онлайн', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('columns.elastic_car_change_log.scooter_action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('ID компании', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Кто внёс изменения', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Геозоны', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Время обновления', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Время создания', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Флеспи ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Imei', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Время завершения последнего заказа', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Описание', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _scooterLog('Y_4f354BotTmlSvb--dq', '1759', '', '7', '1', '16', 'node', '[22,147,221,400,419,420,421]', '19 июн 2026, 14:04', '11 дек 2023, 23:57:11', '5647690', '867844062312833', '16 июн 2026, 20:43:47'),
                          _scooterLog('Sf4f354BotTmlSvb7-fv', '977', '769208', '7', '1', '16', 'node', '[22,147,215,400,419,420,421]', '19 июн 2026, 14:04', '09 мая 2023, 03:04:27', '5243381', '867844060831255', '19 июн 2026, 13:01:58'),
                          _scooterLog('Rv4f354BotTmlSvb7-ez', '806', '769209', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:04', '08 мая 2023, 23:55:39', '5335877', '867844060823575', '18 июн 2026, 04:29:29'),
                          _scooterLog('yP4f354BotTmlSvbteap', '904', '', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:04', '09 мая 2023, 01:44:39', '5243236', '867844060829424', '19 июн 2026, 02:49:36'),
                          _scooterLog('xv4f354BotTmlSvbteaT', '1757', '', '7', '1', '16', 'node', '[22,69,147,215,400,419,420,421]', '19 июн 2026, 14:04', '11 дек 2023, 23:57:11', '5647699', '867844062289908', '19 июн 2026, 06:26:31'),
                          _scooterLog('xP4f354BotTmlSvbteZ9', '806', '769209', '7', '1', '16', 'node', '[22,147,293,400,419,420,421]', '19 июн 2026, 14:04', '08 мая 2023, 23:55:39', '5335877', '867844060823575', '18 июн 2026, 04:29:29'),
                          _scooterLog('jf4f354BotTmlSvboebM', '977', '769208', '7', '1', '16', 'node', '[22,69,147,215,400,419,420,421]', '19 июн 2026, 14:04', '09 мая 2023, 03:04:27', '5243381', '867844060831255', '19 июн 2026, 13:01:58'),
                          _scooterLog('HP4f354BotTmlSvbduaX', '806', '769209', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:04', '08 мая 2023, 23:55:39', '5335877', '867844060823575', '18 июн 2026, 04:29:29'),
                          _scooterLog('_4f354BotTmlSvbZ-Up', '977', '769208', '7', '1', '16', 'node', '[22,69,147,400,419,420,421]', '19 июн 2026, 14:03', '09 мая 2023, 03:04:27', '5243381', '867844060831255', '19 июн 2026, 13:01:58'),
                          _scooterLog('Iv4f354BotTmlSvbDeWB', '945', '', '7', '1', '16', 'node', '[22,147,221,400,419,420,421]', '19 июн 2026, 14:03', '09 мая 2023, 02:42:02', '5243328', '867844060829903', '16 июн 2026, 08:05:08'),
                          _scooterLog('9f4e354BotTmlSvb9eTk', '976', '', '7', '1', '16', 'node', '[22,147,221,400,419,420,421]', '19 июн 2026, 14:03', '09 мая 2023, 03:04:09', '5243380', '867844060823500', '19 июн 2026, 06:22:46'),
                          _scooterLog('Ov4e354BotTmlSvb5uRq', '976', '', '7', '1', '16', 'node', '[22,147,221,400,419,420,421]', '19 июн 2026, 14:03', '09 мая 2023, 03:04:09', '5243380', '867844060823500', '19 июн 2026, 06:22:46'),
                          _scooterLog('hf4e354BotTmlSvbXuti', '977', '769208', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:03', '09 мая 2023, 03:04:27', '5243381', '867844060831255', '19 июн 2026, 13:01:58'),
                          _scooterLog('E_4e354BotTmlSvbl-S7', '1790', '769207', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:03', '11 дек 2023, 23:57:11', '5647774', '867844062311694', '19 июн 2026, 00:50:43'),
                          _scooterLog('1f4e354BotTmlSvbB-kT', '1734', '769205', '7', '1', '16', 'node', '[22,147,400,419,420,421]', '19 июн 2026, 14:02', '11 дек 2023, 23:57:11', '5647760', '868070043236367', '19 июн 2026, 01:32:58'),
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

  Widget _scooterLog(String id, String num, String orderId, String model, String online, String compId, String user, String geo, String updTime, String creTime, String flespi, String imei, String lastOrder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(id, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 100, child: Text(num, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 120, child: Text(orderId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 80, child: Text(model, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 80, child: Text(online, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 250, child: Text('', style: TextStyle(fontSize: 11))), // empty action col
          SizedBox(width: 100, child: Text(compId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 120, child: Text(user, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(geo, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(updTime, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(creTime, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(flespi, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(imei, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 200, child: Text(lastOrder, style: const TextStyle(fontSize: 11))),
          const Expanded(child: Text('', style: TextStyle(fontSize: 11))), // Description
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
