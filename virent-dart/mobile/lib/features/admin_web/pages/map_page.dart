// map_page.dart — Admin: Local Tile Manager + Map
//
// Fully offline. Shows the local map. Admin can check tile cache status
// and clear it. Tiles are downloaded once via flutter_map's automatic
// caching when online — after that, the map works forever offline.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/map/local_tile_server.dart';
import '../../../../core/services/map/tile_cache_service.dart';
import '../widgets/admin_dialogs.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  static const _tashkentCenter = LatLng(41.3111, 69.2406);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloader = LocalTileDownloader.instance;
    final tileCount = downloader.countLocalTiles();
    final tileSizeMb = (downloader.localTilesSize() / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      children: [
        // ── Top controls bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              const Text('🗺️ Карта Ташкента (локально)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Clear cache button
              OutlinedButton.icon(
                onPressed: () => _confirmClearCache(downloader),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text('$tileCount тайлов • $tileSizeMb MB'),
              ),
            ],
          ),
        ),

        // ── Map ──
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _tashkentCenter,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              cachedTileLayer(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _tashkentCenter,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Status bar ──
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tileCount > 0
                      ? 'Локально: $tileCount тайлов ($tileSizeMb MB). Карта работает без интернета.'
                      : 'Тайлы не загружены. Откройте карту при интернете — flutter_map закеширует автоматически.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmClearCache(LocalTileDownloader downloader) {
    showAdminConfirmDialog(
      context,
      title: 'Очистить локальный кеш карты',
      message: 'Удалить все сохранённые тайлы? Без интернета карта станет тёмной.',
      onConfirm: () async {
        downloader.clearAll();
        if (mounted) {
          setState(() {});
          showAdminSnack(context, 'Кеш карты очищен');
        }
      },
    );
  }
}
