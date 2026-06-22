// scooter_detail_page.dart — Detailed scooter view with telemetry + commands.
//
// Shows: telemetry history, command log, firmware version, maintenance schedule.
// Fully local — data from embedded server SQLite.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../widgets/admin_dialogs.dart';

class ScooterDetailPage extends ConsumerWidget {
  const ScooterDetailPage({super.key, this.scooterId});
  final String? scooterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scootersListProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (scooters) {
        final s = scooterId != null
            ? scooters.firstWhere((s) => (s['id'] ?? s['scooter_id'])?.toString() == scooterId,
                orElse: () => <String, dynamic>{})
            : scooters.isNotEmpty ? scooters.first : <String, dynamic>{};

        if (s.isEmpty) {
          return const Center(child: Text('Самокат не найден'));
        }

        final id = (s['id'] ?? s['scooter_id'] ?? '-').toString();
        final name = (s['name'] ?? s['model'] ?? id).toString();
        final battery = (s['battery'] ?? s['battery_level'] ?? '-').toString();
        final status = (s['status'] ?? '-').toString();
        final lat = (s['lat'] ?? s['latitude'] ?? 41.3111).toString();
        final lng = (s['lng'] ?? s['longitude'] ?? 69.2406).toString();
        final transport = (s['transport'] ?? 'http').toString();
        final firmware = (s['firmware'] ?? s['firmware_version'] ?? '1.0.0').toString();
        final odometer = (s['odometer'] ?? s['total_km'] ?? '0').toString();
        final locked = s['locked'] == true || s['is_locked'] == true;
        final qr = (s['qr_code'] ?? s['gosnomer'] ?? '-').toString();

        // Fetch telemetry from server (empty if not yet loaded)
        final telemetryLogs = ref.watch(telemetryLogProvider);
        final telemetry = telemetryLogs is AsyncData
            ? telemetryLogs.value
                .where((l) => (l['scooter_id'] ?? l['mac'] ?? '').toString() == id)
                .take(20)
                .map((l) => <String, String>{
                  'time': (l['created_at'] ?? l['timestamp'] ?? '-').toString(),
                  'battery': (l['battery'] ?? l['battery_level'] ?? '-').toString(),
                  'speed': (l['speed'] ?? '0').toString(),
                  'status': (l['status'] ?? 'idle').toString(),
                }).toList()
            : <Map<String, String>>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status == 'online' || status == 'active' ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(status.toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: status == 'active' ? Colors.green : Colors.grey)),
              ]),
              Text('ID: $id • QR: $qr', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),

              // ── Stats grid ──
              Row(children: [
                _statCard('🔋 Батарея', '$battery%', battery is String && int.tryParse(battery) != null && int.parse(battery) < 20 ? Colors.red : Colors.green),
                const SizedBox(width: 12),
                _statCard('🛞 Пробег', '$odometer км', Colors.blue),
                const SizedBox(width: 12),
                _statCard('📡 Транспорт', transport, Colors.purple),
                const SizedBox(width: 12),
                _statCard('🔒 Замок', locked ? 'LOCK' : 'OPEN', locked ? Colors.red : Colors.green),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _statCard('📍 Координаты', '${double.tryParse(lat)?.toStringAsFixed(4) ?? lat}, ${double.tryParse(lng)?.toStringAsFixed(4) ?? lng}', Colors.orange),
                const SizedBox(width: 12),
                _statCard('⚙️ Прошивка', 'v$firmware', Colors.teal),
              ]),
              const SizedBox(height: 24),

              // ── Quick commands ──
              const Text('Быстрые команды', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _cmdBtn('Lock', Icons.lock, const Color(0xFFEF4444)),
                _cmdBtn('Unlock', Icons.lock_open, const Color(0xFF22C55E)),
                _cmdBtn('Alarm', Icons.notifications_active, const Color(0xFFF59E0B)),
                _cmdBtn('Reboot', Icons.restart_alt, const Color(0xFF6366F1)),
                _cmdBtn('Locate', Icons.gps_fixed, const Color(0xFF8B5CF6)),
              ]),
              const SizedBox(height: 24),

              // ── Telemetry table ──
              const Text('📈 Телеметрия (последние 20 записей)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    columns: const [
                      DataColumn(label: Text('Время')),
                      DataColumn(label: Text('Батарея')),
                      DataColumn(label: Text('Скорость')),
                      DataColumn(label: Text('Статус')),
                    ],
                    rows: telemetry.map((t) => DataRow(cells: [
                      DataCell(Text(t['time'] ?? '-', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${t['battery']}%', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${t['speed']} км/ч', style: const TextStyle(fontSize: 12))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t['status'] == 'moving' ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t['status'] ?? '-', style: const TextStyle(fontSize: 11)),
                      )),
                    ])).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _cmdBtn(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<Map<String, String>> _mockTelemetry() => List.generate(20, (i) {
    final min = 20 - i;
    return {
      'time': '14:${min.toString().padLeft(2, "0")}',
      'battery': '${85 - i * 4}',
      'speed': '${[0, 0, 12, 15, 18, 20, 15, 0, 0, 8, 14, 18, 22, 18, 10, 0, 0, 5, 15, 20][i % 20]}',
      'status': i % 5 == 0 ? 'idle' : 'moving',
    };
  });
}
