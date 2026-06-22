// persistent_store.dart — JSON-file persistence for the Virent DataStore.
//
// Writes the entire DataStore as an atomic JSON file on disk. On startup,
// loads the last saved state. Every mutation schedules a debounced save
// (3-second cooldown) so rapid operations don't thrash the disk.
//
// Production notes:
//   For single-PC deployment (desktop app + embedded server) this is more
//   than sufficient. For multi-server / VPS deployments swap this for
//   PostgreSQL or MongoDB — the DataStore.toJson()/fromJson() contract
//   stays identical.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../backend/embedded_server.dart' show DataStore;
import '../../utils/logger.dart';

/// Manages persistent save/load of the [DataStore] to a local JSON file.
///
/// Usage:
/// ```dart
/// final store = PersistentStore();
/// await store.init();
/// store.attach(dataStore);  // starts auto-saving
/// // ... app runs ...
/// await store.dispose();    // flushes final save
/// ```
class PersistentStore {
  File? _file;
  Timer? _saveTimer;
  DataStore? _data;
  bool _dirty = false;
  bool _initialised = false;

  /// Full path to the JSON file.
  Future<String> get _filePath async {
    if (kIsWeb) return ''; // no persistence on web
    final dir = await getApplicationSupportDirectory();
    final virentDir = Directory('${dir.path}/Virent');
    if (!await virentDir.exists()) {
      await virentDir.create(recursive: true);
    }
    return '${virentDir.path}/datastore.json';
  }

  /// Initialise the store and load any previously-saved data into [data].
  ///
  /// Returns the loaded JSON map, or `null` when no save file exists yet.
  /// Callers should pass the result to [DataStore.fromJson].
  Future<Map<String, dynamic>?> init() async {
    if (_initialised) return null;
    _initialised = true;

    try {
      final path = await _filePath;
      if (path.isEmpty) return null;
      _file = File(path);
      if (!await _file!.exists()) {
        AppLogger.info('No saved data found — starting fresh', tag: 'DB');
        return null;
      }
      final content = await _file!.readAsString();
      if (content.isEmpty) return null;
      final json = jsonDecode(content) as Map<String, dynamic>;
      AppLogger.info(
        'Loaded saved state: ${json['users']?.length ?? 0} users, '
        '${json['trips']?.length ?? 0} trips, '
        '${(json['scooters'] as List?)?.length ?? 0} scooters',
        tag: 'DB',
      );
      return json;
    } catch (e) {
      AppLogger.error('Failed to load saved state', error: e, tag: 'DB');
      return null;
    }
  }

  /// Attach a [DataStore] for auto-saving. Every mutation should call
  /// [markDirty] to schedule a save.
  void attach(DataStore data) {
    _data = data;
  }

  /// Mark data as changed — schedules a debounced save.
  void markDirty() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () => _flush());
  }

  /// Force an immediate save (e.g., on app shutdown).
  Future<void> flush() async {
    _saveTimer?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    if (!_dirty || _data == null) return;
    _dirty = false;

    try {
      final json = _data!.toJson();
      final content = const JsonEncoder.withIndent('  ').convert(json);

      // Atomic write: write to temp file, then rename.
      final path = await _filePath;
      if (path.isEmpty) return;
      final tmpFile = File('$path.tmp');
      await tmpFile.writeAsString(content, flush: true);
      await tmpFile.rename(path);
    } catch (e) {
      AppLogger.error('Failed to save state', error: e, tag: 'DB');
    }
  }

  /// Call on app shutdown — flushes any pending save.
  Future<void> dispose() async {
    _saveTimer?.cancel();
    await _flush();
  }
}
