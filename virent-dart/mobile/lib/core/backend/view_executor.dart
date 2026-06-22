// view_executor.dart — Request Tree executor.
//
// Ported from backend/src/views/executor.js. Per constitution §6.2: the
// backend executes a request tree by:
//   1. Accept request
//   2. Check auth
//   3. Check permissions
//   4. Read sections param
//   5. Build dependency tree
//   6. Remove unwanted branches
//   7. Check cache
//   8. Group identical requests
//   9. Execute independent nodes in parallel
//  10. Limit concurrency
//  11. Assemble response
//  12. Write metrics/logs
//
// Each node has: [id], [useCase] (async fn), [priority] (B0/B1/B2/B3),
// [dependsOn] (list of node ids), [cache] (ttlSec + contextKeys), [required].

import 'dart:async';
import 'dart:convert';

import 'cache_service.dart';

/// Priority band — B0 is critical, B3 is best-effort.
enum Priority { b0, b1, b2, b3 }

/// Per-node cache config.
class NodeCache {
  /// TTL in seconds. `0` disables caching for this node.
  final int ttlSec;

  /// Context keys whose values participate in the cache key.
  final List<String> contextKeys;

  const NodeCache({required this.ttlSec, this.contextKeys = const []});
}

/// A single node in a [ViewSection].
class ViewNode {
  final String id;
  final Future<dynamic> Function(Map<String, dynamic> ctx) useCase;
  final Priority priority;
  final List<String> dependsOn;
  final NodeCache? cache;

  const ViewNode({
    required this.id,
    required this.useCase,
    this.priority = Priority.b1,
    this.dependsOn = const [],
    this.cache,
  });
}

/// A section is a group of nodes that share a cache namespace and are
/// executed together (with cross-node dependencies resolved in-section).
class ViewSection {
  final List<ViewNode> nodes;
  final bool required;
  final int cacheTtlSec;
  final String cacheNamespace;
  final String cacheVersion;
  final List<String> cacheContextKeys;

  const ViewSection({
    required this.nodes,
    this.required = true,
    this.cacheTtlSec = 0,
    this.cacheNamespace = 'view',
    this.cacheVersion = 'v1',
    this.cacheContextKeys = const [],
  });
}

/// A view tree is a collection of named sections.
class ViewTree {
  final Map<String, ViewSection> sections;
  const ViewTree({required this.sections});
}

/// Per-section execution metadata.
class SectionMeta {
  final int ms;
  final String cacheStatus; // HIT | MISS | ERROR
  final String? error;

  const SectionMeta({
    required this.ms,
    required this.cacheStatus,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'ms': ms,
        'cache': cacheStatus,
        if (error != null) 'error': error,
      };
}

/// Top-level execution result.
class ViewExecutionResult {
  final Map<String, Map<String, dynamic>> data;
  final Map<String, SectionMeta> sections;
  final bool partial;
  final int totalMs;

  const ViewExecutionResult({
    required this.data,
    required this.sections,
    required this.partial,
    required this.totalMs,
  });

  Map<String, dynamic> toJson() => {
        'data': data,
        'meta': {
          'sections': sections.map((k, v) => MapEntry(k, v.toJson())),
          'partial': partial,
          'total_ms': totalMs,
        },
      };
}

/// Executes a [tree] for the requested [requestedSections].
///
/// - When [requestedSections] is `null`, every section marked `required: true`
///   is run.
/// - Sections can declare dependencies on nodes from earlier sections via
///   [ViewNode.dependsOn]. Cross-section deps are resolved through the
///   shared results map.
/// - On a required-section error the error propagates. On an optional-section
///   error the section is recorded as `ERROR` and `partial` is set to `true`.
Future<ViewExecutionResult> executeTree(
  ViewTree tree,
  List<String>? requestedSections,
  Map<String, dynamic> context,
) async {
  final startTotal = DateTime.now();
  final data = <String, Map<String, dynamic>>{};
  final sectionsMeta = <String, SectionMeta>{};
  var partial = false;

  final allSections = tree.sections.keys.toList();
  final sectionsToRun = (requestedSections == null || requestedSections.isEmpty)
      ? allSections
          .where((s) => tree.sections[s]?.required ?? true)
          .toList()
      : requestedSections.where((s) => allSections.contains(s)).toList();

  if (requestedSections != null &&
      sectionsToRun.length < requestedSections.length) {
    partial = true;
  }

  // Shared state ACROSS sections — allows cross-section dependencies.
  final sharedResults = <String, dynamic>{};
  final sharedExecuted = <String>{};

  for (final sectionName in sectionsToRun) {
    final section = tree.sections[sectionName]!;
    final startSection = DateTime.now();
    try {
      final sectionResult = await _executeSection(
        section,
        context,
        sharedResults,
        sharedExecuted,
      );
      data[sectionName] = sectionResult.data;
      sectionsMeta[sectionName] = SectionMeta(
        ms: DateTime.now().difference(startSection).inMilliseconds,
        cacheStatus: sectionResult.cacheStatus,
      );
    } catch (e) {
      if (section.required) rethrow;
      sectionsMeta[sectionName] = SectionMeta(
        ms: DateTime.now().difference(startSection).inMilliseconds,
        cacheStatus: 'ERROR',
        error: e.toString(),
      );
      partial = true;
    }
  }

  return ViewExecutionResult(
    data: data,
    sections: sectionsMeta,
    partial: partial,
    totalMs: DateTime.now().difference(startTotal).inMilliseconds,
  );
}

class _SectionResult {
  final Map<String, dynamic> data;
  final String cacheStatus;
  const _SectionResult({required this.data, required this.cacheStatus});
}

Future<_SectionResult> _executeSection(
  ViewSection section,
  Map<String, dynamic> context,
  Map<String, dynamic> sharedResults,
  Set<String> sharedExecuted,
) async {
  final cacheNs = section.cacheNamespace;
  final cacheVer = section.cacheVersion;
  final cacheTtl = section.cacheTtlSec;

  // Try section-level cache.
  if (cacheTtl > 0) {
    final cacheKey = jsonEncode({
      'section': cacheNs,
      'context': _serializeContext(context, section.cacheContextKeys),
    });
    final cached = globalCache.get('view_section', cacheKey, cacheVer);
    if (cached != null) {
      final cachedMap = cached as Map<String, dynamic>;
      for (final node in section.nodes) {
        sharedExecuted.add(node.id);
        sharedResults[node.id] = cachedMap[node.id];
      }
      return _SectionResult(data: cachedMap, cacheStatus: 'HIT');
    }
  }

  final results = <String, dynamic>{};
  final remaining = List<ViewNode>.from(section.nodes);
  var iterations = 0;
  while (remaining.isNotEmpty && iterations < 50) {
    iterations++;
    final readyNow = remaining
        .where((n) => n.dependsOn.every((d) => sharedExecuted.contains(d)))
        .toList();
    if (readyNow.isEmpty) {
      throw StateError(
          'Cyclic or unresolvable dependency in section nodes: ${remaining.map((n) => n.id).join(', ')}');
    }
    await Future.wait(readyNow.map((node) async {
      final nodeContext = Map<String, dynamic>.from(context);
      nodeContext['deps'] = _pickKeys(sharedResults, node.dependsOn);
      dynamic val;
      if (node.cache != null && node.cache!.ttlSec > 0) {
        final cacheKey = jsonEncode({
          'node': node.id,
          'ctx': _serializeContext(nodeContext, node.cache!.contextKeys),
        });
        val = globalCache.get('view_node', cacheKey, cacheVer);
        if (val == null) {
          val = await node.useCase(nodeContext);
          globalCache.set('view_node', cacheKey, val,
              ttlSec: node.cache!.ttlSec, version: cacheVer);
        }
      } else {
        val = await node.useCase(nodeContext);
      }
      results[node.id] = val;
      sharedResults[node.id] = val;
      sharedExecuted.add(node.id);
    }));
    for (final n in readyNow) {
      remaining.remove(n);
    }
  }

  if (cacheTtl > 0) {
    final cacheKey = jsonEncode({
      'section': cacheNs,
      'context': _serializeContext(context, section.cacheContextKeys),
    });
    globalCache.set('view_section', cacheKey, results,
        ttlSec: cacheTtl, version: cacheVer);
  }

  return _SectionResult(data: results, cacheStatus: 'MISS');
}

Map<String, dynamic> _pickKeys(Map<String, dynamic> src, List<String> keys) {
  final out = <String, dynamic>{};
  for (final k in keys) {
    if (src.containsKey(k)) out[k] = src[k];
  }
  return out;
}

Map<String, dynamic>? _serializeContext(
    Map<String, dynamic> ctx, List<String> keys) {
  if (keys.isEmpty) return null;
  final out = <String, dynamic>{};
  for (final k in keys) {
    final v = ctx[k];
    if (v == null) continue;
    if (v is String || v is num || v is bool) {
      out[k] = v;
    } else if (v is Map && v['id'] != null) {
      out[k] = v['id'].toString();
    }
  }
  return out;
}
