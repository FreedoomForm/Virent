import 'package:flutter/material.dart';

class ClickTransactionsPage extends StatelessWidget {
  const ClickTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                        Text('Транзакции CLICK', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 5 из 5 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    _labeledInput('merchant_trans_id', 150),
                    const SizedBox(width: 8),
                    _labeledInput('click_trans_id', 150),
                    const SizedBox(width: 8),
                    _labeledInput('status', 100),
                    const SizedBox(width: 8),
                    _labeledInput('error', 100),
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
                      color: const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 40, child: Text('Id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Click trans', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('Click paydoc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Merchant trans', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Merchant prepare', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Merchant confirm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('Error', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 100, child: Text('Error note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Sign time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Created', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('Updated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _clickRow('5', '1378842563', '', '65', '5', '5', '24,900', 'Complete (1)', 'confirmed (2)', '0', 'Success', '2026-05-29 12:48:50', '29 мая 2026, 12:48', '29 мая 2026, 12:48'),
                          _clickRow('4', '1921602807', '', '56', '4', '4', '24,990', 'Complete (1)', 'confirmed (2)', '0', 'Success', '2026-05-25 17:32:38', '25 мая 2026, 17:32', '25 мая 2026, 17:32'),
                          _clickRow('3', '40366171', '', '55', '3', '3', '24,990', 'Complete (1)', 'confirmed (2)', '0', 'Success', '2026-05-25 17:30:20', '25 мая 2026, 17:30', '25 мая 2026, 17:30'),
                          _clickRow('2', '663213541', '', '54', '2', '2', '24,990', 'Complete (1)', 'confirmed (2)', '0', 'Success', '2026-05-25 17:18:00', '25 мая 2026, 17:18', '25 мая 2026, 17:18'),
                          _clickRow('1', '481383948', '', '53', '1', '1', '24,990', 'Complete (1)', 'confirmed (2)', '0', 'Success', '2026-05-25 17:17:12', '25 мая 2026, 17:17', '25 мая 2026, 17:17'),
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
  }

  Widget _clickRow(String id, String trans, String paydoc, String merchTrans, String merchPrep, String merchConf, String amount, String action, String status, String error, String errorNote, String sign, String created, String updated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(trans, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 120, child: Text(paydoc, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(merchTrans, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(merchPrep, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(merchConf, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(amount, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(action, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(status, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 60, child: Text(error, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 100, child: Text(errorNote, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(sign, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(created, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 140, child: Text(updated, style: const TextStyle(fontSize: 11))),
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
