import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class BillingReceiptsPage extends ConsumerWidget {
  const BillingReceiptsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billingReceiptsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Ошибка: $e")),
      data: (items) {
        return Container(
      color: const Colors.white,
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
                        Text('Чеки', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 711,062 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    _labeledInput('columns.bonus.order_id', 120),
                    const SizedBox(width: 8),
                    _labeledInput('ID клиента', 100),
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
                width: 1600,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 60, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Uuid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Чек', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Provider uuid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 250, child: Text('Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Created', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Company', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Sendable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Reason', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Status check after', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _receiptRow('712714', '6930835671', 'CLICK', '', '69e86108fbfa34f0ff0dd9b2', 'SUCCESS', '150273', '500000', '22 апр 2026, 10:50', '23', '', 'Нет'),
                          _receiptRow('712713', '6930810352', 'CLICK', '', '69e860337aaef991135de6be', 'SUCCESS', '290422', '400100', '22 апр 2026, 10:44', '24', '', 'Нет'),
                          _receiptRow('712712', '029186218708', 'CLICK', '', '69e85e3a7aaef991135de6bd', 'SUCCESS', '238145', '417550', '22 апр 2026, 10:35', '24', '', 'Нет'),
                          _receiptRow('712711', '029186161056', 'CLICK', '', '69e85cbc84d6f73a1a0f16c2', 'SUCCESS', '238145', '500000', '22 апр 2026, 10:32', '24', '', 'Нет'),
                          _receiptRow('712710', '029186066068', 'CLICK', '', '69e85bcb7aaef991135de6ba', 'SUCCESS', '238145', '396100', '22 апр 2026, 10:25', '24', '', 'Нет'),
                          _receiptRow('712709', '029186061459', 'CLICK', '', '69e85ae1780cea8d9009cac2', 'SUCCESS', '289148', '500000', '22 апр 2026, 10:25', '23', '', 'Нет'),
                          _receiptRow('712708', '029186048920', 'CLICK', '', '69e85b857aaef991135de6b6', 'SUCCESS', '281315', '249250', '22 апр 2026, 10:24', '22', '', 'Нет'),
                          _receiptRow('712707', '029186026352', 'CLICK', '', '69e85a97a35ebbb104078e62', 'SUCCESS', '281315', '500000', '22 апр 2026, 10:22', '22', '', 'Нет'),
                          _receiptRow('712706', '029186019042', 'CLICK', '', '69e85a84f8d391df42066352', 'SUCCESS', '238145', '500000', '22 апр 2026, 10:22', '24', '', 'Нет'),
                          _receiptRow('712705', '6930612493', 'CLICK', '', '69e859fb27bd41d5b9025d62', 'SUCCESS', '288941', '1490000', '22 апр 2026, 10:17', '16', '', 'Нет'),
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

  Widget _receiptRow(String id, String uuid, String check, String providerUuid, String bill, String status, String client, String amount, String created, String company, String order, String sendable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 100, child: Text(uuid, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(check, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
          SizedBox(width: 120, child: Text(providerUuid, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 250, child: Text(bill, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(status, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(client, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
          SizedBox(width: 80, child: Text(amount, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(created, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(company, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(order, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(sendable, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 100),
          const Expanded(child: SizedBox()),
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
