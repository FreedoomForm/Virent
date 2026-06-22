import '../widgets/admin_table_page.dart' show adminPrimaryColor, adminPrimaryForeground;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;

class SettingsConfigPage extends ConsumerStatefulWidget {
  const SettingsConfigPage({super.key});

  @override
  ConsumerState<SettingsConfigPage> createState() => _SettingsConfigPageState();
}

class _SettingsConfigPageState extends ConsumerState<SettingsConfigPage> {
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key, String fallback) {
    return _controllers.putIfAbsent(
        key, () => TextEditingController(text: fallback));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(settingsConfigProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Конфиг', style: TextStyle(fontSize: 24)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(settingsConfigProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Обновить'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 16),
                label: Text(_saving ? 'Сохранение...' : 'Сохранить'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: adminPrimaryColor,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade300)),
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Ошибка: $e',
                        style: const TextStyle(color: Colors.red))),
                data: (config) {
                  String s(String key, [String fallback = '']) {
                    final v = config[key];
                    if (v == null) return fallback;
                    return v.toString();
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('Одноразовые SMS коды'),
                      _buildConfigRow('sms_code_length', 'Длина кода',
                          s('sms_code_length', '6')),
                      _buildConfigRow('ban_timeout', 'Таймаут после бана',
                          s('ban_timeout', '15'),
                          suffix: 'сек'),
                      _buildConfigRow('sms_request_count',
                          'Кол-во запросов нового SMS',
                          s('sms_request_count', '10')),
                      _buildConfigRow('sms_request_timeout',
                          'Таймаут между запросами',
                          s('sms_request_timeout', '1'),
                          suffix: 'мин'),
                      _buildConfigRow('sms_code_ttl', 'Время жизни кода (TTL)',
                          s('sms_code_ttl', '180'),
                          suffix: 'сек'),
                      _buildConfigRow('sms_code_attempts',
                          'Кол-во попыток ввода одного кода',
                          s('sms_code_attempts', '5')),
                      _buildConfigRow('sms_max_per_ip',
                          'Макс. запросов SMS с одного IP',
                          s('sms_max_per_ip', '10000')),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Версии приложения'),
                      _buildConfigRow('android_version', 'android',
                          s('android_version', '2.6.7')),
                      _buildConfigRow('ios_version', 'ios',
                          s('ios_version', '2.6.7')),
                      _buildConfigRow('android_build', 'androidbuild',
                          s('android_build', '129')),
                      _buildConfigRow('ios_build', 'iosbuild',
                          s('ios_build', '129')),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Бесплатная бронь'),
                      _buildConfigRow('free_bookings_count',
                          'Кол-во бесплатных бронирований',
                          s('free_bookings_count', '2')),
                      _buildConfigRow('reset_on_trip_start',
                          'Сбрасывать при начале поездки',
                          s('reset_on_trip_start', '1')),
                    ],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        body[entry.key] = entry.value.text;
      }
      await ref.read(apiClientProvider).put('/admin/settings/config', body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Конфигурация сохранена')));
        ref.invalidate(settingsConfigProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConfigRow(
      String key, String label, String value,
      {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controllerFor(key, value),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  Text(suffix, style: const TextStyle(color: Colors.grey)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
