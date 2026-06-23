import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class RaiderLogsPage extends ConsumerWidget {
  const RaiderLogsPage({super.key});

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
                const Text('Логи Режим Raider', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2200,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 40, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('ID самоката', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Откуда произошло переключение', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Координаты активации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Время активации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 180, child: Text('Время телефона активации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Откуда произошло переключение', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 40, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Координаты деактивации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Время деактивации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 180, child: Text('Время телефона деактивации', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ref.watch(iotLogsProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Ошибка: $e')),
                        data: (items) => items.isEmpty
                          ? const Center(child: Text('В таблице нет доступных данных', style: TextStyle(fontSize: 11, color: Colors.grey)))
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 40, child: Text(item['id']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 40, child: Text(item['id2']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 100, child: Text(item['scooter_id']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 250, child: Text(item['switch_from']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 150, child: Text(item['coords_act']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 150, child: Text(item['time_act']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 180, child: Text(item['phone_time_act']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 250, child: Text(item['switch_from2']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 40, child: Text(item['id3']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 150, child: Text(item['coords_deact']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 150, child: Text(item['time_deact']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 180, child: Text(item['phone_time_deact']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      SizedBox(width: 80, child: Text(item['action']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                                      const SizedBox(width: 150),
                                    ],
                                  ),
                                );
                              },
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
}
