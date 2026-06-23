import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF2C3345),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'ViRent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {},
            child: const Icon(Icons.menu, color: Colors.white70, size: 18),
          ),
          const Spacer(),
          _buildTag('Разблокирован: 0', const Color(0xFF3498DB)),
          _buildTag('Разряжены: 7', const Color(0xFFF1C40F), textColor: Colors.black87),
          _buildTag('Не в сети: 9', const Color(0xFFBDC3C7), textColor: Colors.black87),
          _buildTag('Выезд из зоны: 0', const Color(0xFF8E44AD)),
          _buildTag('Не включился: 1', const Color(0xFFE74C3C)),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.amber,
            child: Icon(Icons.person, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ViRent', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Шерзод', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              Text('Асилбек', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
