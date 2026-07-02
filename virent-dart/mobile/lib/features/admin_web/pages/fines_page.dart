import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';
import './widgets/admin_dialogs.dart';

class FinesPage extends ConsumerWidget {
  const FinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finesListProvider);
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
                const Text('Штрафы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: adminTextDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('ID клиента', style: TextStyle(fontSize: 11, color: adminTextGray)),
                    const SizedBox(width: 4),
                    _input(100),
                    const SizedBox(width: 4),
                    _closeIcon(context, ),
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
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: const Row(
                        children: [
                          SizedBox(width: 200, child: Text('ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('client_id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('hold_id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('order_id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 200, child: Text('bill_id', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('description', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 150, child: Text('timestamp_response', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text('status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('CardPan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 80, child: Text('TransactionId', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text('UzcardTransactionId', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          SizedBox(width: 120, child: Text('updated_at', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                          Expanded(child: Text('Управление', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: [
                          _fineRow('1TH6vudSDF954uqo...', '268355', '20000000', '', '', '', '', '27.07.2025 21:03:55', 'debt', '', '', ''),
                          _fineRow('6882f576b40350335...', '266868', '20000000', '', '', '6882f576b403503...', '', '25.07.2025 08:09:46', 'confirm', '', '', '1753412987', showButtons: false),
                          _fineRow('6864bd8b436464e2...', '253376', '1000000', '', '', '6864bd8b436464...', '', '02.07.2025 10:03:07', 'HOLD', '', '', '', showButtons: true),
                          _fineRow('6864bd738f558c267...', '253376', '1000000', '', '', '6864bd738f558c...', '', '02.07.2025 10:02:44', 'HOLD', '', '', '', showButtons: true),
                          _fineRow('6864bd61a249ce96...', '253376', '1000000', '', '', '6864bd61a249ce...', '', '02.07.2025 10:02:26', 'HOLD', '', '', '', showButtons: true),
                          _fineRow('6864bd564b411f33...', '253376', '1000000', '', '', '6864bd564b411f...', '', '02.07.2025 10:02:14', 'HOLD', '', '', '', showButtons: true),
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

  Widget _fineRow(String id, String clientId, String amount, String holdId, String orderId, String billId, String desc, String timestamp, String status, String cardPan, String transId, String uzcardId, {bool showButtons = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: adminBorder))),
      child: Row(
        children: [
          SizedBox(width: 200, child: Text(id, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 60, child: Text(clientId, style: const TextStyle(fontSize: 10, color: adminInfo))),
          SizedBox(width: 80, child: Text(amount, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 60),
          const SizedBox(width: 60),
          SizedBox(width: 200, child: Text(billId, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 80),
          SizedBox(width: 150, child: Text(timestamp, style: const TextStyle(fontSize: 10))),
          SizedBox(width: 60, child: Text(status, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 80),
          const SizedBox(width: 80),
          SizedBox(width: 140, child: Text(uzcardId, style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 120),
          Expanded(
            child: showButtons
                ? Row(
                    children: [
                      _actionBtn('Подтвердить холд', adminSuccess),
                      const SizedBox(width: 4),
                      _actionBtn('Отменить холд', adminDanger),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: adminBorder)),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  static Widget _closeIcon(BuildContext context) {
    return InkWell(onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'), child: Icon(Icons.close, size: 14, color: Colors.grey[500]));
  }
}
