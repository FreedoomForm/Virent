/// System info and health-check models.
///
/// Ported from `backend/v1/models/system.js`. The backend exposes a
/// single `GET /system/info` endpoint that returns the app version,
/// process uptime, memory usage, disk usage, active connection count,
/// feature flags, and per-collection document counts.
///
/// This file ports that response shape as [SystemInfo] plus a few
/// derived value objects ([SystemMemory], [SystemProcess], [SystemFeatures]).
library;


import 'json_helpers.dart';
/// Top-level system info response returned by `GET /system/info`.
class SystemInfo {
  /// Application metadata (name, version, environment, uptime).
  final SystemApp app;

  /// Host OS metadata (hostname, platform, CPU count, total memory).
  final SystemHost system;

  /// Node.js process metadata (PID, heap usage, uptime).
  final SystemProcess process;

  /// Database metadata (URI with redacted credentials, per-collection
  /// document counts).
  final SystemDatabase database;

  /// Feature-flag set indicating which integrations are configured.
  final SystemFeatures features;

  /// When the snapshot was generated.
  final DateTime? generatedAt;

  const SystemInfo({
    required this.app,
    required this.system,
    required this.process,
    required this.database,
    required this.features,
    this.generatedAt,
  });

  /// Parses a JSON object into a [SystemInfo].
  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
        app: SystemApp.fromJson(
            (json['app'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        system: SystemHost.fromJson(
            (json['system'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        process: SystemProcess.fromJson(
            (json['process'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        database: SystemDatabase.fromJson(
            (json['database'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        features: SystemFeatures.fromJson(
            (json['features'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        generatedAt: parseDate(json['generated_at']),
      );

  /// `true` when the API is running in a development environment.
  bool get isDevelopment =>
      app.environment == 'development' || app.environment == 'dev';

  /// `true` when all critical integrations (SMS, payments) are configured.
  bool get isProductionReady =>
      !isDevelopment &&
      features.smsConfigured &&
      (features.clickConfigured || features.paymeConfigured);

  /// Convenience alias for [SystemProcess.uptimeSeconds] — the
  /// canonical "how long has the server been up?" answer.
  int get uptime => process.uptimeSeconds;

  /// Convenience alias for [SystemProcess.memory] — process memory
  /// usage breakdown.
  SystemMemory get memoryUsage => process.memory;

  /// Convenience alias for [SystemHost.diskUsage] — host disk usage.
  SystemDisk? get diskUsage => system.diskUsage;

  /// Convenience alias for [SystemProcess.activeConnections].
  int get activeConnections => process.activeConnections;

  Map<String, dynamic> toJson() => {
        'app': app.toJson(),
        'system': system.toJson(),
        'process': process.toJson(),
        'database': database.toJson(),
        'features': features.toJson(),
        if (generatedAt != null)
          'generated_at': generatedAt!.toIso8601String(),
      };

  @override
  String toString() =>
      'SystemInfo(${app.name} v${app.version}, env: ${app.environment}, uptime: ${app.uptimeHuman})';
}

/// Application metadata block.
class SystemApp {
  final String name;
  final String version;
  final String nodeVersion;
  final String environment;
  final DateTime? startedAt;
  final int uptimeSeconds;
  final String uptimeHuman;

  const SystemApp({
    required this.name,
    required this.version,
    required this.nodeVersion,
    required this.environment,
    required this.uptimeSeconds,
    required this.uptimeHuman,
    this.startedAt,
  });

  factory SystemApp.fromJson(Map<String, dynamic> json) => SystemApp(
        name: (json['name'] ?? '').toString(),
        version: (json['version'] ?? '0.0.0').toString(),
        nodeVersion: (json['node_version'] ?? '').toString(),
        environment: (json['environment'] ?? 'development').toString(),
        startedAt: parseDate(json['started_at']),
        uptimeSeconds: toInt(json['uptime_seconds'] ?? 0),
        uptimeHuman:
            (json['uptime_human'] ?? '0h 0m 0s').toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'node_version': nodeVersion,
        'environment': environment,
        if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
        'uptime_seconds': uptimeSeconds,
        'uptime_human': uptimeHuman,
      };

  @override
  String toString() => 'SystemApp($name v$version, $environment)';
}

/// Host OS metadata block.
class SystemHost {
  final String hostname;
  final String platform;
  final String arch;
  final int cpus;
  final int totalMemoryMb;
  final int freeMemoryMb;
  final List<double> loadAvg;
  final SystemDisk? diskUsage;

  const SystemHost({
    required this.hostname,
    required this.platform,
    required this.arch,
    required this.cpus,
    required this.totalMemoryMb,
    required this.freeMemoryMb,
    required this.loadAvg,
    this.diskUsage,
  });

  factory SystemHost.fromJson(Map<String, dynamic> json) {
    final rawLoad = json['load_avg'] ?? json['loadAvg'];
    return SystemHost(
      hostname: (json['hostname'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      arch: (json['arch'] ?? '').toString(),
      cpus: toInt(json['cpus']),
      totalMemoryMb: toInt(json['total_memory_mb'] ?? json['totalMemoryMb']),
      freeMemoryMb: toInt(json['free_memory_mb'] ?? json['freeMemoryMb']),
      loadAvg: rawLoad is List
          ? rawLoad
              .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0)
              .toList(growable: false)
          : const [],
      diskUsage: json['disk_usage'] is Map<String, dynamic>
          ? SystemDisk.fromJson(json['disk_usage'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Used memory in MB.
  int get usedMemoryMb => totalMemoryMb - freeMemoryMb;

  /// Memory utilisation ratio in `[0, 1]`.
  double get memoryUtilization =>
      totalMemoryMb == 0 ? 0 : usedMemoryMb / totalMemoryMb;

  /// `true` when the host is under heavy memory pressure (>90% used).
  bool get isMemoryStrained => memoryUtilization > 0.9;

  Map<String, dynamic> toJson() => {
        'hostname': hostname,
        'platform': platform,
        'arch': arch,
        'cpus': cpus,
        'total_memory_mb': totalMemoryMb,
        'free_memory_mb': freeMemoryMb,
        'load_avg': loadAvg,
        if (diskUsage != null) 'disk_usage': diskUsage!.toJson(),
      };

  @override
  String toString() =>
      'SystemHost($hostname, $platform $arch, ${cpus}cpus, ${usedMemoryMb}/${totalMemoryMb}MB)';
}

/// Disk-usage snapshot for the host's primary volume.
class SystemDisk {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  const SystemDisk({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  factory SystemDisk.fromJson(Map<String, dynamic> json) => SystemDisk(
        totalBytes: toInt(json['total_bytes'] ?? json['total']),
        usedBytes: toInt(json['used_bytes'] ?? json['used']),
        freeBytes: toInt(json['free_bytes'] ?? json['free']),
      );

  /// Disk utilisation ratio in `[0, 1]`.
  double get utilization =>
      totalBytes == 0 ? 0 : usedBytes / totalBytes;

  /// `true` when the disk is over 90% full.
  bool get isFull => utilization > 0.9;

  Map<String, dynamic> toJson() => {
        'total_bytes': totalBytes,
        'used_bytes': usedBytes,
        'free_bytes': freeBytes,
      };

  @override
  String toString() =>
      'SystemDisk(${usedBytes}/${totalBytes} bytes, ${(utilization * 100).toStringAsFixed(1)}%)';
}

/// Process memory breakdown (Node.js `process.memoryUsage()` shape).
class SystemMemory {
  /// Resident Set Size — total memory allocated for the process.
  final int rssMb;

  /// V8 heap currently in use.
  final int heapUsedMb;

  /// Total V8 heap allocated.
  final int heapTotalMb;

  /// C++ objects bound to V8 that are not counted in the heap.
  final int? externalMb;

  /// Array-buffers allocated.
  final int? arrayBuffersMb;

  const SystemMemory({
    required this.rssMb,
    required this.heapUsedMb,
    required this.heapTotalMb,
    this.externalMb,
    this.arrayBuffersMb,
  });

  factory SystemMemory.fromJson(Map<String, dynamic> json) => SystemMemory(
        rssMb: toInt(json['rss_mb'] ?? json['rss']),
        heapUsedMb: toInt(json['heap_used_mb'] ?? json['heapUsed']),
        heapTotalMb: toInt(json['heap_total_mb'] ?? json['heapTotal']),
        externalMb: json['external_mb'] == null
            ? null
            : toInt(json['external_mb']),
        arrayBuffersMb: json['array_buffers_mb'] == null
            ? null
            : toInt(json['array_buffers_mb']),
      );

  /// Heap utilisation ratio in `[0, 1]`.
  double get heapUtilization =>
      heapTotalMb == 0 ? 0 : heapUsedMb / heapTotalMb;

  /// `true` when the heap is over 85% full (V8 will GC aggressively).
  bool get isHeapStrained => heapUtilization > 0.85;

  Map<String, dynamic> toJson() => {
        'rss_mb': rssMb,
        'heap_used_mb': heapUsedMb,
        'heap_total_mb': heapTotalMb,
        if (externalMb != null) 'external_mb': externalMb,
        if (arrayBuffersMb != null) 'array_buffers_mb': arrayBuffersMb,
      };

  @override
  String toString() =>
      'SystemMemory(rss: ${rssMb}MB, heap: ${heapUsedMb}/${heapTotalMb}MB)';
}

/// Node.js process metadata block.
class SystemProcess {
  final int pid;
  final SystemMemory memory;
  final int uptimeSeconds;
  final int activeConnections;

  const SystemProcess({
    required this.pid,
    required this.memory,
    required this.uptimeSeconds,
    this.activeConnections = 0,
  });

  factory SystemProcess.fromJson(Map<String, dynamic> json) =>
      SystemProcess(
        pid: toInt(json['pid']),
        memory: SystemMemory.fromJson(
            (json['memory'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        uptimeSeconds: toInt(json['uptime_seconds'] ?? 0),
        activeConnections:
            toInt(json['active_connections'] ?? json['activeConnections']),
      );

  Map<String, dynamic> toJson() => {
        'pid': pid,
        'memory': memory.toJson(),
        'uptime_seconds': uptimeSeconds,
        'active_connections': activeConnections,
      };

  @override
  String toString() =>
      'SystemProcess(pid: $pid, uptime: ${uptimeSeconds}s, conns: $activeConnections)';
}

/// Database metadata block.
class SystemDatabase {
  /// Connection URI with credentials redacted.
  final String uri;

  /// Per-collection document counts. Values are integers, or the
  /// string `'error'` when the count query failed.
  final Map<String, Object> collections;

  const SystemDatabase({
    required this.uri,
    required this.collections,
  });

  factory SystemDatabase.fromJson(Map<String, dynamic> json) {
    final rawCollections = json['collections'] ?? const <String, dynamic>{};
    final collections = <String, Object>{};
    if (rawCollections is Map) {
      rawCollections.forEach((key, value) {
        if (value is int) {
          collections[key.toString()] = value;
        } else if (value is num) {
          collections[key.toString()] = value.toInt();
        } else {
          collections[key.toString()] = value?.toString() ?? 'error';
        }
      });
    }
    return SystemDatabase(
      uri: (json['uri'] ?? '').toString(),
      collections: collections,
    );
  }

  /// Total document count across all collections (ignores `'error'`s).
  int get totalDocuments => collections.values.fold<int>(
        0,
        (sum, v) => v is int ? sum + v : sum,
      );

  /// Number of collections that failed to report a count.
  int get errorCount =>
      collections.values.where((v) => v is! int).length;

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'collections': collections,
      };

  @override
  String toString() =>
      'SystemDatabase(${collections.length} collections, $totalDocuments docs)';
}

/// Feature-flag set indicating which integrations are configured.
class SystemFeatures {
  final String smsProvider;
  final bool smsConfigured;
  final bool clickConfigured;
  final bool paymeConfigured;
  final bool fcmConfigured;
  final bool apnsConfigured;
  final bool googleOauth;

  const SystemFeatures({
    required this.smsProvider,
    required this.smsConfigured,
    required this.clickConfigured,
    required this.paymeConfigured,
    required this.fcmConfigured,
    required this.apnsConfigured,
    required this.googleOauth,
  });

  factory SystemFeatures.fromJson(Map<String, dynamic> json) =>
      SystemFeatures(
        smsProvider: (json['sms_provider'] ?? 'console').toString(),
        smsConfigured: json['sms_provider'] != null &&
            json['sms_provider'] != 'console',
        clickConfigured: json['click_configured'] == true,
        paymeConfigured: json['payme_configured'] == true,
        fcmConfigured: json['fcm_configured'] == true,
        apnsConfigured: json['apns_configured'] == true,
        googleOauth: json['google_oauth'] == true,
      );

  /// `true` when at least one push provider is configured.
  bool get pushConfigured => fcmConfigured || apnsConfigured;

  Map<String, dynamic> toJson() => {
        'sms_provider': smsProvider,
        'sms_configured': smsConfigured,
        'click_configured': clickConfigured,
        'payme_configured': paymeConfigured,
        'fcm_configured': fcmConfigured,
        'apns_configured': apnsConfigured,
        'google_oauth': googleOauth,
      };

  @override
  String toString() =>
      'SystemFeatures(sms: $smsProvider, click: $clickConfigured, payme: $paymeConfigured)';
}

// --- internal helpers ----------------------------------------------------


