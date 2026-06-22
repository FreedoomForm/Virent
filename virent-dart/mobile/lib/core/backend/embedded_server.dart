// embedded_server.dart — Virent embedded backend
//
// Runs a shelf HTTP server inside the Flutter app process.
// This means:
//   - No separate backend binary to install or start
//   - The Windows desktop app IS the server
//   - Mobile apps on the same WiFi connect to <PC_IP>:8443
//   - The Flutter UI connects to localhost:8443
//
// Architecture:
//
//   +-------------------------------------+
//   |     Virent Desktop App (.exe)       |
//   |                                     |
//   |  +----------+    +--------------+   |
//   |  | Flutter  |    | Embedded     |   |
//   |  | UI       |--->| shelf Server |   |
//   |  | (admin)  |    | (port 8443)  |   |
//   |  +----------+    +------+-------+   |
//   |                         |           |
//   +-------------------------+-----------+
//                             |
//                   +---------+---------+
//                   |  WiFi / LAN       |
//                   +---------+---------+
//                             |
//               +-------------+-------------+
//               |             |             |
//          +----+----+   +----+---+   +-----+-----+
//          | Android |   | iOS    |   | Another   |
//          | app     |   | app    |   | device    |
//          +---------+   +--------+   +-----------+
//
// Endpoint surface (mirrors the old Node stack):
//   - Health:           GET  /health
//   - Auth:             POST /auth/phone/send-code, /auth/phone/verify
//   - Scooters:         GET  /scooters/nearby, /scooters/<id>, /admin/scooters
//   - Trips:            POST /trips/reserve|start|end|cancel
//                       GET  /trips/active, /trips/history, /trips
//                       POST /admin/trips/<id>/refund
//   - Users:            GET  /users/me
//                       POST /admin/users/<id>/block|unblock|adjust-balance
//   - Wallet:           GET  /wallet, /wallet/transactions
//                       POST /wallet/topup
//   - Admin:            GET  /admin/stats, /admin/audit-log, /admin/notifications/stats
//                       POST /admin/notifications/send, /admin/prepaids/bulk
//                       POST /admin/scooters/<id>/retire
//                       GET  /admin/scooters/<id>/telemetry, /admin/scooters/<id>/commands
//   - Admin Auth:       POST /admin/login (email + password -> JWT + admin record)
//                       POST /admin/create (super_admin creates new admin)
//                       GET  /admin/list (list every admin)
//                       DELETE /admin/delete/<id> (super_admin deletes admin)
//                       PUT  /admin/permissions/<id> (super_admin edits perms)
//                       — When a phone-OTP verify matches an admin phone, the
//                         /auth/phone/verify response carries is_admin: true
//                         plus the admin record so the mobile app can route
//                         the user to /admin/home.
//   - SMS Gateway:      GET  /sms/pending, POST /sms/sent
//   - Zones:            GET  /zones, POST /zones, GET|PUT|DELETE /zones/<id>
//   - IoT (firmware):   POST /iot/telemetry, /iot/event
//                       GET  /iot/command?scooter_mac=...
//                       POST /iot/command/send (admin)
//   - Support:          POST /admin/support/<id>/close|reopen|assign

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../database/virent_database.dart';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

/// In-memory data store shared between the embedded server and the UI.
///
/// All collections are keyed / list-based and grow as the app is used.
/// A production deployment would swap this for MongoDB / Postgres; the
/// API surface stays identical.
class DataStore {
  /// Seed scooters around Tashkent city centre (Amir Temur Square).
  final List<Map<String, dynamic>> scooters = [
    {
      'id': 's1',
      'name': 'Virent#1',
      'mac_address': 'AA:BB:CC:00:00:01',
      'lat': 41.3111,
      'lng': 69.2406,
      'battery': 92,
      'status': 'available',
      'rate_per_min': 1200,
      'last_seen': null,
    },
    {
      'id': 's2',
      'name': 'Virent#2',
      'mac_address': 'AA:BB:CC:00:00:02',
      'lat': 41.3120,
      'lng': 69.2410,
      'battery': 78,
      'status': 'available',
      'rate_per_min': 1200,
      'last_seen': null,
    },
    {
      'id': 's3',
      'name': 'Virent#3',
      'mac_address': 'AA:BB:CC:00:00:03',
      'lat': 41.3100,
      'lng': 69.2390,
      'battery': 45,
      'status': 'low_battery',
      'rate_per_min': 1200,
      'last_seen': null,
    },
    {
      'id': 's4',
      'name': 'Virent#4',
      'mac_address': 'AA:BB:CC:00:00:04',
      'lat': 41.3130,
      'lng': 69.2420,
      'battery': 88,
      'status': 'available',
      'rate_per_min': 1200,
      'last_seen': null,
    },
    {
      'id': 's5',
      'name': 'Virent#5',
      'mac_address': 'AA:BB:CC:00:00:05',
      'lat': 41.3090,
      'lng': 69.2380,
      'battery': 100,
      'status': 'available',
      'rate_per_min': 1200,
      'last_seen': null,
    },
  ];

  /// All registered users keyed by phone number.
  final Map<String, Map<String, dynamic>> users = {};

  /// All trips keyed by trip id.
  final Map<String, Map<String, dynamic>> trips = {};

  /// Pending OTP codes keyed by phone number.
  final Map<String, String> otpCodes = {};

  /// Per-user transaction ledger keyed by user id.
  final Map<String, List<Map<String, dynamic>>> transactions = {};

  /// Geofence zones (parking / no-ride / slow / charging).
  final List<Map<String, dynamic>> zones = [
    {
      'id': 'z1',
      'name': 'Amir Parking',
      'type': 'parking',
      'speed_limit': 0,
      'vertices': 4,
      'color': '#16A34A',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'z2',
      'name': 'Old Town - No Ride',
      'type': 'no_ride',
      'speed_limit': 0,
      'vertices': 4,
      'color': '#DC2626',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'z3',
      'name': 'School Zone',
      'type': 'slow',
      'speed_limit': 10,
      'vertices': 4,
      'color': '#D97706',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'z4',
      'name': 'Charging Hub',
      'type': 'charging',
      'speed_limit': 0,
      'vertices': 4,
      'color': '#3489FF',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  /// Support tickets (admin-managed).
  final Map<String, Map<String, dynamic>> supportTickets = {};

  /// Prepaid top-up cards (admin bulk-generated).
  final List<Map<String, dynamic>> prepaids = [];

  /// Push notification history (admin-composed).
  final List<Map<String, dynamic>> notifications = [];

  /// Pending IoT commands keyed by command id.
  final Map<String, Map<String, dynamic>> iotCommands = {};

  /// Telemetry log per scooter (capped at 100 entries).
  final Map<String, List<Map<String, dynamic>>> telemetryLog = {};

  /// The currently authenticated user (single-session in embedded mode).
  Map<String, dynamic>? currentUser;

  /// The currently authenticated admin (set by `/admin/login` or by
  /// `/auth/phone/verify` when the verified phone belongs to an admin).
  /// Used by `_requireAdmin` as a fallback when no bearer token is supplied
  /// — this keeps the demo simple while still allowing multi-client admin
  /// auth via admin_token.
  Map<String, dynamic>? currentAdmin;

  /// Audit log entries (admin actions).
  final List<Map<String, dynamic>> auditLog = [];

  /// Admin accounts. Pre-seeded with a single super_admin so the dashboard
  /// is reachable immediately after first boot.
  ///
  /// Pre-seeded credentials (also documented in
  /// `lib/features/admin/data/models/admin_user_model.dart`):
  ///   email    : admin@virent.io
  ///   password : Admin123!
  ///   role     : super_admin
  ///   phone    : +998900000001  (allows OTP login through the regular flow)
  final List<Map<String, dynamic>> admins = [
    {
      'id': 'admin-1',
      'email': 'admin@virent.io',
      'name': 'Virent Super Admin',
      'password': 'Admin123!',
      'role': 'super_admin',
      'permissions': ['*'],
      'phone': '+998900000001',
      'created_at': DateTime.now().toIso8601String(),
      'last_login_at': null,
    },
  ];

  /// Issued admin JWT tokens keyed by token string. Used to authenticate
  /// `/admin/*` calls without coupling to the rider session.
  final Map<String, Map<String, dynamic>> adminTokens = {};

  // --- Derived helpers used by the dashboard ------------------------------

  /// Total number of scooters in the fleet.
  int get totalScooters => scooters.length;

  /// Number of scooters currently marked available.
  int get availableScooters =>
      scooters.where((s) => s['status'] == 'available').length;

  /// Number of registered users.
  int get totalUsers => users.length;

  /// Number of trips (any status) ever recorded.
  int get totalTrips => trips.length;

  /// Sum of all completed-trip revenue (UZS).
  int get revenueToday => trips.values
      .where((t) => t['status'] == 'completed')
      .fold<int>(0, (sum, t) => sum + ((t['cost'] ?? 0) as num).toInt());

  /// Serializes the entire store to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'scooters': scooters,
    'users': Map<String, dynamic>.from(users),
    'trips': Map<String, dynamic>.from(trips),
    'otpCodes': Map<String, dynamic>.from(otpCodes),
    'transactions': transactions.map((k, v) => MapEntry(k, v)),
    'zones': zones,
    'supportTickets': Map<String, dynamic>.from(supportTickets),
    'prepaids': prepaids,
    'notifications': notifications,
    'iotCommands': Map<String, dynamic>.from(iotCommands),
    'telemetryLog': telemetryLog.map((k, v) => MapEntry(k, List<Map>.from(v))),
    'admins': admins,
    'auditLog': auditLog,
    'adminTokens': Map<String, dynamic>.from(adminTokens),
    'version': 1,
  };

  /// Restores the store from a previously-saved JSON map.
  /// Returns the count of restored items for logging.
  int fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['scooters'] is List) {
      scooters.clear();
      for (final s in json['scooters']) { scooters.add(Map<String, dynamic>.from(s)); count++; }
    }
    if (json['users'] is Map) {
      users.clear();
      (json['users'] as Map).forEach((k, v) { users[k.toString()] = Map<String, dynamic>.from(v); count++; });
    }
    if (json['trips'] is Map) {
      trips.clear();
      (json['trips'] as Map).forEach((k, v) { trips[k.toString()] = Map<String, dynamic>.from(v); count++; });
    }
    if (json['otpCodes'] is Map) {
      otpCodes.clear();
      (json['otpCodes'] as Map).forEach((k, v) { otpCodes[k.toString()] = v.toString(); });
    }
    if (json['transactions'] is Map) {
      transactions.clear();
      (json['transactions'] as Map).forEach((k, v) {
        transactions[k.toString()] = (v as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
    if (json['zones'] is List) {
      zones.clear();
      for (final z in json['zones']) { zones.add(Map<String, dynamic>.from(z)); }
    }
    if (json['supportTickets'] is Map) {
      supportTickets.clear();
      (json['supportTickets'] as Map).forEach((k, v) { supportTickets[k.toString()] = Map<String, dynamic>.from(v); });
    }
    if (json['prepaids'] is List) {
      prepaids.clear();
      for (final p in json['prepaids']) { prepaids.add(Map<String, dynamic>.from(p)); }
    }
    if (json['notifications'] is List) {
      notifications.clear();
      for (final n in json['notifications']) { notifications.add(Map<String, dynamic>.from(n)); }
    }
    if (json['iotCommands'] is Map) {
      iotCommands.clear();
      (json['iotCommands'] as Map).forEach((k, v) { iotCommands[k.toString()] = Map<String, dynamic>.from(v); });
    }
    if (json['telemetryLog'] is Map) {
      telemetryLog.clear();
      (json['telemetryLog'] as Map).forEach((k, v) {
        telemetryLog[k.toString()] = (v as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
    if (json['admins'] is List) {
      admins.clear();
      for (final a in json['admins']) { admins.add(Map<String, dynamic>.from(a)); }
    }
    if (json['auditLog'] is List) {
      auditLog.clear();
      for (final e in json['auditLog']) { auditLog.add(Map<String, dynamic>.from(e)); }
    }
    if (json['adminTokens'] is Map) {
      adminTokens.clear();
      (json['adminTokens'] as Map).forEach((k, v) { adminTokens[k.toString()] = Map<String, dynamic>.from(v); });
    }
    return count;
  }

  /// Directory for Virent app data (database, logs).
  String get virentDir {
    // On desktop, use a fixed location; on mobile, use app support dir.
    if (Platform.isWindows) {
      return '${Platform.environment['APPDATA']}\\Virent';
    } else if (Platform.isLinux || Platform.isMacOS) {
      return '${Platform.environment['HOME']}/.virent';
    }
    return '';
  }

  /// Load all data from SQLite into in-memory maps.
  Future<void> loadFromDb() async {
    final db = VirentDatabase.db;

    // Scooters
    final scRows = await db.query('scooters');
    for (final row in scRows) {
      final s = Map<String, dynamic>.from(row);
      if (!scooters.any((x) => x['id'] == s['id'])) {
        scooters.add(s);
      }
    }

    // Users
    final uRows = await db.query('users');
    for (final row in uRows) {
      users[row['phone'] as String] = Map<String, dynamic>.from(row);
    }

    // Trips
    final tRows = await db.query('trips');
    for (final row in tRows) {
      trips[row['id'] as String] = Map<String, dynamic>.from(row);
    }

    // Zones
    final zRows = await db.query('zones');
    zones.clear();
    for (final row in zRows) {
      zones.add(Map<String, dynamic>.from(row));
    }

    // Admins
    final aRows = await db.query('admins');
    admins.clear();
    for (final row in aRows) {
      admins.add(Map<String, dynamic>.from(row));
    }

    // Prepaids
    final pRows = await db.query('prepaids');
    prepaids.clear();
    for (final row in pRows) {
      prepaids.add(Map<String, dynamic>.from(row));
    }

    // IoT commands
    final iRows = await db.query('iot_commands');
    iotCommands.clear();
    for (final row in iRows) {
      iotCommands[row['id'] as String] = Map<String, dynamic>.from(row);
    }

    // Transactions
    final txRows = await db.query('transactions');
    transactions.clear();
    for (final row in txRows) {
      final uid = row['user_id'] as String;
      transactions.putIfAbsent(uid, () => []).add(Map<String, dynamic>.from(row));
    }

    // Notifications
    final nRows = await db.query('notifications');
    notifications.clear();
    for (final row in nRows) {
      notifications.add(Map<String, dynamic>.from(row));
    }

    // Audit log
    final alRows = await db.query('audit_log', orderBy: 'timestamp DESC', limit: 500);
    auditLog.clear();
    for (final row in alRows) {
      auditLog.add(Map<String, dynamic>.from(row));
    }
  }

  /// Sync in-memory maps to SQLite (write-through).
  Future<void> syncToDb() async {
    final db = VirentDatabase.db;
    final batch = db.batch();

    // Scooters — delete all, re-insert
    batch.delete('scooters');
    for (final s in scooters) {
      batch.insert('scooters', Map<String, dynamic>.from(s)..remove('distance'),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Users
    for (final u in users.values) {
      batch.insert('users', Map<String, dynamic>.from(u),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Trips
    for (final t in trips.values) {
      batch.insert('trips', Map<String, dynamic>.from(t),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Zones
    batch.delete('zones');
    for (final z in zones) {
      batch.insert('zones', Map<String, dynamic>.from(z),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Admins
    batch.delete('admins');
    for (final a in admins) {
      final copy = Map<String, dynamic>.from(a);
      if (copy['permissions'] is List) {
        copy['permissions'] = jsonEncode(copy['permissions']);
      }
      batch.insert('admins', copy, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // OTP codes (transient — don't persist)

    await batch.commit(noResult: true);
  }
}

/// Embedded Virent backend server.
///
/// Call [start] on app launch and [stop] on app exit. On desktop platforms
/// the server runs on `0.0.0.0:8443` so other devices on the LAN can reach
/// it. On mobile platforms the server is not started; the mobile app acts
/// purely as a client and connects to the desktop PC's IP address.
class EmbeddedServer {
  /// Shared in-memory data store. Public so the desktop admin UI can read
  /// statistics without round-tripping through HTTP when both run in the
  /// same process.
  final DataStore data = DataStore();

  HttpServer? _server;

  /// Port the embedded server listens on. Defaults to 8443 to match the
  /// hard-coded default in [ApiClient].
  final int port;

  /// Optional log sink. Every informational / error line is forwarded here
  /// so the desktop UI can display a live server log panel.
  final void Function(String)? onLog;

  /// Creates an embedded server bound to [port].
  EmbeddedServer({this.port = 8443, this.onLog});

  /// Whether the server is currently accepting connections.
  bool get isRunning => _server != null;

  /// The localhost URL the Flutter UI should use to talk to the server.
  String get url => 'http://localhost:$port';

  void _log(String msg) => onLog?.call(msg);

  /// Appends an entry to the in-memory audit log.
  void _audit({
    required String action,
    required String entity,
    String? entityId,
    String actor = 'admin',
    Map<String, dynamic> details = const {},
  }) {
    data.auditLog.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'actor': actor,
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'details': details,
    });
    if (data.auditLog.length > 500) {
      data.auditLog.removeRange(500, data.auditLog.length);
    }
  }

  /// Starts the embedded HTTP server.
  ///
  /// Idempotent — calling [start] while already running is a no-op.
  /// On success the server is reachable at `http://0.0.0.0:[port]`.
  Future<void> start() async {
    if (_server != null) return;

    final router = Router();

    _registerHealth(router);
    _registerAuth(router);
    _registerScooters(router);
    _registerTrips(router);
    _registerUsers(router);
    _registerWallet(router);
    _registerAdmin(router);
    _registerAdminAuth(router);
    _registerSmsGateway(router);
    _registerZones(router);
    _registerIoT(router);
    _registerSupport(router);

    final handler = Pipeline()
        .addMiddleware(_loggingMiddleware)
        .addMiddleware(corsHeaders())
        .addHandler(router.call);

    _server = await shelf_io.serve(handler, '0.0.0.0', port);

    final localIp = await _findLocalIp();
    _log('=========================================================');
    _log('  Virent Embedded Backend');
    _log('  Listening on http://0.0.0.0:$port');
    _log('  Local:   http://localhost:$port');
    _log('  Network: http://$localIp:$port');
    _log('');
    _log('  For mobile apps on the same WiFi:');
    _log('    Set API URL to: http://$localIp:$port');
    _log('=========================================================');
  }

  /// Stops the embedded server and releases the bound port.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _log('Embedded server stopped');
  }

  // ---------------------------------------------------------------------
  // Middleware
  // ---------------------------------------------------------------------

  /// Logs every request line and forwards it to [onLog].
  Handler _loggingMiddleware(Handler innerHandler) {
    return (Request request) async {
      final started = DateTime.now();
      try {
        final response = await innerHandler(request);
        final ms = DateTime.now().difference(started).inMilliseconds;
        _log('${request.method} ${request.requestedUri.path} '
            '-> ${response.statusCode} (${ms}ms)');
        return response;
      } catch (e, st) {
        _log('[ERROR] ${request.method} ${request.requestedUri.path} '
            'threw: $e');
        _log(st.toString());
        return _err('Internal server error', status: 500);
      }
    };
  }

  // ---------------------------------------------------------------------
  // Route registration
  // ---------------------------------------------------------------------

  void _registerHealth(Router router) {
    router.get('/health', (_) => _json({
          'status': 'ok',
          'service': 'Virent Embedded Backend',
          'version': '1.0.0',
          'uptime': DateTime.now().toIso8601String(),
        }));
  }

  void _registerAuth(Router router) {
    // POST /auth/phone/send-code — send an OTP to the given phone number.
    //
    // ADMIN AUTO-LOGIN: if the phone belongs to a pre-seeded admin account,
    // the OTP is skipped entirely. The response carries `auto_verified: true`
    // plus the full auth payload (token, user, admin, admin_token) so the
    // client can persist the session and navigate straight to the admin
    // panel without showing the OTP entry screen.
    router.post('/auth/phone/send-code', (Request req) async {
      final body = await _body(req);
      final phone = body['phone'] as String?;
      if (phone == null || phone.isEmpty) return _err('phone required');

      // ---- Admin auto-login (skip OTP) ----
      final admin = _adminByPhone(phone);
      if (admin != null) {
        admin['last_login_at'] = DateTime.now().toIso8601String();
        final user = data.users.putIfAbsent(phone, () => {
              'id': 'u${data.users.length + 1}',
              'phone': phone,
              'name': admin['name'] ?? 'Admin',
              'balance': 0,
              'trips_count': 0,
              'status': 'active_user',
              'role': admin['role'],
              'email': admin['email'],
              'created_at': DateTime.now().toIso8601String(),
            });
        // Update existing user record with admin fields
        user['role'] = admin['role'];
        user['email'] = admin['email'];
        user['name'] = admin['name'];
        data.currentUser = user;
        data.currentAdmin = admin;
        final token = 'virent_${DateTime.now().millisecondsSinceEpoch}';
        final adminToken = 'admin_${DateTime.now().millisecondsSinceEpoch}';
        data.adminTokens[adminToken] = admin;
        _log('[AUTH] Admin auto-login $phone (${admin['role']})');
        return _json({
          'success': true,
          'message': 'Admin auto-verified',
          'auto_verified': true,
          'verification_id': 'vid_${DateTime.now().millisecondsSinceEpoch}',
          'token': token,
          'user': user,
          'is_admin': true,
          'admin': _publicAdmin(admin),
          'admin_token': adminToken,
        });
      }

      // ---- Regular OTP flow ----
      // Use cryptographically secure RNG for OTP codes.
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      data.otpCodes[phone] = code;
      _log('[OTP] $phone -> $code (forward to SMS gateway)');
      return _json({
        'success': true,
        'message': 'OTP sent',
        'verification_id': 'vid_${DateTime.now().millisecondsSinceEpoch}',
      });
    });

    // POST /auth/phone/verify — verify the OTP and create / restore the user.
    router.post('/auth/phone/verify', (Request req) async {
      final body = await _body(req);
      final phone = body['phone'] as String?;
      final code = body['code'] as String?;
      if (phone == null || code == null) {
        return _err('phone and code required');
      }
      if (data.otpCodes[phone] != code) {
        return _err('Invalid OTP', status: 401);
      }
      data.otpCodes.remove(phone);
      final user = data.users.putIfAbsent(phone, () => {
            'id': 'u${data.users.length + 1}',
            'phone': phone,
            'name': 'User ${phone.substring(phone.length - 4)}',
            'balance': 50000,
            'trips_count': 0,
            'status': 'active_user',
            'created_at': DateTime.now().toIso8601String(),
          });
      data.currentUser = user;
      final token = 'virent_${DateTime.now().millisecondsSinceEpoch}';
      _log('[AUTH] Verified $phone (user ${user['id']})');

      // If the verified phone belongs to an admin account, surface the admin
      // record + role so the mobile app can route the user to /admin/home.
      final admin = _adminByPhone(phone);
      if (admin != null) {
        admin['last_login_at'] = DateTime.now().toIso8601String();
        // Promote the rider record so the existing AuthUser.isAdmin getter
        // returns true — this lets the router redirect to /admin/home
        // without needing a separate admin session lookup.
        user['role'] = admin['role'];
        user['email'] = admin['email'];
        user['name'] = admin['name'];
        data.currentAdmin = admin;
        final adminToken =
            'admin_${DateTime.now().millisecondsSinceEpoch}';
        data.adminTokens[adminToken] = admin;
        return _json({
          'success': true,
          'token': token,
          'user': user,
          'is_admin': true,
          'admin': _publicAdmin(admin),
          'admin_token': adminToken,
          'message': 'Admin verified via OTP',
        });
      }

      return _json({
        'success': true,
        'token': token,
        'user': user,
        'is_admin': false,
      });
    });

    // POST /auth/logout — clears the current session.
    router.post('/auth/logout', (_) {
      data.currentUser = null;
      data.currentAdmin = null;
      return _json({'success': true});
    });
  }

  void _registerAdminAuth(Router router) {
    // POST /admin/login — email + password login for admin accounts.
    //
    // Returns a JWT-like token, the admin record (without password) and the
    // role. The token is registered in [DataStore.adminTokens] so subsequent
    // admin requests can be authenticated.
    router.post('/admin/login', (Request req) async {
      final body = await _body(req);
      final email = (body['email'] as String?)?.trim().toLowerCase();
      final password = body['password'] as String?;
      if (email == null || email.isEmpty || password == null) {
        return _err('email and password required');
      }
      final admin = data.admins.firstWhere(
        (a) => (a['email'] as String).toLowerCase() == email,
        orElse: () => <String, dynamic>{},
      );
      if (admin.isEmpty || admin['password'] != password) {
        return _err('Invalid admin credentials', status: 401);
      }
      admin['last_login_at'] = DateTime.now().toIso8601String();
      final token = 'admin_${DateTime.now().millisecondsSinceEpoch}';
      data.adminTokens[token] = admin;
      data.currentAdmin = admin;
      _audit(
        action: 'admin.login',
        entity: 'admin',
        entityId: admin['id'] as String,
        actor: admin['email'] as String,
      );
      _log('[ADMIN] Login ${admin['email']} (${admin['role']})');
      return _json({
        'success': true,
        'token': token,
        'admin': _publicAdmin(admin),
        'message': 'Login successful',
      });
    });

    // POST /admin/create — super_admin creates a new admin account.
    router.post('/admin/create', (Request req) async {
      final body = await _body(req);
      final actor = _requireAdmin(req);
      if (actor == null) return _err('Unauthorized', status: 401);
      if (actor['role'] != 'super_admin') {
        return _err('Only super_admin can create admins', status: 403);
      }
      final email = (body['email'] as String?)?.trim().toLowerCase();
      final name = (body['name'] as String?)?.trim();
      final password = body['password'] as String?;
      final roleStr = (body['role'] as String?) ?? 'operator';
      final phone = (body['phone'] as String?)?.trim();
      final permissions = (body['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      if (email == null ||
          email.isEmpty ||
          name == null ||
          name.isEmpty ||
          password == null ||
          password.isEmpty) {
        return _err('email, name and password are required');
      }
      if (!const {'super_admin', 'admin', 'operator'}.contains(roleStr)) {
        return _err('role must be one of: super_admin, admin, operator');
      }
      if (data.admins.any((a) =>
          (a['email'] as String).toLowerCase() == email)) {
        return _err('An admin with this email already exists', status: 409);
      }
      if (phone != null &&
          phone.isNotEmpty &&
          data.admins.any((a) => a['phone'] == phone)) {
        return _err('An admin with this phone already exists', status: 409);
      }
      final id = 'admin-${DateTime.now().millisecondsSinceEpoch}';
      final newAdmin = <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'password': password,
        'role': roleStr,
        'permissions': permissions,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': null,
      };
      data.admins.add(newAdmin);
      _audit(
        action: 'admin.create',
        entity: 'admin',
        entityId: id,
        actor: actor['email'] as String,
        details: {'email': email, 'role': roleStr, 'name': name},
      );
      _log('[ADMIN] Created admin $email ($roleStr)');
      return _json({
        'success': true,
        'admin': _publicAdmin(newAdmin),
      });
    });

    // GET /admin/list — list every admin account (passwords stripped).
    router.get('/admin/list', (Request req) {
      final actor = _requireAdmin(req);
      if (actor == null) return _err('Unauthorized', status: 401);
      if (actor['role'] != 'super_admin') {
        return _err('Only super_admin can list admins', status: 403);
      }
      return _json({
        'admins': data.admins.map(_publicAdmin).toList(),
        'count': data.admins.length,
      });
    });

    // DELETE /admin/delete/<id> — super_admin deletes an admin.
    router.delete('/admin/delete/<id>', (Request req, String id) {
      final actor = _requireAdmin(req);
      if (actor == null) return _err('Unauthorized', status: 401);
      if (actor['role'] != 'super_admin') {
        return _err('Only super_admin can delete admins', status: 403);
      }
      final idx = data.admins.indexWhere((a) => a['id'] == id);
      if (idx == -1) return _err('Admin not found', status: 404);
      if (data.admins[idx]['id'] == actor['id']) {
        return _err('Cannot delete your own account', status: 400);
      }
      final removed = data.admins.removeAt(idx);
      // Revoke any tokens held by this admin.
      data.adminTokens.removeWhere((_, v) => v['id'] == id);
      if (data.currentAdmin?['id'] == id) {
        data.currentAdmin = null;
      }
      _audit(
        action: 'admin.delete',
        entity: 'admin',
        entityId: id,
        actor: actor['email'] as String,
        details: {'email': removed['email']},
      );
      _log('[ADMIN] Deleted admin ${removed['email']}');
      return _json({'success': true});
    });

    // PUT /admin/permissions/<id> — super_admin replaces an admin's perms.
    router.put('/admin/permissions/<id>',
        (Request req, String id) async {
      final actor = _requireAdmin(req);
      if (actor == null) return _err('Unauthorized', status: 401);
      if (actor['role'] != 'super_admin') {
        return _err('Only super_admin can edit permissions', status: 403);
      }
      final body = await _body(req);
      final perms = (body['permissions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final admin = data.admins.firstWhere(
        (a) => a['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (admin.isEmpty) return _err('Admin not found', status: 404);
      admin['permissions'] = perms;
      _audit(
        action: 'admin.update_permissions',
        entity: 'admin',
        entityId: id,
        actor: actor['email'] as String,
        details: {'permissions': perms},
      );
      _log('[ADMIN] Updated permissions for ${admin['email']} -> $perms');
      return _json({
        'success': true,
        'admin': _publicAdmin(admin),
      });
    });
  }

  void _registerScooters(Router router) {
    // GET /scooters/nearby?lat&lng — list scooters sorted by distance.
    router.get('/scooters/nearby', (Request req) {
      final lat = double.tryParse(
              req.url.queryParameters['lat'] ?? '') ??
          41.3111;
      final lng = double.tryParse(
              req.url.queryParameters['lng'] ?? '') ??
          69.2406;
      final radiusStr = req.url.queryParameters['radius_m'];
      final radius = radiusStr == null
          ? null
          : double.tryParse(radiusStr);
      final nearby = data.scooters.where((s) {
        if (s['status'] == 'retired') return false;
        return true;
      }).map((s) {
        final dist = sqrt(
          pow(((s['lat'] as double) - lat) * 111000, 2) +
              pow(((s['lng'] as double) - lng) * 111000, 2),
        );
        return <String, dynamic>{
          ...s,
          'distance': dist.round(),
        };
      }).where((s) => radius == null || (s['distance'] as int) <= radius)
          .toList()
        ..sort((a, b) =>
            (a['distance'] as int).compareTo(b['distance'] as int));
      return _json({'scooters': nearby});
    });

    // GET /scooters/<id> — full scooter detail.
    router.get('/scooters/<id>', (Request req, String id) {
      final s = _scooterById(id);
      if (s == null) return _err('Scooter not found', status: 404);
      return _json({'scooter': s});
    });
  }

  void _registerTrips(Router router) {
    // POST /trips/reserve — reserve a scooter before unlocking it.
    router.post('/trips/reserve', (Request req) async {
      final body = await _body(req);
      final scooter = _scooterById(body['scooter_id'] as String?);
      if (scooter == null) return _err('Scooter not found', status: 404);
      if (scooter['status'] != 'available') {
        return _err('Scooter not available', status: 409);
      }
      scooter['status'] = 'reserved';
      return _json({'success': true, 'status': scooter['status']});
    });

    // POST /trips/start — begin an active trip.
    router.post('/trips/start', (Request req) async {
      final body = await _body(req);
      final scooter = _scooterById(body['scooter_id'] as String?);
      if (scooter == null) return _err('Scooter not found', status: 404);
      if (scooter['status'] != 'available' &&
          scooter['status'] != 'reserved') {
        return _err('Scooter not available', status: 409);
      }
      scooter['status'] = 'in_use';
      final tripId = 't${DateTime.now().millisecondsSinceEpoch}';
      final trip = <String, dynamic>{
        'id': tripId,
        'user_id': data.currentUser?['id'],
        'scooter_id': scooter['id'],
        'start_time': DateTime.now().toIso8601String(),
        'start_battery': scooter['battery'],
        'status': 'active',
        'cost': 0,
      };
      data.trips[tripId] = trip;
      _log('[TRIP] Started $tripId (scooter ${scooter['id']})');
      return _json({'success': true, 'trip': trip});
    });

    // POST /trips/end — end an active trip, compute cost and release the scooter.
    router.post('/trips/end', (Request req) async {
      final body = await _body(req);
      final tripId = body['trip_id'] as String?;
      if (tripId == null) return _err('trip_id required');
      final trip = data.trips[tripId];
      if (trip == null || trip['status'] != 'active') {
        return _err('Active trip not found', status: 404);
      }
      final end = DateTime.now();
      trip['end_time'] = end.toIso8601String();
      final dur = max(1, end.difference(DateTime.parse(trip['start_time'])).inMinutes);
      trip['duration_min'] = dur;
      final rate = (_scooterById(trip['scooter_id'] as String)?['rate_per_min']
              ?? 1200) as int;
      trip['cost'] = dur * rate;
      trip['status'] = 'completed';

      // Release the scooter and drain the battery.
      final sc = _scooterById(trip['scooter_id'] as String)!;
      sc['status'] = 'available';
      sc['battery'] = max(0, (sc['battery'] as int) - dur * 2);

      // Charge the user.
      if (data.currentUser != null) {
        data.currentUser!['balance'] =
            (data.currentUser!['balance'] as int) - (trip['cost'] as int);
        data.currentUser!['trips_count'] =
            (data.currentUser!['trips_count'] as int) + 1;
        _pushTransaction(
          data.currentUser!['id'] as String,
          type: 'trip_charge',
          amount: -(trip['cost'] as int),
          description: 'Trip $tripId (${dur}min)',
        );
      }
      _log('[TRIP] Ended $tripId cost=${trip['cost']} UZS (${dur}min)');
      return _json({'success': true, 'trip': trip});
    });

    // POST /trips/cancel — cancel an active trip without charge.
    router.post('/trips/cancel', (Request req) async {
      final body = await _body(req);
      final tripId = body['trip_id'] as String?;
      if (tripId == null) return _err('trip_id required');
      final trip = data.trips[tripId];
      if (trip == null) return _err('Trip not found', status: 404);
      trip['status'] = 'cancelled';
      trip['end_time'] = DateTime.now().toIso8601String();
      final sc = _scooterById(trip['scooter_id'] as String);
      if (sc != null) sc['status'] = 'available';
      _log('[TRIP] Cancelled $tripId');
      return _json({'success': true, 'trip': trip});
    });

    // GET /trips/active — the current user's active trip, if any.
    router.get('/trips/active', (_) {
      final userId = data.currentUser?['id'];
      if (userId == null) return _err('Not authenticated', status: 401);
      final active = data.trips.values.firstWhere(
        (t) => t['user_id'] == userId && t['status'] == 'active',
        orElse: () => <String, dynamic>{},
      );
      return _json({'trip': active});
    });

    // GET /trips/history — the current user's past trips.
    router.get('/trips/history', (Request req) {
      final userId = data.currentUser?['id'];
      if (userId == null) return _err('Not authenticated', status: 401);
      final limit = int.tryParse(
              req.url.queryParameters['limit'] ?? '') ??
          50;
      final history = data.trips.values
          .where((t) =>
              t['user_id'] == userId && t['status'] != 'active')
          .toList()
        ..sort((a, b) => (b['start_time'] as String)
            .compareTo(a['start_time'] as String));
      return _json({'trips': history.take(limit).toList()});
    });

    // GET /trips — admin: list every trip in the system.
    router.get('/trips', (Request req) {
      final limit = int.tryParse(
              req.url.queryParameters['limit'] ?? '') ??
          100;
      final status = req.url.queryParameters['status'];
      final all = data.trips.values.where((t) {
        if (status == null) return true;
        return t['status'] == status;
      }).toList()
        ..sort((a, b) => (b['start_time'] as String)
            .compareTo(a['start_time'] as String));
      return _json({'trips': all.take(limit).toList()});
    });
  }

  void _registerUsers(Router router) {
    // GET /users/me — current authenticated user profile.
    router.get('/users/me', (_) {
      if (data.currentUser == null) {
        return _err('Not authenticated', status: 401);
      }
      return _json({'user': data.currentUser});
    });

    // GET /users — admin: list all users.
    router.get('/users', (_) {
      return _json({'users': data.users.values.toList()});
    });

    // POST /admin/users/<id>/block — block a customer with a reason.
    router.post('/admin/users/<id>/block', (Request req, String id) async {
      final body = await _body(req);
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (reason.isEmpty) return _err('reason required');
      final user = _userById(id);
      if (user == null) return _err('User not found', status: 404);
      user['status'] = 'blocked';
      user['blocked_reason'] = reason;
      user['blocked_at'] = DateTime.now().toIso8601String();
      _audit(
        action: 'user.block',
        entity: 'user',
        entityId: id,
        details: {'reason': reason},
      );
      _log('[ADMIN] Blocked user $id: $reason');
      return _json({'success': true});
    });

    // POST /admin/users/<id>/unblock — restore a blocked customer.
    router.post('/admin/users/<id>/unblock', (Request req, String id) {
      final user = _userById(id);
      if (user == null) return _err('User not found', status: 404);
      user['status'] = 'active_user';
      user.remove('blocked_reason');
      user.remove('blocked_at');
      _audit(
        action: 'user.unblock',
        entity: 'user',
        entityId: id,
      );
      _log('[ADMIN] Unblocked user $id');
      return _json({'success': true});
    });

    // POST /admin/users/<id>/adjust-balance — credit / debit a wallet.
    router.post('/admin/users/<id>/adjust-balance',
        (Request req, String id) async {
      final body = await _body(req);
      final delta = (body['delta'] as num?)?.toDouble();
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (delta == null || reason.isEmpty) {
        return _err('delta (number) and reason required');
      }
      final user = _userById(id);
      if (user == null) return _err('User not found', status: 404);
      final newBalance = (user['balance'] as int) + delta.toInt();
      if (newBalance < 0) return _err('balance would be negative');
      user['balance'] = newBalance;
      _pushTransaction(id,
          type: 'admin_adjustment',
          amount: delta.toInt(),
          description: reason);
      _audit(
        action: 'user.adjust_balance',
        entity: 'user',
        entityId: id,
        details: {'delta': delta, 'reason': reason, 'new_balance': newBalance},
      );
      _log('[ADMIN] Adjusted $id by $delta -> $newBalance UZS');
      return _json({'success': true, 'new_balance': newBalance});
    });
  }

  void _registerWallet(Router router) {
    // GET /wallet — current user balance + transactions.
    router.get('/wallet', (_) {
      if (data.currentUser == null) {
        return _err('Not authenticated', status: 401);
      }
      return _json({
        'balance': data.currentUser!['balance'],
        'currency': 'UZS',
        'transactions':
            data.transactions[data.currentUser!['id']] ?? [],
      });
    });

    // GET /wallet/transactions — current user transactions only.
    router.get('/wallet/transactions', (_) {
      if (data.currentUser == null) {
        return _err('Not authenticated', status: 401);
      }
      return _json({
        'transactions':
            data.transactions[data.currentUser!['id']] ?? [],
      });
    });

    // POST /wallet/topup — add credit to the current user's wallet.
    router.post('/wallet/topup', (Request req) async {
      if (data.currentUser == null) {
        return _err('Not authenticated', status: 401);
      }
      final body = await _body(req);
      final amount = (body['amount'] as num?)?.toInt();
      if (amount == null || amount <= 0) return _err('Invalid amount');
      data.currentUser!['balance'] =
          (data.currentUser!['balance'] as int) + amount;
      _pushTransaction(
        data.currentUser!['id'] as String,
        type: 'topup',
        amount: amount,
        description: body['description'] as String? ?? 'Wallet top-up',
      );
      _log('[WALLET] Top-up +$amount UZS '
          '(new balance ${data.currentUser!['balance']})');
      return _json({'success': true, 'new_balance': data.currentUser!['balance']});
    });
  }

  void _registerAdmin(Router router) {
    // GET /admin/stats — dashboard headline numbers.
    router.get('/admin/stats', (_) => _json({
          'total_scooters': data.totalScooters,
          'available_scooters': data.availableScooters,
          'total_users': data.totalUsers,
          'total_trips': data.totalTrips,
          'revenue': data.revenueToday,
          'active_trips': data.trips.values
              .where((t) => t['status'] == 'active')
              .length,
          'blocked_users': data.users.values
              .where((u) => u['status'] == 'blocked')
              .length,
        }));

    // GET /admin/scooters — every scooter in the fleet (incl. retired).
    router.get('/admin/scooters', (_) => _json({'scooters': data.scooters}));

    // GET /admin/audit-log?actor&action&entity&from&to&limit — filtered audit trail.
    router.get('/admin/audit-log', (Request req) {
      final qp = req.url.queryParameters;
      final actor = qp['actor'];
      final action = qp['action'];
      final entity = qp['entity'];
      final from = qp['from'];
      final to = qp['to'];
      final limit = int.tryParse(qp['limit'] ?? '') ?? 100;
      var entries = data.auditLog.where((e) {
        if (actor != null &&
            !(e['actor'] as String).toLowerCase().contains(actor.toLowerCase())) {
          return false;
        }
        if (action != null && e['action'] != action) return false;
        if (entity != null && e['entity'] != entity) return false;
        if (from != null) {
          if (DateTime.tryParse(e['timestamp'] as String) == null) return false;
          if (DateTime.parse(e['timestamp'] as String)
              .isBefore(DateTime.parse(from))) return false;
        }
        if (to != null) {
          if (DateTime.tryParse(e['timestamp'] as String) == null) return false;
          if (DateTime.parse(e['timestamp'] as String)
              .isAfter(DateTime.parse(to))) return false;
        }
        return true;
      }).toList();
      entries = entries.take(limit).toList();
      return _json({
        'entries': entries,
        'count': entries.length,
      });
    });

    // POST /admin/notifications/send — compose + dispatch a push notification.
    router.post('/admin/notifications/send', (Request req) async {
      final body = await _body(req);
      final title = (body['title'] as String?)?.trim() ?? '';
      final notifBody = (body['body'] as String?)?.trim() ?? '';
      final segment = body['segment'] as String? ?? 'all';
      if (title.isEmpty || notifBody.isEmpty) {
        return _err('title and body required');
      }
      final targetCount = data.users.values.where((u) {
        switch (segment) {
          case 'active':
            return u['status'] == 'active_user';
          case 'blocked':
            return u['status'] == 'blocked';
          default:
            return true;
        }
      }).length;
      final id = 'n${DateTime.now().millisecondsSinceEpoch}';
      data.notifications.insert(0, {
        'id': id,
        'title': title,
        'body': notifBody,
        'segment': segment,
        'status': 'sent',
        'target_count': targetCount,
        'delivered_count': 0,
        'read_count': 0,
        'sent_at': DateTime.now().toIso8601String(),
      });
      _audit(
        action: 'notification.send',
        entity: 'notification',
        entityId: id,
        details: {'title': title, 'segment': segment, 'target_count': targetCount},
      );
      _log('[ADMIN] Notification "$title" sent to $targetCount users');
      return _json({
        'success': true,
        'notification_id': id,
        'target_count': targetCount,
      });
    });

    // GET /admin/notifications/stats — recent notification history.
    router.get('/admin/notifications/stats', (_) =>
        _json({'notifications': data.notifications.take(50).toList()}));

    // POST /admin/prepaids/bulk — generate a batch of prepaid top-up codes.
    router.post('/admin/prepaids/bulk', (Request req) async {
      final body = await _body(req);
      final count = min((body['count'] as num?)?.toInt() ?? 0, 1000);
      final amount = (body['amount'] as num?)?.toDouble();
      final prefix =
          ((body['prefix'] as String?) ?? 'VIRENT').toUpperCase();
      final expiresInDays = (body['expires_in_days'] as num?)?.toInt() ?? 365;
      if (count < 1 || amount == null || amount <= 0) {
        return _err('count (1..1000) and amount (>0) required');
      }
      final expiresAt = DateTime.now()
          .add(Duration(days: expiresInDays))
          .toIso8601String();
      final codes = <String>[];
      for (var i = 0; i < count; i++) {
        final rand = _randomHex(12);
        final code = '$prefix-$rand';
        codes.add(code);
        data.prepaids.add({
          'code': code,
          'amount': amount,
          'currency': 'UZS',
          'status': 'unused',
          'used_by': null,
          'used_at': null,
          'expires_at': expiresAt,
          'batch': prefix,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      _audit(
        action: 'prepaid.bulk_create',
        entity: 'prepaid',
        entityId: prefix,
        details: {'count': count, 'amount': amount, 'prefix': prefix},
      );
      _log('[ADMIN] Generated $count prepaid cards ($prefix)');
      return _json({'success': true, 'count': count, 'codes': codes});
    });

    // POST /admin/scooters/<id>/retire — decommission a scooter.
    router.post('/admin/scooters/<id>/retire',
        (Request req, String id) async {
      final body = await _body(req);
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (reason.isEmpty) return _err('reason required');
      final sc = _scooterById(id);
      if (sc == null) return _err('Scooter not found', status: 404);
      sc['status'] = 'retired';
      sc['retired_at'] = DateTime.now().toIso8601String();
      sc['retired_reason'] = reason;
      _audit(
        action: 'scooter.retire',
        entity: 'scooter',
        entityId: id,
        details: {'reason': reason},
      );
      _log('[ADMIN] Retired scooter $id: $reason');
      return _json({'success': true});
    });

    // GET /admin/scooters/<id>/telemetry — recent telemetry log for a scooter.
    router.get('/admin/scooters/<id>/telemetry',
        (Request req, String id) {
      final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 100;
      final log = data.telemetryLog[id] ?? [];
      return _json({'data': log.reversed.take(limit).toList()});
    });

    // GET /admin/scooters/<id>/commands — command history for a scooter.
    router.get('/admin/scooters/<id>/commands',
        (Request req, String id) {
      final limit = int.tryParse(req.url.queryParameters['limit'] ?? '') ?? 50;
      final sc = _scooterById(id);
      if (sc == null) return _err('Scooter not found', status: 404);
      final mac = sc['mac_address'] as String?;
      final cmds = data.iotCommands.values
          .where((c) => c['scooter_mac'] == mac)
          .toList()
        ..sort((a, b) => (b['created_at'] as String)
            .compareTo(a['created_at'] as String));
      return _json({'data': cmds.take(limit).toList()});
    });

    // POST /admin/trips/<id>/refund — refund part of a completed trip.
    router.post('/admin/trips/<id>/refund', (Request req, String id) async {
      final body = await _body(req);
      final amount = (body['amount'] as num?)?.toDouble();
      final reason = (body['reason'] as String?)?.trim() ?? '';
      if (amount == null || amount <= 0 || reason.isEmpty) {
        return _err('amount (>0) and reason required');
      }
      final trip = data.trips[id];
      if (trip == null) return _err('Trip not found', status: 404);
      if (amount > (trip['cost'] as num)) {
        return _err('refund exceeds trip cost');
      }
      trip['refunded'] = true;
      trip['refund_amount'] = amount;
      trip['refund_reason'] = reason;
      trip['refunded_at'] = DateTime.now().toIso8601String();
      final userId = trip['user_id'] as String?;
      if (userId != null) {
        final user = _userById(userId);
        if (user != null) {
          user['balance'] = (user['balance'] as int) + amount.toInt();
        }
        _pushTransaction(userId,
            type: 'refund',
            amount: amount.toInt(),
            description: 'Refund for trip $id');
      }
      _audit(
        action: 'trip.refund',
        entity: 'trip',
        entityId: id,
        details: {'amount': amount, 'reason': reason},
      );
      _log('[ADMIN] Refunded trip $id: $amount UZS — $reason');
      return _json({'success': true});
    });
  }

  void _registerSmsGateway(Router router) {
    // GET /sms/pending — the admin phone polls this to fetch OTP requests.
    router.get('/sms/pending', (_) {
      final pending = data.otpCodes.entries
          .map((e) => {'phone': e.key, 'code': e.value})
          .toList();
      return _json({'pending': pending});
    });

    // POST /sms/sent — admin phone confirms an SMS was actually sent.
    router.post('/sms/sent', (Request req) async {
      final body = await _body(req);
      final phone = body['phone'] as String?;
      if (phone == null) return _err('phone required');
      // Keep the OTP code (verify still needs it) — just log the ack.
      _log('[SMS] Admin phone confirmed SMS sent to $phone');
      return _json({'success': true});
    });
  }

  void _registerZones(Router router) {
    // GET /zones — list every geofence zone.
    router.get('/zones', (_) => _json({'zones': data.zones}));

    // POST /zones — create a new zone.
    router.post('/zones', (Request req) async {
      final body = await _body(req);
      final name = body['name'] as String?;
      if (name == null || name.isEmpty) return _err('name required');
      final id = 'z${DateTime.now().millisecondsSinceEpoch}';
      final zone = {
        'id': id,
        'name': name,
        'type': body['type'] ?? 'no_ride',
        'speed_limit': body['speed_limit'] ?? 0,
        'vertices': (body['vertices'] as List?)?.length ?? 0,
        'color': body['color'] ?? '#3489FF',
        'polygon': body['vertices'],
        'created_at': DateTime.now().toIso8601String(),
      };
      data.zones.add(zone);
      _audit(
        action: 'zone.create',
        entity: 'zone',
        entityId: id,
        details: {'name': name, 'type': zone['type']},
      );
      _log('[ZONE] Created $id ($name)');
      return _json({'success': true, 'zone': zone});
    });

    // GET /zones/<id> — single zone detail.
    router.get('/zones/<id>', (Request req, String id) {
      final z = data.zones.where((z) => z['id'] == id).firstOrNull;
      if (z == null) return _err('Zone not found', status: 404);
      return _json({'zone': z});
    });

    // PUT /zones/<id> — replace an existing zone.
    router.put('/zones/<id>', (Request req, String id) async {
      final z = data.zones.where((z) => z['id'] == id).firstOrNull;
      if (z == null) return _err('Zone not found', status: 404);
      final body = await _body(req);
      z['name'] = body['name'] ?? z['name'];
      z['type'] = body['type'] ?? z['type'];
      z['speed_limit'] = body['speed_limit'] ?? z['speed_limit'];
      z['color'] = body['color'] ?? z['color'];
      if (body['vertices'] is List) {
        z['polygon'] = body['vertices'];
        z['vertices'] = (body['vertices'] as List).length;
      }
      _audit(
        action: 'zone.update',
        entity: 'zone',
        entityId: id,
        details: {'name': z['name']},
      );
      return _json({'success': true, 'zone': z});
    });

    // DELETE /zones/<id> — remove a zone.
    router.delete('/zones/<id>', (Request req, String id) {
      final idx = data.zones.indexWhere((z) => z['id'] == id);
      if (idx == -1) return _err('Zone not found', status: 404);
      data.zones.removeAt(idx);
      _audit(action: 'zone.delete', entity: 'zone', entityId: id);
      return _json({'success': true});
    });
  }

  void _registerIoT(Router router) {
    const validCommands = [
      'lock',
      'unlock',
      'alarm_on',
      'alarm_off',
      'led_on',
      'led_off',
      'update_firmware',
      'reboot',
      'locate',
    ];

    // POST /iot/telemetry — scooter pushes GPS + battery + status.
    router.post('/iot/telemetry', (Request req) async {
      final body = await _body(req);
      final mac = body['scooter_mac'] as String?;
      if (mac == null) return _err('scooter_mac required');
      final sc = data.scooters
          .where((s) => (s['mac_address'] as String?) == mac)
          .firstOrNull;
      if (sc == null) return _err('Scooter not provisioned', status: 404);
      final coords = body['coordinates'];
      final battery = (body['battery'] as num?)?.toDouble();
      final speed = (body['speed'] as num?)?.toDouble() ?? 0;
      final newStatus = body['status'] as String?;
      final now = DateTime.now();
      sc['last_seen'] = now.toIso8601String();
      if (coords != null) sc['coordinates'] = coords;
      if (battery != null) {
        sc['battery'] = battery.toInt();
        if (battery < 20 && sc['status'] == 'available') {
          sc['status'] = 'charging_needed';
        }
      }
      if (newStatus != null &&
          {
            'available',
            'in_use',
            'charging_needed',
            'charging',
            'maintenance',
            'reserved'
          }.contains(newStatus)) {
        sc['status'] = newStatus;
      }
      final log = data.telemetryLog.putIfAbsent(
          sc['id'] as String, () => <Map<String, dynamic>>[]);
      log.add({
        'timestamp': now.toIso8601String(),
        'coordinates': coords,
        'battery': battery,
        'speed': speed,
      });
      if (log.length > 100) {
        log.removeRange(0, log.length - 100);
      }
      return _json({'success': true, 'message': 'Telemetry received'});
    });

    // POST /iot/event — scooter pushes an event (lock/unlock/alarm/fall/...).
    router.post('/iot/event', (Request req) async {
      final body = await _body(req);
      final mac = body['scooter_mac'] as String?;
      final eventType = body['event_type'] as String?;
      if (mac == null || eventType == null) {
        return _err('scooter_mac and event_type required');
      }
      final sc = data.scooters
          .where((s) => (s['mac_address'] as String?) == mac)
          .firstOrNull;
      if (sc == null) return _err('Scooter not found', status: 404);
      sc['last_seen'] = DateTime.now().toIso8601String();
      _log('[IoT] Event $eventType from $mac');
      return _json({'success': true, 'message': 'Event recorded'});
    });

    // GET /iot/command?scooter_mac=... — scooter polls for pending commands.
    router.get('/iot/command', (Request req) {
      final mac = req.url.queryParameters['scooter_mac'];
      if (mac == null) return _err('scooter_mac required');
      final pending = data.iotCommands.values
          .where((c) =>
              c['scooter_mac'] == mac && c['status'] == 'pending')
          .toList()
        ..sort((a, b) => (a['created_at'] as String)
            .compareTo(b['created_at'] as String));
      for (final c in pending.take(5)) {
        c['status'] = 'delivered';
        c['delivered_at'] = DateTime.now().toIso8601String();
      }
      return _json({'commands': pending.take(5).toList()});
    });

    // POST /iot/command/send — admin queues a command for a scooter.
    router.post('/iot/command/send', (Request req) async {
      final body = await _body(req);
      final mac = body['scooter_mac'] as String?;
      final command = body['command'] as String?;
      if (mac == null || command == null) {
        return _err('scooter_mac and command required');
      }
      if (!validCommands.contains(command)) {
        return _err('command must be one of: ${validCommands.join(', ')}');
      }
      final id = 'cmd_${DateTime.now().millisecondsSinceEpoch}';
      data.iotCommands[id] = {
        'id': id,
        'scooter_mac': mac,
        'command': command,
        'params': body['params'] ?? {},
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'delivered_at': null,
        'ack_at': null,
      };
      _log('[IoT] Queued $command for $mac');
      return _json({'success': true, 'command_id': id, 'message': 'Command queued'});
    });
  }

  void _registerSupport(Router router) {
    // POST /admin/support/<id>/close — resolve and close a ticket.
    router.post('/admin/support/<id>/close',
        (Request req, String id) async {
      final body = await _body(req);
      final ticket = data.supportTickets[id] ??= {
        'id': id,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };
      ticket['status'] = 'closed';
      ticket['resolution'] = body['resolution'] ?? '';
      ticket['closed_at'] = DateTime.now().toIso8601String();
      return _json({'success': true});
    });

    // POST /admin/support/<id>/reopen — reopen a closed ticket.
    router.post('/admin/support/<id>/reopen', (Request req, String id) {
      final ticket = data.supportTickets[id];
      if (ticket == null) return _err('Ticket not found', status: 404);
      ticket['status'] = 'open';
      ticket['reopened_at'] = DateTime.now().toIso8601String();
      ticket.remove('resolution');
      ticket.remove('closed_at');
      return _json({'success': true});
    });

    // POST /admin/support/<id>/assign — assign a ticket to a staff member.
    router.post('/admin/support/<id>/assign',
        (Request req, String id) async {
      final body = await _body(req);
      final assignee = (body['assignee'] as String?)?.trim() ?? '';
      if (assignee.isEmpty) return _err('assignee required');
      final ticket = data.supportTickets.putIfAbsent(
          id,
          () => {
                'id': id,
                'status': 'open',
                'created_at': DateTime.now().toIso8601String(),
              });
      ticket['assigned_to'] = assignee;
      ticket['assigned_at'] = DateTime.now().toIso8601String();
      return _json({'success': true});
    });
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Map<String, dynamic>? _scooterById(String? id) {
    if (id == null) return null;
    for (final s in data.scooters) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  /// Returns the admin whose phone matches [phone], or `null` when no admin
  /// has registered that phone. Used by `/auth/phone/verify` to detect admin
  /// logins through the regular OTP flow.
  Map<String, dynamic>? _adminByPhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    for (final a in data.admins) {
      if (a['phone'] == phone) return a;
    }
    return null;
  }

  /// Returns a public-safe copy of [admin] (without the password field).
  Map<String, dynamic> _publicAdmin(Map<String, dynamic> admin) {
    return {
      'id': admin['id'],
      'email': admin['email'],
      'name': admin['name'],
      'role': admin['role'],
      'permissions': admin['permissions'] ?? const <String>[],
      if (admin['phone'] != null) 'phone': admin['phone'],
      'createdAt': admin['created_at'] ?? admin['createdAt'],
      'lastLoginAt': admin['last_login_at'] ?? admin['lastLoginAt'],
    };
  }

  /// Resolves the admin account associated with the bearer token on [req].
  /// Returns `null` when the token is missing / invalid.
  ///
  /// Tokens are issued by `/admin/login` (and by `/auth/phone/verify` when
  /// the phone belongs to an admin) and stored in [DataStore.adminTokens].
  /// As a fallback, returns [DataStore.currentAdmin] when no token is
  /// supplied — this keeps the demo simple for single-user desktop usage.
  Map<String, dynamic>? _requireAdmin(Request req) {
    final auth = req.headers['authorization'];
    if (auth != null && auth.toLowerCase().startsWith('bearer ')) {
      final token = auth.substring(7).trim();
      final byToken = data.adminTokens[token];
      if (byToken != null) return byToken;
    }
    return data.currentAdmin;
  }

  Map<String, dynamic>? _userById(String? id) {
    if (id == null) return null;
    for (final u in data.users.values) {
      if (u['id'] == id) return u;
    }
    return data.currentUser?['id'] == id ? data.currentUser : null;
  }

  void _pushTransaction(
    String userId, {
    required String type,
    required int amount,
    required String description,
  }) {
    data.transactions.putIfAbsent(userId, () => []);
    data.transactions[userId]!.insert(0, {
      'id': 'tx${DateTime.now().millisecondsSinceEpoch}_${data.transactions[userId]!.length}',
      'type': type,
      'amount': amount,
      'currency': 'UZS',
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Reads and JSON-decodes the request body as a `Map<String, dynamic>`.
  /// Returns an empty map when the body is missing or invalid.
  Future<Map<String, dynamic>> _body(Request req) async {
    final raw = await req.readAsString();
    if (raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // fall through
    }
    return {};
  }

  /// Walks the IPv4 interfaces and returns the first non-loopback address
  /// (so the desktop UI can show mobile clients where to connect).
  Future<String> _findLocalIp() async {
    try {
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {
      // NetworkInterface.list can throw on some sandboxed runtimes.
    }
    return 'localhost';
  }

  /// Generates [length] hex characters of cryptographically strong randomness.
  String _randomHex(int length) {
    final rnd = Random.secure();
    final values = List<int>.generate(length ~/ 2, (_) => rnd.nextInt(256));
    return values.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  Response _json(Map<String, dynamic> data, {int status = 200}) =>
      Response(status,
          body: jsonEncode(data),
          headers: const {'Content-Type': 'application/json'});

  Response _err(String msg, {int status = 400}) => Response(status,
      body: jsonEncode({'error': msg}),
      headers: const {'Content-Type': 'application/json'});
}
