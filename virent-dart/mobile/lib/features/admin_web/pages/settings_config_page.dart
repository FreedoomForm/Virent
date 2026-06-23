import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_web_providers.dart';

class SettingsConfigPage extends ConsumerWidget {
  const SettingsConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(settingsConfigProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: \$e', style: const TextStyle(color: Colors.red))),
      data: (items) => Padding(
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Одноразовые SMS коды'),
                  _buildConfigRow('Длина кода', '6'),
                  _buildConfigRow('Таймаут после бана', '15', suffix: 'сек'),
                  _buildConfigRow('Кол-во запросов нового SMS', '10'),
                  _buildConfigRow('Таймаут между запросами', '1', suffix: 'мин'),
                  _buildConfigRow('Время жизни кода (TTL)', '180', suffix: 'сек'),
                  _buildConfigRow('Кол-во попыток ввода одного кода', '5'),
                  _buildConfigRow('Максимальное количество запросов SMS с одного IP', '10000'),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Версии приложения'),
                  _buildConfigRow('android', '2.6.7'),
                  _buildConfigRow('ios', '2.6.7'),
                  _buildConfigRow('androidbuild', '129'),
                  _buildConfigRow('iosbuild', '129'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Бесплатная бронь'),
                  _buildConfigRow('Кол-во бесплатных бронирований', '2'),
                  _buildConfigRow('Сбрасывать при начале поездки', '1'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

      ),
    );
  );
  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade100,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConfigRow(String label, String value, {String? suffix}) {
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
                    controller: TextEditingController(text: value),
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