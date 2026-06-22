// error_logger.dart — Local error logging (offline Sentry alternative).
//
// Writes errors to SQLite table `error_log` and a rotating log file.
// Admin can view errors in the admin panel.
// Zero external services — fully local.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class ErrorLogger {
  static final ErrorLogger instance = ErrorLogger._();
  ErrorLogger._();

  Database? _db;

  Future<void> init(Database db) async {
    _db = db;
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS error_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        stack_trace TEXT,
        context TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// Log an error with optional stack trace and context.
  Future<void> log(
    dynamic error,
    StackTrace? stackTrace, {
    String context = '',
  }) async {
    final msg = error.toString();
    final trace = stackTrace?.toString() ?? '';

    debugPrint('[ERROR] $msg');

    // Write to SQLite
    try {
      await _db?.insert('error_log', {
        'message': msg,
        'stack_trace': trace.length > 2000 ? trace.substring(0, 2000) : trace,
        'context': context,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}

    // Write to log file
    try {
      final dir = _logDir;
      await Directory(dir).create(recursive: true);
      final file = File('$dir/virent_errors.log');
      final line = '[${DateTime.now().toIso8601String()}] $msg\n$trace\n---\n';
      await file.writeAsString(line, mode: FileMode.append);
      // Rotate if > 5 MB
      if (await file.length() > 5 * 1024 * 1024) {
        await file.rename('$dir/virent_errors.old.log');
      }
    } catch (_) {}
  }

  /// Get recent errors from SQLite.
  Future<List<Map<String, dynamic>>> getRecentErrors({int limit = 50}) async {
    try {
      return await _db?.query('error_log',
            orderBy: 'created_at DESC', limit: limit) ??
          [];
    } catch (_) {
      return [];
    }
  }

  String get _logDir {
    if (Platform.isWindows) return '${Platform.environment['APPDATA']}/Virent/logs';
    return '${Platform.environment['HOME']}/.virent/logs';
  }
}
