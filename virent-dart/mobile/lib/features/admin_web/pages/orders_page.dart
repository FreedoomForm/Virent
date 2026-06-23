import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF5F6FA),
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
                        Text('Заказы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 435,693 совпадений (отфильтровано из 769,200 совпадений)',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                const SizedBox(height: 10),
                // Status filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusBtn('Отложено', const Color(0xFFE67E22), true),
                      _statusBtn('Бронь', const Color(0xFFBDC3C7), true),
                      const SizedBox(width: 4),
                      _statusBtn('Осмотр', Colors.white, false, textColor: const Color(0xFF666666)),
                      _statusBtn('Осмотр платный', Colors.white, false, textColor: const Color(0xFF666666)),
                      _statusBtn('Парковка', Colors.white, false, textColor: const Color(0xFF666666)),
                      _statusBtn('Завершён', Colors.white, false, textColor: const Color(0xFF666666)),
                      const SizedBox(width: 4),
                      _statusBtn('В аренду', const Color(0xFF2C3345), true),
                      _statusBtn('Активный', const Color(0xFF7B68EE), true),
                      const SizedBox(width: 8),
                      const Text('Номер', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('ID клиента', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      const Text('Дата', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _chip('Не оплачен', const Color(0xFFE74C3C)),
                      const SizedBox(width: 4),
                      const Text('ID самоката', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      const SizedBox(width: 4),
                      _input(80),
                      const SizedBox(width: 4),
                      _closeIcon(),
                      const SizedBox(width: 8),
                      _chip('Без абонемента', const Color(0xFF1ABC9C)),
                      _chip('С абонементом', const Color(0xFF1ABC9C)),
                      _chip('Тариф ▼', const Color(0xFF7B68EE)),
                      _chip('Абонемент ▼', const Color(0xFF7B68EE)),
                      _chip('Компания ▼', const Color(0xFF7B68EE)),
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
                      color: const Color(0xFFF8F9FA),
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
                      ref.watch(prepaidOrdersProvider).when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Ошибка: $e")),
                        data: (items) => ListView(
                          children: items.map((item) => _orderRowFromItem(item)).toList(),
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

  Widget _orderRow(String id, String clientId, String clientName, String car, String tariff, String abon, String dur, String status, String mileage, String start, String finish, String cost) {
    Color statusColor;
    switch (status) {
      case 'Завершено':
        statusColor = const Color(0xFF2ECC71);
        break;
      case 'Поездка':
        statusColor = const Color(0xFF3498DB);
        break;
      case 'Отложено':
        statusColor = const Color(0xFFE67E22);
        break;
      default:
        statusColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFFE67E22)))),
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
                Text(clientName, style: const TextStyle(fontSize: 9, color: Color(0xFF3498DB))),
              ],
            ),
          ),
          SizedBox(width: 60, child: Text(car, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(tariff, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: abon.isNotEmpty ? Text(abon, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB))) : const SizedBox()),
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
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Colors.grey.shade400)),
          SizedBox(width: 60, child: Icon(Icons.check_box_outline_blank, size: 14, color: Colors.grey.shade400)),
          SizedBox(width: 80, child: Text(cost, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 80),
          const SizedBox(width: 90),
          const SizedBox(width: 50),
          const SizedBox(width: 160),
          const SizedBox(width: 120, child: Text('ИП Асилбеков Шерзод', style: TextStyle(fontSize: 9))),
          Expanded(
            child: InkWell(
              onTap: () {},
              child: const Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB))),
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
        border: filled ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(color: filled ? textColor : const Color(0xFF666666), fontSize: 10, fontWeight: FontWeight.w500)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  static Widget _closeIcon() {
    return InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500]));
  }

  static Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  /// Builds a row from provider data item.
  Widget _orderRowFromItem(Map<String, dynamic> item) {
    return _orderRow(
      item['id']?.toString() ?? '',
      item['clientId']?.toString() ?? '',
      item['clientName']?.toString() ?? '',
      item['car']?.toString() ?? '',
      item['tariff']?.toString() ?? '',
      item['abon']?.toString() ?? '',
      item['dur']?.toString() ?? '',
      item['status']?.toString() ?? '',
      item['mileage']?.toString() ?? '',
      item['start']?.toString() ?? '',
      item['finish']?.toString() ?? '',
      item['cost']?.toString() ?? '',
    );
  }

}
