import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFF344050), // Dark theme header color
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'ViRent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          const Spacer(),
          // Tags
          _buildStatusTag('Разблокирован: 0', const Color(0xFF2E86C1)),
          _buildStatusTag('Разряжен: 7', const Color(0xFFF1C40F), textColor: Colors.black),
          _buildStatusTag('Не в сети: 9', const Color(0xFFAEB6BF), textColor: Colors.black),
          _buildStatusTag('Выезд из зоны: 0', const Color(0xFF8E44AD)),
          _buildStatusTag('Не включился: 1', const Color(0xFFE74C3C)),
          const SizedBox(width: 16),
          // User Info
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ViRent', style: TextStyle(color: Colors.white, fontSize: 12)),
              Text('Шерзод', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16,
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
