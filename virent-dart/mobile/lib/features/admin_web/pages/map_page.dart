import '../widgets/admin_table_page.dart' show adminPrimaryColor, adminPrimaryForeground;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scootersListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Map Top Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Текущая карта: Частота аренд', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(onPressed: () => showAdminSnack(context, 'Режим карты: Общая'), child: const Text('Общая карта')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => showAdminSnack(context, 'Режим карты: Тепловая'), child: const Text('Тепловая карта')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => showAdminSnack(context, 'Режим карты: Частота аренд'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adminPrimaryColor, // Purple active
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Частота аренд'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => showAdminSnack(context, 'Режим карты: Группирование самокатов'), child: const Text('Группирование самокатов')),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Radio(value: 1, groupValue: 1, onChanged: (v) {}),
                      const Text('Старт аренд'),
                      Radio(value: 2, groupValue: 1, onChanged: (v) {}),
                      const Text('Конец аренд'),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
        // Dark Map Mockup
        Expanded(
          child: Container(
            color: const Color(0xFF2E2E2E), // Dark map background
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (e, _) => Center(child: Text('Ошибка: $e', style: const TextStyle(color: Colors.red))),
              data: (scooters) {
                if (scooters.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 100, color: Colors.white54),
                        SizedBox(height: 16),
                        Text('Mapbox Integration (Mockup)', style: TextStyle(color: Colors.white54, fontSize: 24)),
                        SizedBox(height: 24),
                        Text('Нет самокатов', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }
                // Simple representation of map bubbles grouped by status
                final onlineCount = scooters.where((s) {
                  final v = s['online'];
                  if (v == null) return false;
                  if (v is bool) return v;
                  final st = v.toString().toLowerCase();
                  return st == '1' || st == 'true' || st == 'yes';
                }).length;
                final offlineCount = scooters.length - onlineCount;
                final inRentCount = scooters.where((s) {
                  final st = (s['status'] ?? '').toString().toLowerCase();
                  return st.contains('rent') || st.contains('busy');
                }).length;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 100, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text('Mapbox Integration (Mockup)', style: TextStyle(color: Colors.white54, fontSize: 24)),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 24,
                        children: [
                          CircleAvatar(radius: 40, backgroundColor: Colors.pinkAccent, child: Text('$inRentCount')),
                          CircleAvatar(radius: 30, backgroundColor: Colors.lightGreen, child: Text('$onlineCount')),
                          CircleAvatar(radius: 20, backgroundColor: Colors.lightBlue, child: Text('$offlineCount')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}
