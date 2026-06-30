import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prepaidOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('Заказы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF1B2A4E))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 435,693 совпадений (отфильтровано из 769,200 совпадений)',
                            style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Status filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusBtn('Отложено', const Color(0xFFFFC107), true),
                      _statusBtn('Бронь', const Color(0xFFD9E2EF), true),
                      const SizedBox(width: 4),
                      _statusBtn('Осмотр', Colors.white, false, textColor: const Color(0xFF868686)),
                      _statusBtn('Осмотр платный', Colors.white, false, textColor: const Color(0xFF868686)),
                      _statusBtn('Парковка', Colors.white, false, textColor: const Color(0xFF868686)),
                      _statusBtn('Завершён', Colors.white, false, textColor: const Color(0xFF868686)),
                      const SizedBox(width: 4),
                      _statusBtn('В аренду', const Color(0xFF1B2A4E), true),
                      _statusBtn('Активный', const Color(0xFF7C69EF), true),
                      const SizedBox(width: 8),
                      const Text('Номер', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('ID клиента', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('Дата', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      const SizedBox(width: 4),
                      _chip('Не оплачен', const Color(0xFFDF4759)),
                      const SizedBox(width: 4),
                      const Text('ID самоката', style: TextStyle(fontSize: 11, color: Color(0xFF868686))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      _chip('Без абонемента', const Color(0xFF42BA96)),
                      _chip('С абонементом', const Color(0xFF42BA96)),
                      _chip('Тариф ▼', const Color(0xFF7C69EF)),
                      _chip('Абонемент ▼', const Color(0xFF7C69EF)),
                      _chip('Компания ▼', const Color(0xFF7C69EF)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 2200,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 60, child: Text('Id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Client', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Car', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Tariff', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Abonement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('Долг', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Duration', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Mileage', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('Start time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('Finish time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Is payme', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Is click', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Total cost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Remains pay', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 90, child: Text('GuardChanged', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('Drift', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 160, child: Text('Redis token', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Company', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _orderRow('769200', '343022', 'surname Daqavilus', '05-742', 'Minute', '', '00:01:55', 'Завершено', '1', '19 июн 2026, 13:48', '19 июн 2026, 13:50', '3 390.50 С.'),
                          _orderRow('769199', '334807', 'surname nodir', '05-790', 'Minute', '', '00:06:27', 'Поездка', '1', '19 июн 2026, 13:45', '', '7 169.00 С.'),
                          _orderRow('769198', '258352', 'surname латиф', '05-0161', 'Минутный[...]', '20 Ми[...]', '00:07:43', 'Поездка', '1', '19 июн 2026, 13:44', '', '14 900.00 С.'),
                          _orderRow('769197', '283732', 'surname Firdavs', '05-0114', 'Minute', '', '00:05:50', 'Завершено', '1', '19 июн 2026, 13:42', '19 июн 2026, 13:48', '9 340.50 С.'),
                          _orderRow('769196', '043378', 'surname Doston', '05-792', 'Minute', '', '00:12:25', 'Поездка', '3', '19 июн 2026, 13:39', '', '15 660.00 С.'),
                          _orderRow('769195', '324096', 'surname feruz', '05-0090', 'Minute', '', '00:08:32', 'Завершено', '2', '19 июн 2026, 13:32', '19 июн 2026, 13:40', '12 013.50 С.'),
                          _orderRow('769194', '286608', 'surname Behruz', '05-0002', 'Minute', '', '00:04:55', 'Завершено', '1', '19 июн 2026, 13:28', '19 июн 2026, 13:33', '8 433.00 С.'),
                          _orderRow('769193', '296600', 'surname Behruz', '05-0002', 'Minute', '', '00:00:00', 'Отложено', '0', '19 июн 2026, 13:28', '19 июн 2026, 13:28', '0.00 С.'),
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

  Widget _orderRow(String id, String clientId, String clientName, String car, String tariff, String abon, String dur, String status, String mileage, String start, String finish, String cost) {
    Color statusColor;
    switch (status) {
      case 'Завершено':
        statusColor = const Color(0xFF42BA96);
        break;
      case 'Поездка':
        statusColor = const Color(0xFF467FD0);
        break;
      case 'Отложено':
        statusColor = const Color(0xFFFFC107);
        break;
      default:
        statusColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD9E2EF)))),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFFFFC107)))),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
                  child: Text(clientId, style: const TextStyle(fontSize: 8, color: Colors.white)),
                ),
                Text(clientName, style: const TextStyle(fontSize: 9, color: Color(0xFF467FD0))),
              ],
            ),
          ),
          SizedBox(width: 60, child: Text(car, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(tariff, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: abon.isNotEmpty ? Text(abon, style: const TextStyle(fontSize: 10, color: Color(0xFF467FD0))) : const SizedBox()),
          const SizedBox(width: 50),
          SizedBox(width: 70, child: Text(dur, style: const TextStyle(fontSize: 10))),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
              child: Text(status, style: const TextStyle(fontSize: 8, color: Colors.white), textAlign: TextAlign.center),
            ),
          ),
          SizedBox(width: 60, child: Text(mileage, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 130, child: Text(start, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 130, child: Text(finish, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 50, child: Icon(Icons.check_box, size: 14, color: Colors.green.shade400)),
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Color(0xFF868686))),
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Color(0xFF868686))),
          SizedBox(width: 80, child: Text(cost, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 80),
          const SizedBox(width: 90),
          const SizedBox(width: 50),
          const SizedBox(width: 160),
          const SizedBox(width: 120, child: Text('ИП Асилбеков Шерзод', style: TextStyle(fontSize: 9))),
          Expanded(
            child: InkWell(
              onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
              child: const Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF467FD0))),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusBtn(String label, Color color, bool filled, {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: Color(0xFFD9E2EF)),
      ),
      child: Text(label, style: TextStyle(color: filled ? textColor : const Color(0xFF868686), fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  static Widget _input(double w) {
    return SizedBox(
      width: w,
      height: 28,
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Color(0xFFD9E2EF))),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  static Widget _closeIcon() {
    return InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: Icon(Icons.close, size: 14, color: Colors.grey[500]));
  }

  static Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
