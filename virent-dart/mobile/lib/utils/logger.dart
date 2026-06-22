// logger.dart — lightweight tagged logger.
//
// Wraps the `logger` package behind a single `AppLogger` facade with the
// standard level set (debug / info / warn / error) and tag support, so
// every feature can emit structured lines without depending on a specific
// logging library. Ported from BarqScoot's `lib/utils/logger.dart` and
// re-tuned for Virent (default tag `VIRENT`).
//
// Usage:
//   AppLogger.info('Trip started', tag: 'RIDE');
//   AppLogger.error('OTP verify failed', error: e, stackTrace: st);

import 'package:logger/logger.dart';

/// Severity-ordered tagged logger used across the Virent app.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  /// Default tag prepended to every line when no explicit tag is given.
  static const String defaultTag = 'VIRENT';

  /// Informational message — normal operation flow.
  static void info(String message, {String tag = defaultTag}) {
    _logger.i('[$tag] $message');
  }

  /// Alias of [info] kept for BarqScoot parity.
  static void log(String message, {String tag = defaultTag}) =>
      info(message, tag: tag);

  /// Verbose diagnostic message — hidden in release builds.
  static void debug(String message, {String tag = defaultTag}) {
    _logger.d('[$tag] $message');
  }

  /// Recoverable warning — something unexpected but not fatal.
  static void warning(String message, {String tag = defaultTag}) {
    _logger.w('[$tag] $message');
  }

  /// Error condition — also logs [error] and [stackTrace] when supplied.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = defaultTag,
  }) {
    _logger.e(
      '[$tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Very verbose trace — typically disabled in production.
  static void trace(String message, {String tag = defaultTag}) {
    _logger.t('[$tag] $message');
  }
}
