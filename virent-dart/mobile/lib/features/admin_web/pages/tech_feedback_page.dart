import 'package:flutter/material.dart';

class TechFeedbackPage extends StatelessWidget {
  const TechFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Фидбек', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 13,420 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _labeledInput('Самокат', 100),
                        const SizedBox(width: 8),
                        _labeledInput('Заказ', 100),
                        const SizedBox(width: 8),
                        _labeledInput('Клиент', 100),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B68EE),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                          ),
                          child: const Text('Проверен', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 60, child: Text('id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('car_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('client_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('order_id', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 80, child: Text('checked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('Who checked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('created_at', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 150, child: Text('updated_at', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _feedbackRow('13467', '896', '255358', '768694', 'Самокат имеет неопрятный вид (грязный)', '2026-06-18 21:34:19', '2026-06-18 21:34:19'),
                      _feedbackRow('13466', '1762', '296132', '768682', 'Самокат не включился', '2026-06-18 21:18:55', '2026-06-18 21:18:55'),
                      _feedbackRow('13465', '928', '285978', '768649', 'Самокат имеет неопрятный вид (грязный)', '2026-06-18 20:45:30', '2026-06-18 20:45:30'),
                      _feedbackRow('13464', '959', '293800', '768633', 'Самокат не включился', '2026-06-18 20:30:02', '2026-06-18 20:30:02'),
                      _feedbackRow('13463', '914', '264511', '768513', 'Самокат не включился', '2026-06-18 16:54:28', '2026-06-18 16:54:28'),
                      _feedbackRow('13462', '1763', '212741', '768505', 'Самокат не включился', '2026-06-18 16:42:09', '2026-06-18 16:42:09'),
                      _feedbackRow('13461', '1763', '212741', '768504', 'Самокат не включился', '2026-06-18 16:40:49', '2026-06-18 16:40:49'),
                      _feedbackRow('13460', '1734', '249529', '768402', 'Самокат не включился', '2026-06-18 14:00:45', '2026-06-18 14:00:45'),
                      _feedbackRow('13459', '1788', '249529', '768400', 'Самокат включился, но не едет', '2026-06-18 13:59:42', '2026-06-18 13:59:42'),
                      _feedbackRow('13458', '1706', '248798', '768355', 'Передумал, решил пойти пешком', '2026-06-18 11:40:13', '2026-06-18 11:40:13'),
                      _feedbackRow('13457', '935', '68757', '768332', 'Самокат не включился', '2026-06-18 10:13:29', '2026-06-18 10:13:29'),
                      _feedbackRow('13456', '935', '68757', '768331', 'Самокат не включился', '2026-06-18 10:12:22', '2026-06-18 10:12:22'),
                      _feedbackRow('13455', '799', '296464', '768255', 'Самокат включился, но не едет', '2026-06-18 04:07:06', '2026-06-18 04:07:06'),
                      _feedbackRow('13454', '1745', '296456', '768210', 'Самокат включился, но не едет', '2026-06-18 02:15:36', '2026-06-18 02:15:36'),
                      _feedbackRow('13453', '965', '106578', '768181', 'Самокат не включился', '2026-06-18 01:50:16', '2026-06-18 01:50:16'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackRow(String id, String carId, String clientId, String orderId, String type, String createdAt, String updatedAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(id, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 80, child: Text(carId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 80, child: Text(clientId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          SizedBox(width: 80, child: Text(orderId, style: const TextStyle(fontSize: 11, color: Color(0xFF7B68EE)))),
          Expanded(child: Text(type, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 150, child: Text('', style: TextStyle(fontSize: 11))), // Who checked
          SizedBox(width: 150, child: Text(createdAt, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 150, child: Text(updatedAt, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                const Icon(Icons.visibility, size: 12, color: Color(0xFF3498DB)),
                const SizedBox(width: 4),
                const Text('Просмотр', style: TextStyle(fontSize: 11, color: Color(0xFF3498DB))),
                const SizedBox(width: 12),
                const Text('Проверить фидбэк', style: TextStyle(fontSize: 11, color: Color(0xFF3498DB))),
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
