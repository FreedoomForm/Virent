// cache_service.dart — In-process LRU cache with TTL.
//
// Ported from backend/src/shared/cache.js. Per constitution §15:
//   - No cache without TTL
//   - No cache without owner
//   - Cache hit/miss logged via [stats]
//
// Implements levels L0/L1 (request memoization + application memory). L2
// (Redis) is a separate module for production deployments.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

/// A single cache entry.
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  final DateTime createdAt;

  const _CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Snapshot of cache statistics for observability.
class CacheStats {
  final int size;
  final int maxSize;
  final int hits;
  final int misses;
  final double hitRate;

  const CacheStats({
    required this.size,
    required this.maxSize,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'max_size': maxSize,
        'hits': hits,
        'misses': misses,
        'hit_rate': hitRate,
      };

  @override
  String toString() =>
      'CacheStats(size=$size/$maxSize, hits=$hits, misses=$misses, '
      'hitRate=${(hitRate * 100).toStringAsFixed(1)}%)';
}

/// LRU (Least-Recently-Used) cache with per-entry TTL.
///
/// Backed by a [LinkedHashMap] which preserves insertion order. Each [get]
/// on a live entry re-inserts it at the end (most-recently-used position).
/// When [maxSize] is reached the oldest entry is evicted.
///
/// Per constitution §15 every entry MUST have a TTL — there is no
/// TTL-less `set` overload.
class LruCache {
  /// Maximum number of entries before the oldest is evicted.
  final int maxSize;

  final LinkedHashMap<String, _CacheEntry> _store = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;

  LruCache({this.maxSize = 1000});

  /// Builds the composite cache key `namespace:version:key`.
  ///
  /// Non-string keys are JSON-encoded so Maps and Lists work as keys too.
  String _key(String namespace, Object key, [String? version]) {
    final k = key is String ? key : jsonEncode(key);
    return '$namespace:${version ?? 'v1'}:$k';
  }

  /// Fetches a value by composite key.
  ///
  /// Returns `null` on miss (expired entries are evicted and counted as a
  /// miss). Hits re-insert the entry at the most-recently-used position so
  /// the LRU eviction order is updated.
  dynamic get(String namespace, Object key, [String? version]) {
    final k = _key(namespace, key, version);
    final entry = _store[k];
    if (entry == null) {
      _misses++;
      return null;
    }
    if (entry.isExpired) {
      _store.remove(k);
      _misses++;
      return null;
    }
    // Move to end (most recently used).
    _store.remove(k);
    _store[k] = entry;
    _hits++;
    return entry.value;
  }

  /// Stores [value] under the composite key with a [ttlSec] second TTL.
  ///
  /// If the cache is at capacity, the oldest entry is evicted first.
  void set(
    String namespace,
    Object key,
    dynamic value, {
    int ttlSec = 60,
    String? version,
  }) {
    if (ttlSec <= 0) {
      throw ArgumentError('ttlSec must be > 0 (constitution §15)');
    }
    final k = _key(namespace, key, version);
    if (_store.length >= maxSize && !_store.containsKey(k)) {
      _store.remove(_store.keys.first);
    }
    final now = DateTime.now();
    _store[k] = _CacheEntry(
      value: value,
      expiresAt: now.add(Duration(seconds: ttlSec)),
      createdAt: now,
    );
  }

  /// Invalidates a single key (when [key] is provided) or all keys in a
  /// namespace (when [key] is omitted).
  void invalidate(String namespace, [Object? key, String? version]) {
    if (key == null) {
      final prefix = '$namespace:';
      _store.removeWhere((k, _) => k.startsWith(prefix));
    } else {
      _store.remove(_key(namespace, key, version));
    }
  }

  /// Returns a snapshot of hit/miss statistics.
  CacheStats stats() {
    final total = _hits + _misses;
    return CacheStats(
      size: _store.length,
      maxSize: maxSize,
      hits: _hits,
      misses: _misses,
      hitRate: total > 0 ? _hits / total : 0,
    );
  }

  /// Clears every entry and resets the hit/miss counters.
  void clear() {
    _store.clear();
    _hits = 0;
    _misses = 0;
  }
}

/// Process-wide singleton cache used by [getOrSet] and the view executor.
///
/// Sized for an embedded backend — bump for production if needed.
final LruCache globalCache = LruCache(maxSize: 2000);

/// Get-or-set pattern: returns the cached value if present (and not expired),
/// otherwise invokes [fetchFn] and stores the result.
///
/// `null` / `undefined` results from [fetchFn] are NOT cached (so a failed
/// lookup will retry on the next call rather than wedging the cache).
Future<T?> getOrSet<T>(
  String namespace,
  Object key,
  int ttlSec,
  Future<T?> Function() fetchFn, {
  String? version,
}) async {
  final cached = globalCache.get(namespace, key, version);
  if (cached != null) return cached as T;
  final fresh = await fetchFn();
  if (fresh != null) {
    globalCache.set(namespace, key, fresh, ttlSec: ttlSec, version: version);
  }
  return fresh;
}
