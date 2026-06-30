import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class SettingsConfigPage extends ConsumerWidget {
  const SettingsConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsConfigProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
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

          const SizedBox(height: 16),
          _buildSectionTitle('configeditor.sms_operators.sectiontitle'),
          _buildSubtitle('configeditor.sms_operators.megacome.sectiontitle'),
          _buildConfigRow('configeditor.sms_operators.megacome.item', '0'),
          _buildConfigRow('configeditor.sms_operators.megacome.item', 'xxxxxxxxx'),

          _buildSubtitle('configeditor.sms_operators.ucell.sectiontitle'),
          _buildConfigRow('configeditor.sms_operators.ucell.item', 'xxxxxxx'),
          _buildConfigRow('configeditor.sms_operators.ucell.item', 'xxxxxxxxx'),

          _buildSubtitle('configeditor.sms_operators.beeline.sectiontitle'),
          _buildConfigRow('configeditor.sms_operators.beeline.item', 'xxxxxxxxx'),
          _buildConfigRow('configeditor.sms_operators.beeline.item', 'xxxxxxx'),

          _buildSubtitle('configeditor.sms_operators.other.sectiontitle'),
          _buildConfigRow('configeditor.sms_operators.other.item', 'xxxxxxx'),
          _buildConfigRow('configeditor.sms_operators.other.item', 'xxxxxxxxxx'),

          const SizedBox(height: 16),
          _buildSectionTitle('Версии приложения'),
          _buildConfigRow('android', '2.6.7'),
          _buildConfigRow('ios', '2.6.7'),
          _buildConfigRow('androidbuild', '129'),
          _buildConfigRow('iosbuild', '129'),

          const SizedBox(height: 16),
          _buildSectionTitle('Бесплатная бронь'),
          _buildConfigRow('Кол-во бесплатных бронирований', '2'),
          _buildConfigRow('Сбрасывать при начале поездки', '1', suffix: '≈'),
          _buildConfigRow('Сбрасывать после', '86400', suffix: 'сек'),

          const SizedBox(height: 16),
          _buildSectionTitle('Настройки'),
          _buildConfigRow('Требуем селфи в начале аренды', '0'),
          _buildConfigRow('Количество фото при завершении аренды', '0'),
          _buildConfigRow('Актуальная версия договора', '2'),
          _buildConfigRow('Стоимость турбо-проверки', '0', suffix: 'коп'),
          _buildConfigRow('Премия фотографа', '200', suffix: 'uzs'),
          _buildConfigRow('Минимальная транзакция', '200', suffix: 'коп'),
          _buildConfigRow('Отменять заказ при неудачном первом холде', '1'),
          _buildConfigRow('ID компании по умолчанию', '1'),
          _buildConfigRow('configeditor.settings.default_client_id', '14'),
          _buildConfigRow('configeditor.settings.stats_start_date', '2020-05-01'),
          _buildConfigRow('ajax кнопки групп машин', 'на линии, на складе, в техничке'),
          _buildConfigRow('Фейк тариф для не премиумов', 'test'),
          _buildConfigRow('Xiaomi check', '1'),
          _buildConfigRow('Максимальное число заказов', '5'),
          _buildConfigRow('configeditor.settings.allow_without_inspect', '1'),
          _buildConfigRow('configeditor.settings.add_bonus_after_finish', '0'),
          _buildConfigRow('configeditor.settings.password_for_chat', 'ScAdg2dVzA'),

          const SizedBox(height: 16),
          _buildSectionTitle('Адресные настройки'),
          _buildConfigRow('Текущий сервер', 'scoots2.virent.uz'),
          _buildConfigRow('Адрес Java', 'http://127.0.0.1:8081/api/'),
          _buildConfigRow('configeditor.adresses.java_log', '/var/www/flutter/data/java/err_log.txt'),

          const SizedBox(height: 16),
          _buildSectionTitle('Штрафы'),
          _buildConfigRow('Штраф за дрифт', '0'),
          _buildConfigRow('Штраф за скорость', '0'),

          const SizedBox(height: 16),
          _buildSectionTitle('Регистрация'),
          _buildConfigRow('Стоимость регистрации', '0'),
          _buildConfigRow('Бонусы при регистрации', '0'),
          _buildConfigRow('configeditor.registration.telegram_bonus', '0'),
          _buildConfigRow('Требуем middleName', '0'),
          _buildConfigRow('Требуем surname', '1'),
          _buildConfigRow('Требуем селфи', '0'),
          _buildConfigRow('Требуем email', '0'),
          _buildConfigRow('Требуем день рождения', '0'),
          _buildConfigRow('Запускать проверку дубликатов', '1'),
          _buildConfigRow('configeditor.registration.auto_activate_new_clients', '1'),

          const SizedBox(height: 16),
          _buildSectionTitle('Реферальная система'),
          _buildConfigRow('Реферальная система активна', '0'),
          _buildConfigRow('Сумма заказов реферала для начисления бонуса пригласившему', '0'),
          _buildConfigRow('Бонусы для пригласившего', '0'),
          _buildConfigRow('Бонусы приглашенному', '0'),

          const SizedBox(height: 16),
          _buildSectionTitle('Scoots / разделение на компании'),
          _buildConfigRow('Scope для клиентов', '1'),
          _buildConfigRow('Scope для тарифов', '0'),

          const SizedBox(height: 16),
          _buildSectionTitle('Настройки минимальной операции для разных платежных систем'),
          _buildConfigRow('Visa', '200'),
          _buildConfigRow('MasterCard', '200'),
          _buildConfigRow('Maestro', '200'),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: Color(0xFFD9E2EF)),
      ),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSubtitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD9E2EF)),
          right: BorderSide(color: Color(0xFFD9E2EF)),
        ),
      ),
      child: Text(title, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildConfigRow(String label, String value, {String? suffix}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD9E2EF)),
          right: BorderSide(color: Color(0xFFD9E2EF)),
          bottom: BorderSide(color: Color(0xFFF1F4F8)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 28,
                  child: TextField(
                    controller: TextEditingController(text: value),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(1), borderSide: const BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1), borderSide: const BorderSide(color: Colors.black)),
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  Text(suffix, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
