// map_page.dart — Fleet map with scooter markers + geofence zones.
//
// Renders a flutter_map centred on Tashkent, overlays:
//   * Scooter markers coloured by status (green=available, red=busy, gray=offline)
//   * Geofence polygons from zonesListProvider
//   * Filter chips to toggle status visibility
//   * Map type tabs: Обычная / Тепловая / Частота аренд / Группировка
//
// Loading and error states are handled via AsyncValue.when on both the
// scooters and zones providers.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/map/tile_cache_service.dart';
import '../admin_web_providers.dart';
import '../widgets/admin_colors.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _tashkentCenter = LatLng(41.3111, 69.2406);

  final MapController _mapController = MapController();

  /// Index of the selected map-type tab.
  /// 0 = Обычная, 1 = Тепловая, 2 = Частота аренд, 3 = Группировка.
  int _mapTypeIndex = 0;

  /// Filter toggles for scooter status visibility.
  final Map<String, bool> _statusFilters = {
    'available': true,
    'busy': true,
    'offline': true,
  };

  /// Whether to show the geofence overlay.
  bool _showZones = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scootersAsync = ref.watch(scootersListProvider);
    final zonesAsync = ref.watch(zonesListProvider);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filters section ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Фильтры',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: adminTextDark)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusFilterChip(
                        'Свободные',
                        'available',
                        const Color(0xFF42BA96),
                      ),
                      _statusFilterChip(
                        'Занятые',
                        'busy',
                        const Color(0xFFDF4759),
                      ),
                      _statusFilterChip(
                        'Не в сети',
                        'offline',
                        const Color(0xFF868686),
                      ),
                      const SizedBox(width: 12),
                      _filterChip('Модель', adminPrimary),
                      _filterChip('Группы', adminPrimary),
                      const SizedBox(width: 8),
                      _smallInput('Номер', 100),
                      const SizedBox(width: 4),
                      _smallInput('Телефон', 120),
                      const SizedBox(width: 4),
                      const Text('Батарея:',
                          style: TextStyle(
                              fontSize: 11, color: adminTextGray)),
                      const SizedBox(width: 4),
                      _smallInput('От (%)', 60),
                      _smallInput('До (%)', 60),
                      const SizedBox(width: 12),
                      _filterChip('На линии', adminInfo),
                      _filterChip('Не на линии', adminWarning),
                      _filterChip('Тревоги отключены', adminSuccess),
                      _filterChip('Тревоги включены', adminSuccess),
                      _filterChip('Режим Raider', adminDanger,
                          outlined: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filterChip('Ташкент', adminPrimary),
                    _filterChip('Самарканд', adminPrimary),
                    _filterChip('Фергана', adminTextDark),
                  ],
                ),
              ],
            ),
          ),

          // ── Map type tabs ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Текущая карта: ${_mapTypeLabel(_mapTypeIndex)}",
                  style: const TextStyle(
                      fontSize: 13, color: adminTextGray),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tabButton('Обычная', 0),
                    _tabButton('Тепловая', 1),
                    _tabButton('Частота аренд', 2),
                    _tabButton('Группировка', 3),
                  ],
                ),
              ],
            ),
          ),

          // ── Map + sidebar ──
          Expanded(
            child: Row(
              children: [
                // Map area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 0, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E0D8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: adminBorder),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        // The actual map — handles loading + error states.
                        scootersAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                "Ошибка загрузки самокатов: $e",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: adminDanger, fontSize: 13),
                              ),
                            ),
                          ),
                          data: (scooters) {
                            return zonesAsync.when(
                              loading: () => FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _tashkentCenter,
                                  initialZoom: 12,
                                  minZoom: 3,
                                  maxZoom: 18,
                                ),
                                children: [
                                  cachedTileLayer(),
                                  _buildScooterMarkers(scooters),
                                ],
                              ),
                              error: (e, _) => Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _tashkentCenter,
                                      initialZoom: 12,
                                      minZoom: 3,
                                      maxZoom: 18,
                                    ),
                                    children: [
                                      cachedTileLayer(),
                                      _buildScooterMarkers(scooters),
                                    ],
                                  ),
                                  Positioned(
                                    left: 12,
                                    top: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: adminDanger),
                                      ),
                                      child: Text(
                                        "Геозоны: $e",
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: adminDanger),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              data: (zones) => FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _tashkentCenter,
                                  initialZoom: 12,
                                  minZoom: 3,
                                  maxZoom: 18,
                                ),
                                children: [
                                  cachedTileLayer(),
                                  if (_showZones) _buildZonePolygons(zones),
                                  _buildScooterMarkers(scooters),
                                ],
                              ),
                            );
                          },
                        ),

                        // Zoom controls overlay
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Column(
                            children: [
                              _zoomButton(Icons.add, () {
                                final z =
                                    (_mapController.camera.zoom + 1)
                                        .clamp(3.0, 18.0);
                                _mapController.move(
                                    _mapController.camera.center, z);
                              }),
                              const SizedBox(height: 2),
                              _zoomButton(Icons.remove, () {
                                final z =
                                    (_mapController.camera.zoom - 1)
                                        .clamp(3.0, 18.0);
                                _mapController.move(
                                    _mapController.camera.center, z);
                              }),
                            ],
                          ),
                        ),

                        // Map type overlay label (for non-default modes)
                        if (_mapTypeIndex != 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _mapTypeLabel(_mapTypeIndex),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Right info panel ──
                Container(
                  width: 220,
                  margin: const EdgeInsets.fromLTRB(8, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: adminBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _showZones = !_showZones),
                          child: Row(
                            children: [
                              Icon(
                                _showZones
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: Colors.blue,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text('Показывать геозоны',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._infoFields(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the subset of scooters whose status filter is currently on.
  List<Map<String, dynamic>> _filteredScooters(
      List<Map<String, dynamic>> scooters) {
    return scooters.where((s) {
      final status = _scooterStatusKey(s);
      return _statusFilters[status] ?? true;
    }).toList();
  }

  Widget _buildScooterMarkers(List<Map<String, dynamic>> scooters) {
    final visible = _filteredScooters(scooters);
    return MarkerLayer(
      markers: visible.map((s) {
        final lat = _parseDouble(s['lat'] ?? s['latitude']);
        final lng = _parseDouble(s['lng'] ?? s['longitude']);
        if (lat == null || lng == null) {
          return Marker(
            point: _tashkentCenter,
            width: 24,
            height: 24,
            child: const Icon(Icons.location_off,
                color: adminTextGray, size: 18),
          );
        }
        final statusKey = _scooterStatusKey(s);
        final color = statusKey == 'available'
            ? const Color(0xFF42BA96)
            : statusKey == 'busy'
                ? const Color(0xFFDF4759)
                : const Color(0xFF868686);
        return Marker(
          point: LatLng(lat, lng),
          width: 24,
          height: 24,
          child: GestureDetector(
            onTap: () => _showScooterInfo(s),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3)
                ],
              ),
              child: const Icon(Icons.electric_scooter,
                  color: Colors.white, size: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildZonePolygons(List<Map<String, dynamic>> zones) {
    final polygons = <Polygon>[];
    for (final z in zones) {
      final points = _extractZonePoints(z);
      if (points.length < 3) continue;
      final type = (z['type'] ?? z['zone_type'] ?? 'parking').toString();
      final color = _zoneColor(type);
      polygons.add(Polygon(
        points: points,
        color: color.withValues(alpha: 0.15),
        borderColor: color,
        borderStrokeWidth: 2.0,
        isFilled: true,
      ));
    }
    return PolygonLayer(polygons: polygons);
  }

  /// Maps a scooter map to one of three status buckets used by the markers.
  String _scooterStatusKey(Map<String, dynamic> s) {
    final raw = (s['status'] ?? s['state'] ?? '').toString().toLowerCase();
    final isOnline = (s['online'] ?? s['is_online'] ?? true) == true;
    if (raw == 'offline' || raw == 'оффлайн' || !isOnline) return 'offline';
    if (raw == 'riding' ||
        raw == 'busy' ||
        raw == 'rented' ||
        raw == 'в аренде') {
      return 'busy';
    }
    return 'available';
  }

  /// Extracts a list of [LatLng] points from a zone map.
  /// Supports `coordinates` (list of {lat,lng}) and `polygon` (list of [lat,lng]).
  List<LatLng> _extractZonePoints(Map<String, dynamic> z) {
    final coords = z['coordinates'] ?? z['polygon'] ?? z['points'];
    if (coords is! List) return const [];
    final out = <LatLng>[];
    for (final c in coords) {
      if (c is Map) {
        final lat = _parseDouble(c['lat'] ?? c['latitude']);
        final lng = _parseDouble(c['lng'] ?? c['lon'] ?? c['longitude']);
        if (lat != null && lng != null) out.add(LatLng(lat, lng));
      } else if (c is List && c.length >= 2) {
        final lat = _parseDouble(c[0]);
        final lng = _parseDouble(c[1]);
        if (lat != null && lng != null) out.add(LatLng(lat, lng));
      }
    }
    return out;
  }

  Color _zoneColor(String type) {
    switch (type) {
      case 'parking':
        return const Color(0xFF22C55E);
      case 'no-ride':
        return const Color(0xFFEF4444);
      case 'slow':
        return const Color(0xFFF59E0B);
      case 'charging':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF467FD0);
    }
  }

  void _showScooterInfo(Map<String, dynamic> s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Самокат #${s['id'] ?? s['scooter_id'] ?? '-'}"),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Статус', "${s['status'] ?? '-'}"),
              _infoRow('Батарея',
                  "${s['battery'] ?? s['battery_level'] ?? '-'}%"),
              _infoRow('Госномер', "${s['gosnomer'] ?? s['plate'] ?? '-'}"),
              _infoRow('Модель',
                  "${s['model'] ?? s['model_name'] ?? '-'}"),
              _infoRow(
                  'Координаты',
                  "${_parseDouble(s['lat'] ?? s['latitude'])?.toStringAsFixed(4) ?? '-'}, "
                  "${_parseDouble(s['lng'] ?? s['longitude'])?.toStringAsFixed(4) ?? '-'}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
                text: "$label: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _mapTypeLabel(int i) {
    switch (i) {
      case 1:
        return 'Тепловая карта';
      case 2:
        return 'Частота аренд';
      case 3:
        return 'Группировка самокатов';
      default:
        return 'Обычная карта';
    }
  }

  List<Widget> _infoFields() {
    final fields = [
      'Номер',
      'Обновлено',
      'Группы',
      'Заказ',
      '',
      '',
      '',
      '',
      '',
      '',
      'Геозоны',
      'Блокировка',
      'Комментарий',
      'Отсек Батареи',
      'Режим Raider'
    ];
    return fields.map((f) {
      if (f.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Divider(color: adminBorder)),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: adminTextDark)),
            const Divider(height: 8),
          ],
        ),
      );
    }).toList();
  }

  /// Status filter chip with a checkbox-like toggle. Tapping toggles
  /// visibility of the corresponding status.
  Widget _statusFilterChip(String label, String key, Color color) {
    final selected = _statusFilters[key] ?? true;
    return GestureDetector(
      onTap: () => setState(() => _statusFilters[key] = !selected),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check : Icons.close,
              size: 10,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, Color color, {bool outlined = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(3),
        border: outlined ? Border.all(color: color) : null,
      ),
      child: Text(label,
          style: TextStyle(
              color: outlined ? color : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _smallInput(String hint, double width) {
    return SizedBox(
      width: width,
      height: 28,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(color: adminBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide(color: adminBorder)),
        ),
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _mapTypeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _mapTypeIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? adminPrimary : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
              color: active ? adminPrimary : adminBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: active ? Colors.white : adminTextGray)),
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: adminTextGray),
      ),
      child: SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 16),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
