// bundled_tile_extractor.dart — Extracts pre-bundled Tashkent tiles from APK assets.
//
// On first launch, extracts tiles from assets/tiles/tashkent/ to the
// file system (%APPDATA%/Virent/tiles/). flutter_map then reads them
// from disk — zero internet needed for the initial map view of Tashkent.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BundledTileExtractor {
  static bool _extracted = false;

  static Future<void> extractIfNeeded() async {
    if (_extracted) return;

    final tilesRoot = _tilesDir;
    final marker = File('$tilesRoot/.extracted');

    if (marker.existsSync()) {
      _extracted = true;
      return;
    }

    try {
      int count = 0;

      // Pre-bundled tiles: zooms 12-14 for Tashkent
      // Use a try/catch per tile so one failure doesn't stop the rest.
      for (final path in _bundledTilePaths) {
        try {
          final relPath = path.replaceFirst('assets/tiles/tashkent/', '');
          final target = File('$tilesRoot/$relPath');
          if (!target.existsSync()) {
            final data = await rootBundle.load(path);
            await target.parent.create(recursive: true);
            await target.writeAsBytes(data.buffer.asUint8List());
            count++;
          }
        } catch (_) {
          // Skip individual tile failures
        }
      }

      await marker.parent.create(recursive: true);
      await marker.writeAsString(DateTime.now().toIso8601String());

      debugPrint('[TILES] Extracted $count bundled tiles to $tilesRoot');
    } catch (e) {
      debugPrint('[TILES] Extract failed (will use online): $e');
    }
    _extracted = true;
  }

  static String get _tilesDir {
    if (Platform.isWindows) {
      return '${Platform.environment['APPDATA']}/Virent/tiles';
    }
    return '${Platform.environment['HOME']}/.virent/tiles';
  }

  /// Paths to bundled tiles.
  /// Generate with: scripts/generate-bundled-tiles.sh
  /// These are Tashkent city center tiles at zooms 12-14.
  static const _bundledTilePaths = <String>[
    // Zoom 12 core tiles (~10 tiles)
    'assets/tiles/tashkent/12/3125/1826.png',
    'assets/tiles/tashkent/12/3126/1826.png',
    'assets/tiles/tashkent/12/3125/1827.png',
    'assets/tiles/tashkent/12/3126/1827.png',
    'assets/tiles/tashkent/12/3124/1826.png',
    'assets/tiles/tashkent/12/3127/1826.png',
    'assets/tiles/tashkent/12/3124/1827.png',
    'assets/tiles/tashkent/12/3127/1827.png',
    'assets/tiles/tashkent/12/3125/1825.png',
    'assets/tiles/tashkent/12/3126/1825.png',
  ];
}
