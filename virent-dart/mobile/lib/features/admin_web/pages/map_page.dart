import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Map Top Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Текущая карта: Частота аренд', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('Общая карта')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('Тепловая карта')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B68EE), // Purple active
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Частота аренд'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('Группирование самокатов')),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Radio(value: 1, groupValue: 1, onChanged: (v) {}),
                      const Text('Старт аренд'),
                      Radio(value: 2, groupValue: 1, onChanged: (v) {}),
                      const Text('Конец аренд'),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
        // Dark Map Mockup
        Expanded(
          child: Container(
            color: const Color(0xFF2E2E2E), // Dark map background
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 100, color: Colors.white54),
                  SizedBox(height: 16),
                  Text('Mapbox Intergration (Mockup)', style: TextStyle(color: Colors.white54, fontSize: 24)),
                  SizedBox(height: 24),
                  // Simple representation of map bubbles
                  Wrap(
                    spacing: 24,
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: Colors.pinkAccent, child: Text('2.8k')),
                      CircleAvatar(radius: 30, backgroundColor: Colors.lightGreen, child: Text('546')),
                      CircleAvatar(radius: 20, backgroundColor: Colors.lightBlue, child: Text('52')),
                    ],
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
