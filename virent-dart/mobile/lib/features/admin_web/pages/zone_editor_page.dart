// zone_editor_page.dart — Map-based zone polygon editor.
//
// Draw/edit geozones directly on the map. Supports:
//   - Tap to add polygon vertices
//   - Drag vertices to reposition
//   - Save polygon to embedded server
//   - Zone types: parking, no-ride, slow, charging

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/map/tile_cache_service.dart';
import '../admin_web_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../widgets/admin_dialogs.dart';

class ZoneEditorPage extends ConsumerStatefulWidget {
  const ZoneEditorPage({super.key});

  @override
  ConsumerState<ZoneEditorPage> createState() => _ZoneEditorPageState();
}

class _ZoneEditorPageState extends ConsumerState<ZoneEditorPage> {
  final MapController _mapController = MapController();
  static const _tashkentCenter = LatLng(41.3111, 69.2406);

  final List<LatLng> _points = [];
  final _nameCtrl = TextEditingController();
  String _zoneType = 'parking';
  bool _saving = false;

  static const _zoneTypes = ['parking', 'no-ride', 'slow', 'charging'];
  static const _typeLabels = {
    'parking': 'Парковка',
    'no-ride': 'Запрет движения',
    'slow': 'Медленная зона',
    'charging': 'Зарядка',
  };
  static const _typeColors = {
    'parking': Color(0xFF22C55E),
    'no-ride': Color(0xFFEF4444),
    'slow': Color(0xFFF59E0B),
    'charging': Color(0xFF6366F1),
  };

  @override
  void dispose() {
    _mapController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[_zoneType] ?? Colors.blue;

    return Column(
      children: [
        // ── Top toolbar ──
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Text('✏️ Редактор геозон',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Zone type selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _zoneType,
                  underline: const SizedBox(),
                  items: _zoneTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(color: _typeColors[t], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(_typeLabels[t] ?? t, style: const TextStyle(fontSize: 13)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() => _zoneType = v ?? 'parking'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _points.length >= 3 ? _saveZone : null,
                icon: _saving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save, size: 16),
                label: Text(_saving ? 'Сохранение...' : 'Сохранить зону'),
              ),
              const SizedBox(width: 8),
              if (_points.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _points.clear()),
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text('${_points.length} точек'),
                ),
            ],
          ),
        ),

        // ── Name input ──
        if (_points.length >= 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(children: [
              const Text('Название:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Например: Центр Ташкента',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ),

        // ── Map ──
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _tashkentCenter,
                  initialZoom: 14,
                  minZoom: 3,
                  maxZoom: 18,
                  onTap: (_, latlng) {
                    setState(() => _points.add(latlng));
                  },
                ),
                children: [
                  cachedTileLayer(),
                  // Draw polygon
                  if (_points.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _points,
                          color: color.withValues(alpha: 0.15),
                          borderColor: color,
                          borderStrokeWidth: 2.5,
                          isFilled: true,
                        ),
                      ],
                    ),
                  // Draw vertex markers
                  MarkerLayer(
                    markers: _points.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
                      return Marker(
                        point: p,
                        width: 28,
                        height: 28,
                        child: GestureDetector(
                          onTap: () => setState(() => _points.removeAt(i)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == 0 ? Colors.green : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: i == 0 ? Colors.white : Colors.black)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Help overlay when empty
              if (_points.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Тапайте по карте чтобы добавить вершины полигона.\nМинимум 3 точки для зоны.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Footer ──
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(children: [
            const Icon(Icons.touch_app, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Точки: ${_points.length}/3+ • Тап — добавить точку • Тап по точке — удалить',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ],
    );
  }

  Future<void> _saveZone() async {
    if (_points.length < 3) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : 'Зона ${DateTime.now().millisecond}';
      final coords = _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
      await ref.read(apiClientProvider).post('/zones/create', {
        'name': name,
        'type': _zoneType,
        'coordinates': coords,
      });
      if (mounted) {
        setState(() {
          _points.clear();
          _nameCtrl.clear();
          _saving = false;
        });
        showAdminSnack(context, 'Геозона "$name" сохранена');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAdminSnack(context, 'Ошибка: $e', isError: true);
      }
    }
  }
}
