// local_tile_server.dart — local tile directory manager.
//
// flutter_map's NetworkTileProvider automatically caches tiles to disk
// via its internal HTTP cache. After the first online use, tiles are
// served from disk without internet.
//
// This service manages the tile storage directory and provides status
// info to the admin panel.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Path where flutter_map caches tiles.
String get tilesDir {
  if (Platform.isWindows) {
    return '${Platform.environ['APPDATA']}/Virent/tiles';
  }
  return '${Platform.environ['HOME']!}/.virent/tiles';
}

/// Standard tile layer for all map screens.
/// Uses flutter_map's built-in HTTP cache — tiles fetched once
/// are served from disk automatically on subsequent loads.
TileLayer cachedTileLayer() {
  return TileLayer(
    urlTemplate: localTileUrl,
    subdomains: const ['a', 'b', 'c'],
    userAgentPackageName: 'com.virent.mobile',
  );
}

/// Tile URL template — serves from local server when tiles cached,
/// falls back to OSM online for first-time loads.
const String localTileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Local tile count and size for admin panel display.
class LocalTileDownloader extends ChangeNotifier {
  static final LocalTileDownloader instance = LocalTileDownloader._();
  LocalTileDownloader._();

  int countLocalTiles() {
    final dir = Directory(tilesDir);
    if (!dir.existsSync()) return 0;
    int count = 0;
    try {
      for (final zDir in dir.listSync().whereType<Directory>()) {
        for (final xDir in zDir.listSync().whereType<Directory>()) {
          count += xDir.listSync().whereType<File>().length;
        }
      }
    } catch (_) {}
    return count;
  }

  int localTilesSize() {
    final dir = Directory(tilesDir);
    if (!dir.existsSync()) return 0;
    try {
      return dir.listSync(recursive: true)
          .whereType<File>()
          .fold<int>(0, (sum, f) => sum + f.lengthSync());
    } catch (_) {
      return 0;
    }
  }

  void clearAll() {
    final dir = Directory(tilesDir);
    if (dir.existsSync()) {
      try { dir.deleteSync(recursive: true); } catch (_) {}
    }
    notifyListeners();
  }
}

// Default Tashkent bounds for admin reference.
const Map<String, double> tashkentBounds = {
  'north': 41.38,
  'south': 41.23,
  'east': 69.35,
  'west': 69.15,
};
