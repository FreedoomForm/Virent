import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class PrepaidOrdersPage extends ConsumerWidget {
  const PrepaidOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prepaidOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) => Container(
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
                        Text('Предоплаченные Заказы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 91 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _labeledInput('ID клиента', 100),
                      const SizedBox(width: 8),
                      _labeledInput('car_id', 100),
                      const SizedBox(width: 8),
                      _labeledInput('status', 80),
                      const SizedBox(width: 8),
                      _labeledInput('transaction_id', 120),
                      const SizedBox(width: 8),
                      _labeledInput('order_id', 100),
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
                width: 1600,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('Id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('Redis token', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('Car', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Client', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Company', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Abonement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Transaction', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Created', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _prepaidRow('91', '932282693681806...', '932', '269368', '16', '28', '2,490,000', 'waiting_payment', '—', '—', '18 июн 2026, 13:54', 'PAYME'),
                          _prepaidRow('90', 'redis-token-tes777...', '790', '22', '19', '36', '2,499,000', 'waiting_payment', '—', '—', '16 июн 2026, 13:07', 'PAYME'),
                          _prepaidRow('89', '895282693701506...', '895', '269370', '16', '28', '2,490,000', 'waiting_payment', '—', '—', '15 июн 2026, 16:52', 'CLICK'),
                          _prepaidRow('88', '895282693701506...', '895', '269370', '16', '28', '2,490,000', 'waiting_payment', '—', '—', '15 июн 2026, 16:52', 'PAYME'),
                          _prepaidRow('87', '895392693701506...', '895', '269370', '16', '39', '1,490,000', 'waiting_payment', '—', '—', '15 июн 2026, 16:52', 'CLICK'),
                          _prepaidRow('86', '895392693701506...', '895', '269370', '16', '39', '1,490,000', 'waiting_payment', '—', '—', '15 июн 2026, 16:52', 'PAYME'),
                          _prepaidRow('85', '174428269368140...', '1,744', '269368', '16', '28', '2,490,000', 'waiting_payment', '—', '—', '14 июн 2026, 18:49', 'PAYME'),
                          _prepaidRow('84', '815282693681406...', '815', '269368', '16', '28', '2,490,000', 'waiting_payment', '—', '—', '14 июн 2026, 08:09', 'PAYME'),
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
  )
  }

  Widget _prepaidRow(String id, String token, String car, String client, String company, String abon, String amount, String status, String trans, String order, String created, String type) {
    final bool isClick = type == 'CLICK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(id, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 200, child: Text(token, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 50, child: Text(car, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(client, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
          SizedBox(width: 70, child: Text(company, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(abon, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(amount, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 120, child: Text(status, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 100, child: Text(trans, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 70, child: Text(order, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(created, style: const TextStyle(fontSize: 10))),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isClick ? const Color(0xFF2ECC71) : const Color(0xFF7B68EE),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(type, style: const TextStyle(fontSize: 9, color: Colors.white), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  SizedBox(width: 8),
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

  Widget _labeledInput(String label, double width) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
        const SizedBox(width: 4),
        SizedBox(
          width: width,
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
        ),
        const SizedBox(width: 4),
        InkWell(onTap: () {}, child: Icon(Icons.close, size: 14, color: Colors.grey[500])),
      ],
    );
  )
  }
}
