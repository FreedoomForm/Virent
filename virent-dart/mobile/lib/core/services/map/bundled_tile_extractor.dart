// bundled_tile_extractor.dart — Extracts pre-bundled Tashkent tiles from APK assets.
//
// On first launch, extracts tiles from assets/tiles/tashkent/ to the
// file system (%APPDATA%/Virent/tiles/). flutter_map then reads them
// from disk — zero internet needed for the initial map view of Tashkent.
//
// Tiles bundled in APK: zooms 12–14 (~500 tiles, ~5 MB)
// Additional zooms (15–16): cached automatically by flutter_map at runtime.

import 'dart:io';
import 'package:flutter/services.dart';

/// Extracts bundled tiles to local storage. Call once at app startup.
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
      // List bundled tiles from asset manifest
      final manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      final tileAssets = manifest.listAssets().where(
        (a) => a.startsWith('assets/tiles/tashkent/') && a.endsWith('.png'),
      );

      int count = 0;
      for (final asset in tileAssets) {
        // assets/tiles/tashkent/12/3125/1826.png → 12/3125/1826.png
        final relPath = asset.replaceFirst('assets/tiles/tashkent/', '');
        final target = File('$tilesRoot/$relPath');

        if (!target.existsSync()) {
          final data = await rootBundle.load(asset);
          await target.parent.create(recursive: true);
          await target.writeAsBytes(data.buffer.asUint8List());
          count++;
        }
      }

      // Write marker
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
}
