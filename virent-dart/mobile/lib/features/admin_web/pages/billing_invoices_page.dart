import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class BillingInvoicesPage extends ConsumerWidget {
  const BillingInvoicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billingReceiptsProvider);
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
                        Text('Счета', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 3,052,330 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    _labeledInput('ID клиента', 100),
                    const SizedBox(width: 8),
                    _labeledInput('Заказ', 100),
                    const SizedBox(width: 8),
                    _labeledInput('columns.redis_token', 140),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: const Text('Export'),
                    ),
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
                width: 2000,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 160, child: Text('ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Hold', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Company', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Operator', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Client', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 160, child: Text('Redis token', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 70, child: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('Created', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Result code', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 50, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Transaction', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Uzcard transaction', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Card pan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 130, child: Text('Code message confirm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _invoiceRow('6a3503bf7aa...', '2331349', '16', 'myuzcard', '769199', '117850', '234807', '17964243480...', 'confirmed', '19 июн, 13:55', '', 'money', '55916531', '', '', 'OK', true, true),
                          _invoiceRow('6a3503ef16f8...', '2331348', '16', 'myuzcard', '769202', '500000', '248798', '17202424879...', 'HOLD', '19 июн, 13:55', '', 'money', '55916523', '', '', '', false, false),
                          _invoiceRow('6a3503bd7aa...', '2331347', '16', 'myuzcard', '769199', '500000', '234807', '17964243480...', 'cancelled', '19 июн, 13:54', '', 'money', '55916504', '', '', '', false, false),
                          _invoiceRow('6a3503bd7aa...', '', '16', '', '769199', '500000', '234807', '17964243480...', 'not enough bonus', '19 июн, 13:54', '', 'bonus', '', '', '', '', false, false),
                          _invoiceRow('6a35037653b...', '2331346', '16', 'myuzcard', '769201', '500000', '224449', '17252424444...', 'HOLD', '19 июн, 13:53', '', 'money', '55916461', '', '', '', false, false),
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

  Widget _invoiceRow(String id, String hold, String company, String operator, String order, String amount, String client, String redis, String status, String created, String resultCode, String type, String trans, String uzcard, String cardPan, String codeMsg, bool showReturn, bool showCreate) {
    Color? statusColor;
    if (status == 'confirmed') statusColor = const Color(0xFF2ECC71);
    if (status == 'HOLD') statusColor = const Color(0xFFF39C12);
    if (status == 'cancelled') statusColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(id, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text(hold, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 60, child: Text(company, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 60, child: Text(operator, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 60, child: Text(order, style: const TextStyle(fontSize: 9, color: Color(0xFF3498DB)))),
          SizedBox(width: 60, child: Text(amount, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 60, child: Text(client, style: const TextStyle(fontSize: 9, color: Color(0xFF3498DB)))),
          SizedBox(width: 160, child: Text(redis, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 70, child: Text(status, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 130, child: Text(created, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 80, child: Text(resultCode, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 50, child: Text(type, style: const TextStyle(fontSize: 9))),
          SizedBox(width: 80, child: Text(trans, style: const TextStyle(fontSize: 9))),
          const SizedBox(width: 100),
          const SizedBox(width: 60),
          SizedBox(width: 130, child: Text(codeMsg, style: const TextStyle(fontSize: 9))),
          Expanded(
            child: Row(
              children: [
                InkWell(onTap: () {}, child: const Text('Просмотр', style: TextStyle(fontSize: 9, color: Color(0xFF3498DB)))),
                if (showReturn) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF39C12), borderRadius: BorderRadius.circular(2)),
                    child: const Text('Вернуть платеж', style: TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                ],
                if (showCreate) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF2ECC71), borderRadius: BorderRadius.circular(2)),
                    child: const Text('Создать чек', style: TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                ],
              ],
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
  }
}
