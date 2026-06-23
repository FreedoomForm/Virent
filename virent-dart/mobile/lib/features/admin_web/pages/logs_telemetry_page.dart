import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class LogsTelemetryPage extends ConsumerWidget {
  const LogsTelemetryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logsTelemetryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e", style: const TextStyle(color: Colors.red))),
      data: (items) {
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
                        Text('Логи Телеметрии', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 10,000 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                Row(
                  children: [
                    _dropdown('Конкретный день ▼'),
                    const SizedBox(width: 8),
                    _dropdown('Промежуток времени ▼'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF7B68EE), borderRadius: BorderRadius.circular(3)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('В тревоге', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _labeledInput('ID самоката', 100),
                    const SizedBox(width: 8),
                    _labeledInput('Id заказа', 100),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1800,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 150, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('CarId', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Gosnomer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('remainingMileage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('EcuErrCode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('EcuErrType', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Order.orderId', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 30, child: Icon(Icons.wifi, size: 14)),
                          SizedBox(width: 30, child: Icon(Icons.battery_charging_full, size: 14)),
                          SizedBox(width: 30, child: Icon(Icons.bolt, size: 14)),
                          SizedBox(width: 30, child: Icon(Icons.lock, size: 14)),
                          SizedBox(width: 80, child: Icon(Icons.sensors, size: 14)), // pseudo for motion icon
                          SizedBox(width: 40, child: Icon(Icons.battery_std, size: 14)),
                          SizedBox(width: 60, child: Icon(Icons.speed, size: 14)),
                          SizedBox(width: 40, child: Icon(Icons.signal_cellular_alt, size: 14)), // pseudo for signal
                          SizedBox(width: 50, child: Icon(Icons.gps_fixed, size: 14)),
                          SizedBox(width: 60, child: Icon(Icons.electric_bolt, size: 14)),
                          SizedBox(width: 40, child: Icon(Icons.info_outline, size: 14)), // pseudo for info v
                          SizedBox(width: 140, child: Text('EventTime', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('ServerTime', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _telemetryRow('Sf4e354BotTmlSvbq-Rf', '1724', '05718', '35.00', '0000000000000000000', '0', '', true, true, true, true, false, '65 %', '0 км/ч', '31 %', '22 sat', '51,113 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('SP4e354BotTmlSvbq-RT', '926', '050135', '26.50', '0000000000000000000', '0', '', true, false, true, true, false, '54 %', '0 км/ч', '31 %', 'sat', '52,951 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('Rv4e354BotTmlSvbq-Q9', '834', '050045', '15.50', '0000000000000000000', '0', '', true, false, true, false, false, '27 %', '4 км/ч', '27 %', 'sat', '47,868 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('Rf4e354BotTmlSvbq-Qy', '839', '050050', '25.00', '0000000000000000000', '0', '', true, true, true, true, false, '50 %', '0 км/ч', '31 %', 'sat', '51,295 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('RP4e354BotTmlSvbq-Qm', '865', '050075', '12.50', '0000000000000000000', '0', '', true, false, true, true, false, '88 %', '2 км/ч', '31 %', 'sat', '53,818 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('Q_4e354BotTmlSvbq-Qb', '1769', '05763', '24.00', '0000000000000000000', '0', '', true, true, true, true, false, '45 %', '0 км/ч', '25 %', '23 sat', '47,795 V', '4 V', '19 июн 2026, 14:03:09', '19 июн 2026, 14:03:09'),
                          _telemetryRow('Qv4e354BotTmlSvbq-QH', '790', '050002', '22.00', '0000000000000000000', '0', '', true, false, true, true, false, '44 %', '0 км/ч', '31 %', 'sat', '47,898 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:09'),
                          _telemetryRow('Qf4e354BotTmlSvbqOSd', '815', '050027', '35.50', '0000000000000000000', '0', '', true, false, true, true, false, '70 %', '0 км/ч', '25 %', 'sat', '50,731 V', '4 V', '19 июн 2026, 14:03:07', '19 июн 2026, 14:03:08'),
                          _telemetryRow('QP4e354BotTmlSvbqOSC', '913', '050122', '27.50', '0000000000000000004', '0', '', true, true, true, false, false, '55 %', '0 км/ч', '19 %', 'sat', '49,044 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
                          _telemetryRow('P_4e354BotTmlSvbq0Rk', '813', '050025', '24.00', '0000000000000000000', '0', '', true, true, true, true, false, '46 %', '0 км/ч', '31 %', 'sat', '51,348 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
                          _telemetryRow('Pv4e354BotTmlSvbq0Rk', '844', '050055', '31.00', '0000000000000000000', '0', '', true, true, true, true, false, '61 %', '0 км/ч', '26 %', 'sat', '50,547 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
                          _telemetryRow('Pf4e354BotTmlSvbqOQu', '1711', '05705', '49.50', '0000000000000000000', '0', '', true, true, true, true, false, '90 %', '0 км/ч', '29 %', '23 sat', '53,200 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
                          _telemetryRow('PP4e354BotTmlSvbqOQQ', '800', '050012', '33.50', '0000000000000000000', '0', '', true, false, true, false, false, '55 %', '0 км/ч', '30 %', 'sat', '49,152 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
                          _telemetryRow('O_4e354BotTmlSvbp-Ty', '1791', '05785', '34.50', '0000000000000000000', '0', '', true, true, true, false, true, '69 %', '0 км/ч', '17 %', '22 sat', '50,771 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:06'),
                          _telemetryRow('Ov4e354BotTmlSvbp-TT', '922', '050131', '33.00', '0000000000000000000', '0', '', true, false, true, true, false, '61 %', '0 км/ч', '29 %', 'sat', '49,895 V', '4 V', '19 июн 2026, 14:03:06', '19 июн 2026, 14:03:08'),
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
      };
    },
);
  }

  Widget _telemetryRow(String id, String carId, String gosnomer, String mileage, String ecuErr, String ecuErrType, String orderId, bool icon1, bool icon2, bool icon3, bool icon4, bool isMotion, String val1, String val2, String val3, String val4, String val5, String val6, String eventTime, String serverTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(id, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 50, child: Text(carId, style: const TextStyle(fontSize: 11, color: Color(0xFF3498DB)))),
          SizedBox(width: 60, child: Text(gosnomer, style: const TextStyle(fontSize: 11, color: Color(0xFF3498DB)))),
          SizedBox(width: 100, child: Text(mileage, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(ecuErr, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 80, child: Text(ecuErrType, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(orderId, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 30, child: Icon(icon1 ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: icon1 ? Colors.green : Colors.grey)),
          SizedBox(width: 30, child: Icon(icon2 ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: icon2 ? Colors.green : Colors.red)),
          SizedBox(width: 30, child: Icon(icon3 ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: icon3 ? Colors.green : Colors.grey)),
          SizedBox(width: 30, child: Icon(icon4 ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: icon4 ? Colors.green : Colors.red)),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors, size: 14, color: isMotion ? Colors.red : Colors.green),
                Text(isMotion ? 'Motion' : 'No motion', style: TextStyle(fontSize: 8, color: isMotion ? Colors.red : Colors.green)),
              ],
            ),
          ),
          SizedBox(width: 40, child: Text(val1, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(val2, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 40, child: Text(val3, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 50, child: Text(val4, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(val5, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 40, child: Text(val6, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(eventTime, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(serverTime, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  Icon(Icons.visibility, size: 12, color: Color(0xFF3498DB)),
                  SizedBox(width: 4),
                  Text('Просмотр', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    );
  }

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        SizedBox(
          width: width,
          height: 28,
          child: TextField(
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  }
}
