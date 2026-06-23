import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';

class PaymeTransactionsPage extends ConsumerWidget {
  const PaymeTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymeTransactionsProvider);
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
                        Text('Транзакции Payme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 39 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    _labeledInput('payme_transaction_id', 150),
                    const SizedBox(width: 8),
                    _labeledInput('state', 100),
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
                width: 1700,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 220, child: Text('Payme transaction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 220, child: Text('Merchant transaction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('payme_time (UTC ms)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('create_time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Perform time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Cancel time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 180, child: Text('state description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('State', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Reason', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _paymeRow('39', '6a0c0144d3ee342047105841', '6a0c0144d3ee342047105841', '2026-05-19 11:20:52', '2026-05-19 11:20:53', '2026-05-19 11:21:01', '2026-05-19 11:21:08', 'Отменена после оплаты / возврат (-2)', true, '-2', '2,499,000', '79150213177', '22', '5'),
                          _paymeRow('38', '6a0c0132d3ee34204710583e', '6a0c0132d3ee34204710583e', '2026-05-19 11:20:34', '2026-05-19 11:20:35', '—', '2026-05-19 11:20:42', 'Отменена до подтверждения (-1)', false, '-1', '2,499,000', '79150213177', '22', '3'),
                          _paymeRow('37', '6a0b21dcd3ee3420471056fb', '6a0b21dcd3ee3420471056fb', '2026-05-18 19:27:40', '2026-05-18 19:27:40', '2026-05-18 19:28:28', '2026-05-18 19:29:16', 'Отменена после оплаты / возврат (-2)', true, '-2', '2,499,000', '79150213177', '22', '5'),
                          _paymeRow('36', '6a0b201fd3ee3420471056f4', '6a0b201fd3ee3420471056f4', '2026-05-18 19:20:15', '2026-05-18 19:20:16', '2026-05-18 19:22:29', '2026-05-18 19:23:17', 'Отменена после оплаты / возврат (-2)', true, '-2', '2,499,000', '79150213177', '22', '5'),
                          _paymeRow('35', '6a0b1cbbd3ee3420471056f1', '6a0b1cbbd3ee3420471056f1', '2026-05-18 19:05:47', '2026-05-18 19:05:47', '—', '—', 'Создана, ожидает оплату (1)', false, '1', '2,499,000', '79150213177', '22', '—', isWarning: true),
                          _paymeRow('34', '6a0b1cb9d3ee3420471056f0', '6a0b1cb9d3ee3420471056f0', '2026-05-18 19:05:45', '2026-05-18 19:05:46', '—', '—', 'Создана, ожидает оплату (1)', false, '1', '2,499,000', '79150213177', '22', '—', isWarning: true),
                          _paymeRow('33', 'test-flow-727e9071c8380ff...', 'test-flow-727e9071c8380ff...', '2026-05-15 20:24:00', '2026-05-15 20:24:00', '2026-05-15 20:24:00', '—', 'Успешно оплачена (2)', false, '2', '2,490,000', '998901361576', '269370', '—', isSuccess: true),
                          _paymeRow('32', 'test-flow-217b6d762990d7...', 'test-flow-217b6d762990d7...', '2026-05-15 19:53:34', '2026-05-15 19:53:42', '2026-05-15 19:53:42', '—', 'Успешно оплачена (2)', false, '2', '2,499,000', '79150213177', '22', '—', isSuccess: true),
                          _paymeRow('31', 'test-flow-ed21c19ee75e86...', 'test-flow-ed21c19ee75e86...', '2026-05-15 19:44:55', '2026-05-15 19:45:08', '—', '—', 'Создана, ожидает оплату (1)', false, '1', '2,499,000', '79150213177', '22', '—', isWarning: true),
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

  Widget _paymeRow(String id, String payme, String merch, String paymeTime, String create, String perform, String cancel, String stateDesc, bool isError, String state, String amount, String phone, String client, String reason, {bool isWarning = false, bool isSuccess = false}) {
    Color stateColor;
    Color textColor = Colors.white;
    if (isError) {
      stateColor = const Color(0xFFE74C3C);
    } else if (isWarning) {
      stateColor = const Color(0xFFF1C40F);
      textColor = Colors.black;
    } else if (isSuccess) {
      stateColor = const Color(0xFF2ECC71);
    } else {
      stateColor = const Color(0xFFBDC3C7);
      textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(id, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 220, child: Text(payme, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 220, child: Text(merch, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(paymeTime, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(create, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(perform, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 140, child: Text(cancel, style: const TextStyle(fontSize: 10))),
          SizedBox(
            width: 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: stateColor, borderRadius: BorderRadius.circular(2)),
              child: Text(stateDesc, style: TextStyle(fontSize: 8, color: textColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          SizedBox(width: 60, child: Text(state, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 80, child: Text(amount, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 100, child: Text(phone, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(client, style: const TextStyle(fontSize: 10, color: Color(0xFF3498DB)))),
          SizedBox(width: 60, child: Text(reason, style: const TextStyle(fontSize: 10))),
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
