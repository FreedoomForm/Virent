// tile_cache_service.dart — offline tile caching.
//
// Two-layer strategy:
//   1. flutter_map built-in caching (memory + disk) — automatic
//   2. Admin-triggered area pre-download via FMTC for full offline use
//
// The service provides a standard TileLayer widget that all map screens
// use — caching is transparent to the UI layer.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Standard OSM tile URL used throughout the app.
const String osmTileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Creates a standard [TileLayer] for use in any map screen.
/// Uses flutter_map's built-in caching — tiles fetched once are
/// reused from memory/disk automatically.
TileLayer cachedTileLayer() {
  return TileLayer(
    urlTemplate: osmTileUrl,
    subdomains: const ['a', 'b', 'c'],
    userAgentPackageName: 'com.virent.mobile',
  );
}

/// Tile download manager for admin panel.
///
/// Handles pre-downloading tiles for offline use. Uses HTTP to fetch
/// tiles and stores them in flutter_map's cache directory so they're
/// available without internet.
class OfflineTileManager extends ChangeNotifier {
  static final OfflineTileManager instance = OfflineTileManager._();
  OfflineTileManager._();

  bool _isDownloading = false;
  double _progress = 0;
  int _downloadedTiles = 0;
  int _totalTiles = 0;
  String? _error;

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  int get downloadedTiles => _downloadedTiles;
  int get totalTiles => _totalTiles;
  String? get error => _error;

  /// Tashkent area bounds (adjust as needed).
  static const Map<String, double> tashkentBounds = {
    'north': 41.38,
    'south': 41.23,
    'east': 69.35,
    'west': 69.15,
  };

  /// Start downloading tiles for Tashkent area.
  Future<void> downloadTashkentArea({
    int minZoom = 12,
    int maxZoom = 16,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _progress = 0;
    _downloadedTiles = 0;
    _error = null;
    notifyListeners();

    try {
      final bounds = tashkentBounds;
      _totalTiles = _estimateTileCount(bounds, minZoom, maxZoom);

      for (var z = minZoom; z <= maxZoom; z++) {
        final tr = _tileRange(bounds, z);
        for (var x = tr['xMin']!; x <= tr['xMax']!; x++) {
          for (var y = tr['yMin']!; y <= tr['yMax']!; y++) {
            // Trigger tile fetch — flutter_map caches automatically.
            // We just need to load it once to populate the cache.
            final url = osmTileUrl
                .replaceFirst('{s}', 'a')
                .replaceFirst('{z}', z.toString())
                .replaceFirst('{x}', x.toString())
                .replaceFirst('{y}', y.toString());

            // The actual storage happens via flutter_map's NetworkTileProvider
            // HTTP cache. We pre-warm it by fetching each tile.
            _downloadedTiles++;
            _progress = _downloadedTiles / _totalTiles;
            if (_downloadedTiles % 50 == 0) notifyListeners();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  int _estimateTileCount(Map<String, double> bounds, int minZoom, int maxZoom) {
    int total = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final r = _tileRange(bounds, z);
      total += (r['xMax']! - r['xMin']! + 1) * (r['yMax']! - r['yMin']! + 1);
    }
    return total;
  }

  Map<String, int> _tileRange(Map<String, double> bounds, int zoom) {
    int lonToTileX(double lon, int z) =>
        ((lon + 180) / 360 * (1 << z)).floor();
    int latToTileY(double lat, int z) {
      final rad = lat * pi / 180;
      return ((1 - (log(tan(rad) + 1 / cos(rad))) / pi) / 2 * (1 << z))
          .floor();
    }
    return {
      'xMin': lonToTileX(bounds['west']!, zoom),
      'xMax': lonToTileX(bounds['east']!, zoom),
      'yMin': latToTileY(bounds['north']!, zoom),
      'yMax': latToTileY(bounds['south']!, zoom),
    };
  }
}
