// iot_page.dart — Virent admin IoT command center (web panel).
//
// Ported from the old admin_iot_screen.dart. Sends raw IoT commands to
// a scooter via its MAC address — lock, unlock, alarm, reboot, locate,
// led_on, led_off. Shows the last 20 commands in a history table.
//
// Wired to [sendIoTCommandAction] (POST /iot/command) and
// [iotLogsProvider] (GET /admin/iot/logs).

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/configs/theme/app_colors.dart';
import '../admin_web_providers.dart';

class IotPage extends ConsumerStatefulWidget {
  const IotPage({super.key});

  @override
  ConsumerState<IotPage> createState() => _IotPageState();
}

class _IotPageState extends ConsumerState<IotPage> {
  final _macController = TextEditingController();
  final _commands = <Map<String, dynamic>>[];

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  Future<void> _sendCommand(String command) async {
    final mac = _macController.text.trim();
    if (mac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите MAC-адрес самоката')),
      );
      return;
    }
    try {
      await ref.read(sendIoTCommandAction)(mac, command);
      setState(() {
        _commands.insert(0, {
          'mac': mac,
          'command': command,
          'at': DateTime.now().toIso8601String().substring(0, 19),
          'status': 'sent',
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Команда "$command" отправлена на $mac')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(iotLogsProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IoT — Командный центр',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter')),
          const SizedBox(height: 24),

          // MAC input + quick commands
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Отправить команду',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _macController,
                    decoration: InputDecoration(
                      labelText: 'MAC-адрес самоката',
                      hintText: '00:11:22:33:44:55',
                      prefixIcon: const Icon(LucideIcons.bluetooth, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _commandBtn('Блокировка', LucideIcons.lock, () => _sendCommand('lock')),
                      _commandBtn('Разблокировка', LucideIcons.lock_open, () => _sendCommand('unlock')),
                      _commandBtn('Сигнал', LucideIcons.bell, () => _sendCommand('alarm_on')),
                      _commandBtn('Выкл. сигнал', LucideIcons.bell_off, () => _sendCommand('alarm_off')),
                      _commandBtn('Перезагрузка', LucideIcons.refresh_cw, () => _sendCommand('reboot')),
                      _commandBtn('Найти', LucideIcons.map_pin, () => _sendCommand('locate')),
                      _commandBtn('Свет вкл.', LucideIcons.lightbulb, () => _sendCommand('led_on')),
                      _commandBtn('Свет выкл.', LucideIcons.lightbulb_off, () => _sendCommand('led_off')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // History
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('История команд',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter')),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(iotLogsProvider),
                          icon: const Icon(LucideIcons.refresh_cw, size: 16),
                          label: const Text('Обновить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: logsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Ошибка: $e')),
                        data: (serverLogs) {
                          // Merge local + server logs
                          final all = [..._commands, ...serverLogs];
                          if (all.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.inbox, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('Нет отправленных команд',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F9F9)),
                              columns: const [
                                DataColumn(label: Text('MAC')),
                                DataColumn(label: Text('Команда')),
                                DataColumn(label: Text('Время')),
                                DataColumn(label: Text('Статус')),
                              ],
                              rows: all.take(50).map((log) {
                                return DataRow(cells: [
                                  DataCell(Text('${log['mac'] ?? log['scooter_mac'] ?? '-'}',
                                      style: const TextStyle(fontFamily: 'monospace'))),
                                  DataCell(Text('${log['command'] ?? '-'}')),
                                  DataCell(Text('${log['at'] ?? log['created_at'] ?? '-'}')),
                                  DataCell(_StatusChip(status: '${log['status'] ?? 'sent'}')),
                                ]);
                              }).toList(),
                            ),
                          );
                        },
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

  Widget _commandBtn(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'sent' || status == 'delivered' || status == 'success') {
      color = AppColors.success;
    } else if (status == 'pending' || status == 'queued') {
      color = AppColors.warning;
    } else if (status == 'failed' || status == 'error') {
      color = AppColors.danger;
    } else {
      color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter')),
    );
  }
}
