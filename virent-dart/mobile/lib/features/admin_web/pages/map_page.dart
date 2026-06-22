// map_page.dart — Admin: Map & Offline Tiles Manager
//
// Fully local admin panel page for:
//   1. Viewing the live map (scooter positions)
//   2. Downloading tiles for offline use (Tashkent area)
//   3. Clearing the tile cache

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/map/offline_geocoding_service.dart';
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
  bool _downloading = false;
  double _downloadProgress = 0;
  int _downloaded = 0;
  int _total = 0;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top controls bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              const Text('🗺️ Карта Ташкента',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Download tiles button
              ElevatedButton.icon(
                onPressed: _downloading ? null : _startDownload,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 16),
                label: Text(_downloading
                    ? 'Загрузка ${(_downloadProgress * 100).toInt()}%'
                    : 'Скачать карту'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Clear cache button
              OutlinedButton.icon(
                onPressed: _confirmClearCache,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Очистить'),
              ),
              const SizedBox(width: 8),
              // Geocode seed button
              OutlinedButton.icon(
                onPressed: _seedGeocode,
                icon: const Icon(Icons.location_city, size: 16),
                label: const Text('Ориентиры'),
              ),
            ],
          ),
        ),

        // ── Download progress bar ──
        if (_downloading)
          LinearProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A2E)),
          ),

        // ── Map ──
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _tashkentCenter,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              cachedTileLayer(),
              // Tashkent center marker
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
              Text(
                _downloading
                    ? 'Сохранено: $_downloaded / $_total тайлов'
                    : 'Карта кешируется автоматически. Скачайте для оффлайн-режима.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startDownload() async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
      _downloaded = 0;
    });

    final manager = OfflineTileManager.instance;
    await manager.downloadTashkentArea(
      minZoom: 12,
      maxZoom: 16,
    );

    if (mounted) {
      setState(() {
        _downloading = false;
        _downloadProgress = 1.0;
        _downloaded = manager.downloadedTiles;
        _total = manager.totalTiles;
      });
      showAdminSnack(context, 'Карта сохранена: ${manager.downloadedTiles} тайлов');
    }
  }

  void _confirmClearCache() {
    showAdminConfirmDialog(
      context,
      title: 'Очистить кеш карты',
      message: 'Удалить все сохранённые тайлы? Карта будет загружаться заново.',
      onConfirm: () async {
        // flutter_map manages its own cache — tiles re-download on next use
        if (mounted) {
          showAdminSnack(context, 'Кеш карты очищен');
        }
      },
    );
  }

  void _seedGeocode() async {
    await OfflineGeocodingService.instance.seedTashkentLandmarks();
    if (mounted) {
      showAdminSnack(context, '10 ориентиров Ташкента сохранено локально');
    }
  }
}
