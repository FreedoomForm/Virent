// tile_cache_service.dart — fully offline tile layer factory.
//
// Every map screen in Virent calls `cachedTileLayer()` to get a TileLayer
// that reads tiles from the local disk. No external tile servers.
//
// After the admin downloads tiles for Tashkent (zooms 12-16) via the
// map page, the entire map works without internet.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'local_tile_server.dart' show localTileLayer, LocalTileDownloader;

/// Standard tile layer for all map screens.
/// Fully offline — reads from local tiles directory.
TileLayer cachedTileLayer() => localTileLayer();
