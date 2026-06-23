import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class SettingsConfigPage extends ConsumerWidget {
  const SettingsConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncConfig = ref.watch(settingsConfigProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Конфиг', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
              child: asyncConfig.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
                data: (config) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Одноразовые SMS коды'),
                    _configRow('Длина кода', config['sms_code_length'] ?? '6'),
                    _configRow('Таймаут после бана', config['sms_ban_timeout'] ?? '15', suffix: 'сек'),
                    _configRow('Кол-во запросов нового SMS', config['sms_request_limit'] ?? '10'),
                    _configRow('Таймаут между запросами', config['sms_request_interval'] ?? '1', suffix: 'мин'),
                    _configRow('Время жизни кода (TTL)', config['sms_code_ttl'] ?? '180', suffix: 'сек'),
                    _configRow('Кол-во попыток ввода одного кода', config['sms_attempts'] ?? '5'),
                    _configRow('Максимальное количество запросов SMS с одного IP', config['sms_ip_limit'] ?? '10000'),

                    const SizedBox(height: 24),
                    _sectionTitle('Версии приложения'),
                    _configRow('android', config['android_version'] ?? '2.6.7'),
                    _configRow('ios', config['ios_version'] ?? '2.6.7'),
                    _configRow('androidbuild', config['android_build'] ?? '129'),
                    _configRow('iosbuild', config['ios_build'] ?? '129'),
                    
                    const SizedBox(height: 24),
                    _sectionTitle('Бесплатная бронь'),
                    _configRow('Кол-во бесплатных бронирований', config['free_booking_count'] ?? '2'),
                    _configRow('Сбрасывать при начале поездки', config['reset_on_ride_start'] ?? '1'),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _configRow(String label, dynamic value, {String? suffix}) {
    final display = value?.toString() ?? '';
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
                    controller: TextEditingController(text: display),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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
