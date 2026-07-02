import 'package:flutter/material.dart';
import '../widgets/admin_dialogs.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: const Color(0xFF1B2A4E),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'ViRent',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showAdminInfoDialog(context, 'Информация', 'Действие в разработке'),
            child: const Icon(Icons.menu, color: Colors.white70, size: 16),
          ),
          const Spacer(),
          _buildTag('Разблокирован: 0', const Color(0xFF467FD0)),
          _buildTag('Разряжены: 7', const Color(0xFFFFC107), textColor: Colors.black87),
          _buildTag('Не в сети: 9', const Color(0xFFD9E2EF), textColor: Colors.black87),
          _buildTag('Выезд из зоны: 0', const Color(0xFF7C69EF)),
          _buildTag('Не включился: 1', const Color(0xFFDF4759)),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 10,
            backgroundColor: Colors.amber,
            child: Icon(Icons.person, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ViRent', style: TextStyle(color: Colors.white70, fontSize: 9)),
              Text('Шерзод', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
              Text('Асилбек', style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
