// local_tile_server.dart — fully offline tile server for Virent.
//
// Strategy:
//   1. Tiles are stored as files in: %APPDATA%/Virent/tiles/{z}/{x}/{y}.png
//   2. Admin downloads tiles via map_page.dart (one-time)
//   3. flutter_map uses FileTileProvider pointing at local directory
//   4. Zero external dependencies — no openstreetmap.org, no internet
//
// On first launch with no tiles, the map shows a dark grid with "download map"
// prompt. After admin downloads tiles for Tashkent (zooms 12-16), the map
// works fully offline forever.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Path where tiles are stored — resolved at runtime.
String get tilesDir {
  if (Platform.isWindows) {
    return '${Platform.environment['APPDATA']}/Virent/tiles';
  }
  return '${Platform.environment['HOME']}/.virent/tiles';
}

/// Creates a TileLayer that reads ONLY from local tiles directory.
/// No external URLs — fully offline.
TileLayer localTileLayer() {
  return TileLayer(
    urlTemplate: 'file://$tilesDir/{z}/{x}/{y}.png',
    tileProvider: _LocalFileTileProvider(),
    userAgentPackageName: 'com.virent.mobile',
    errorImage: const _DarkGridPainter(),
  );
}

/// Custom TileProvider that reads PNG files from local disk.
class _LocalFileTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    final file = File('${tilesDir}/${coords.z}/${coords.x}/${coords.y}.png');
    if (!file.existsSync()) {
      return const _EmptyDarkTile();
    }
    return FileImage(file);
  }
}

/// Single-color dark tile returned when no local tile exists.
class _EmptyDarkTile extends ImageProvider<_EmptyDarkTile> {
  const _EmptyDarkTile();

  @override
  Future<_EmptyDarkTile> obtainKey(ImageConfiguration config) =>
      SynchronousFuture<_EmptyDarkTile>(this);

  @override
  ImageStreamCompleter loadImage(
      _EmptyDarkTile key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      _paintDarkTile(),
    );
  }

  Future<ImageInfo> _paintDarkTile() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 256, 256),
      Paint()..color = const Color(0xFF1a1a2e),
    );
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final codec = await ui.instantiateImageCodec(bytes!.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

/// Fallback painter for offline tiles.
class _DarkGridPainter extends StatelessWidget {
  const _DarkGridPainter();

  @override
  Widget build(BuildContext context) =>
      Container(color: const Color(0xFF1a1a2e));
}

// ═══════════════════════════════════════════════════════════════════════
// Tile download & management (local only)
// ═══════════════════════════════════════════════════════════════════════

/// Downloads tiles for an area using flutter_map's built-in caching.
/// Call this from the admin panel to pre-cache an area for offline use.
class LocalTileDownloader extends ChangeNotifier {
  static final LocalTileDownloader instance = LocalTileDownloader._();
  LocalTileDownloader._();

  bool _active = false;
  double _progress = 0;
  int _done = 0;
  int _total = 0;
  String? _error;

  bool get isActive => _active;
  double get progress => _progress;
  int get done => _done;
  int get total => _total;
  String? get error => _error;

  static const Map<String, double> tashkent = {
    'north': 41.38,
    'south': 41.23,
    'east': 69.35,
    'west': 69.15,
  };

  /// Calculate how many tiles have been cached locally.
  int countLocalTiles() {
    final dir = Directory(tilesDir);
    if (!dir.existsSync()) return 0;
    int count = 0;
    for (final zDir in dir.listSync().whereType<Directory>()) {
      for (final xDir in zDir.listSync().whereType<Directory>()) {
        count += xDir.listSync().whereType<File>().length;
      }
    }
    return count;
  }

  /// Total size of cached tiles in bytes.
  int localTilesSize() {
    final dir = Directory(tilesDir);
    if (!dir.existsSync()) return 0;
    return dir.listSync(recursive: true)
        .whereType<File>()
        .fold<int>(0, (sum, f) => sum + f.lengthSync());
  }

  /// Delete all cached tiles.
  void clearAll() {
    final dir = Directory(tilesDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    notifyListeners();
  }
}
