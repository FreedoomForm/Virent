/// Shared JSON parsing helpers for all backend models.
///
/// These functions were previously duplicated across 20+ model files.
/// Centralising them here reduces bug surface — if a parsing edge case
/// needs fixing, it only needs to change once.
///
/// Import: `import 'json_helpers.dart';`
library;

/// Converts a dynamic value to a non-null ID string.
///
/// Handles MongoDB `{$oid: "..."}` objects, plain strings, and any
/// other type by calling `.toString()`.
String stringifyId(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map && value['\$oid'] != null) return value['\$oid'].toString();
  return value.toString();
}

/// Converts a dynamic value to a nullable ID string.
///
/// Returns `null` for null input, otherwise delegates to [stringifyId].
String? stringifyIdNullable(dynamic value) {
  if (value == null) return null;
  return stringifyId(value);
}

/// Converts a dynamic value to an [int], defaulting to 0.
///
/// Handles [int], [num], and string representations.
int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Converts a dynamic value to a [double], defaulting to 0.
///
/// Handles [num] and string representations.
double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

/// Converts a dynamic value to a nullable [String].
///
/// Returns `null` for null input, otherwise calls `.toString()`.
String? asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

/// Parses a dynamic value into a nullable [DateTime].
///
/// Handles:
/// - [DateTime] (returned as-is)
/// - [num] (treated as milliseconds since epoch, UTC)
/// - MongoDB `{$date: ...}` extended JSON (both numeric and string forms)
/// - ISO-8601 string representations
DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is Map) {
    final raw = value['\$date'];
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
    }
    if (raw is String) return DateTime.tryParse(raw);
  }
  return DateTime.tryParse(value.toString());
}
