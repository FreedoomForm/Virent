// virent_database.dart — SQLite database for Virent (production-grade).
//
// Uses sqflite — the Flutter-native SQLite wrapper. No code generation,
// no ORM overhead. All tables have indexes on frequently-queried columns.
// WAL mode for concurrent reads during writes.
//
// Schema mirrors DataStore exactly — one table per collection.
// On first run: creates tables + inserts seed data (5 scooters, 1 admin).
// On subsequent runs: loads all data into memory for the embedded server.

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../utils/logger.dart';

/// SQLite database manager for Virent.
class VirentDatabase {
  static Database? _db;
  static bool _initialised = false;

  static Database get db {
    if (_db == null) throw StateError('Database not initialised. Call init() first.');
    return _db!;
  }

  /// Initialise the database — creates tables and seed data on first run.
  static Future<void> init(String dbPath) async {
    if (_initialised) return;

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );
    _initialised = true;
    AppLogger.info('SQLite database ready at $dbPath', tag: 'DB');
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ── Scooters ──────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE scooters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        mac_address TEXT UNIQUE,
        lat REAL DEFAULT 41.3111,
        lng REAL DEFAULT 69.2406,
        battery INTEGER DEFAULT 100,
        status TEXT DEFAULT 'available',
        rate_per_min INTEGER DEFAULT 1200,
        last_seen TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    batch.execute('CREATE INDEX idx_scooters_status ON scooters(status)');
    batch.execute('CREATE INDEX idx_scooters_mac ON scooters(mac_address)');

    // ── Users ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone TEXT UNIQUE NOT NULL,
        name TEXT,
        email TEXT,
        balance INTEGER DEFAULT 0,
        trips_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active_user',
        role TEXT DEFAULT 'rider',
        blocked_reason TEXT,
        blocked_at TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    batch.execute('CREATE INDEX idx_users_phone ON users(phone)');
    batch.execute('CREATE INDEX idx_users_status ON users(status)');

    // ── Trips ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        scooter_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_battery INTEGER,
        end_battery INTEGER,
        duration_min INTEGER,
        cost INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (scooter_id) REFERENCES scooters(id)
      )
    ''');
    batch.execute('CREATE INDEX idx_trips_user ON trips(user_id)');
    batch.execute('CREATE INDEX idx_trips_status ON trips(status)');

    // ── OTP codes ─────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE otp_codes (
        phone TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── Transactions ──────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
    batch.execute('CREATE INDEX idx_transactions_user ON transactions(user_id)');

    // ── Zones ─────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT DEFAULT 'no_ride',
        speed_limit INTEGER DEFAULT 0,
        vertices INTEGER DEFAULT 4,
        color TEXT DEFAULT '#3489FF',
        polygon TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── Admins ────────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE admins (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT DEFAULT 'admin',
        permissions TEXT DEFAULT '[]',
        phone TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        last_login_at TEXT
      )
    ''');

    // ── Admin tokens ──────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE admin_tokens (
        token TEXT PRIMARY KEY,
        admin_id TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (admin_id) REFERENCES admins(id)
      )
    ''');

    // ── Prepaids ──────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE prepaids (
        code TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'UZS',
        status TEXT DEFAULT 'unused',
        used_by TEXT,
        used_at TEXT,
        expires_at TEXT,
        batch TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── Notifications ─────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT,
        segment TEXT DEFAULT 'all',
        target_count INTEGER DEFAULT 0,
        sent_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── IoT commands ──────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE iot_commands (
        id TEXT PRIMARY KEY,
        scooter_mac TEXT NOT NULL,
        command TEXT NOT NULL,
        params TEXT DEFAULT '{}',
        status TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT (datetime('now')),
        delivered_at TEXT,
        ack_at TEXT
      )
    ''');
    batch.execute('CREATE INDEX idx_iot_cmds_mac ON iot_commands(scooter_mac)');
    batch.execute('CREATE INDEX idx_iot_cmds_status ON iot_commands(status)');

    // ── Telemetry log ─────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE telemetry_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scooter_id TEXT NOT NULL,
        lat REAL,
        lng REAL,
        battery INTEGER,
        speed REAL,
        status TEXT,
        timestamp TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (scooter_id) REFERENCES scooters(id)
      )
    ''');
    batch.execute('CREATE INDEX idx_telemetry_scooter ON telemetry_log(scooter_id)');
    batch.execute('CREATE INDEX idx_telemetry_ts ON telemetry_log(timestamp)');

    // ── Audit log ─────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE audit_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity TEXT NOT NULL,
        entity_id TEXT,
        actor TEXT,
        details TEXT,
        timestamp TEXT DEFAULT (datetime('now'))
      )
    ''');
    batch.execute('CREATE INDEX idx_audit_action ON audit_log(action)');
    batch.execute('CREATE INDEX idx_audit_ts ON audit_log(timestamp)');

    // ── Support tickets ───────────────────────────────────────────
    batch.execute('''
      CREATE TABLE support_tickets (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        subject TEXT NOT NULL,
        message TEXT,
        status TEXT DEFAULT 'open',
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // ── Promo codes ───────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE promo_codes (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        discount_percent INTEGER,
        discount_amount INTEGER,
        max_uses INTEGER,
        used_count INTEGER DEFAULT 0,
        expires_at TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── Bonuses ───────────────────────────────────────────────────
    batch.execute('''
      CREATE TABLE bonuses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        user_id TEXT,
        type TEXT DEFAULT 'signup',
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await batch.commit(noResult: true);

    // ── Seed data ────────────────────────────────────────────────────
    await _seedData(db);
  }

  /// Insert default scooters and admin account on first run.
  static Future<void> _seedData(Database db) async {
    // Seed scooters
    final scooters = [
      {'id':'s1','name':'Virent#1','mac_address':'AA:BB:CC:00:00:01','lat':41.3111,'lng':69.2406,'battery':92,'status':'available'},
      {'id':'s2','name':'Virent#2','mac_address':'AA:BB:CC:00:00:02','lat':41.3120,'lng':69.2410,'battery':78,'status':'available'},
      {'id':'s3','name':'Virent#3','mac_address':'AA:BB:CC:00:00:03','lat':41.3100,'lng':69.2390,'battery':45,'status':'low_battery'},
      {'id':'s4','name':'Virent#4','mac_address':'AA:BB:CC:00:00:04','lat':41.3130,'lng':69.2420,'battery':88,'status':'available'},
      {'id':'s5','name':'Virent#5','mac_address':'AA:BB:CC:00:00:05','lat':41.3090,'lng':69.2380,'battery':100,'status':'available'},
    ];
    for (final s in scooters) {
      await db.insert('scooters', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed zones
    final zones = [
      {'id':'z1','name':'Amir Parking','type':'parking','speed_limit':0,'vertices':4,'color':'#16A34A'},
      {'id':'z2','name':'Old Town - No Ride','type':'no_ride','speed_limit':0,'vertices':4,'color':'#DC2626'},
      {'id':'z3','name':'School Zone','type':'slow','speed_limit':10,'vertices':4,'color':'#D97706'},
      {'id':'z4','name':'Charging Hub','type':'charging','speed_limit':0,'vertices':4,'color':'#3489FF'},
    ];
    for (final z in zones) {
      await db.insert('zones', z, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed admin (password: Admin123!)
    await db.insert('admins', {
      'id': 'admin-1',
      'email': 'admin@virent.io',
      'name': 'Virent Super Admin',
      'password': 'Admin123!',
      'role': 'super_admin',
      'permissions': '["*"]',
      'phone': '+998900000001',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    AppLogger.info('Seed data inserted — 5 scooters, 4 zones, 1 admin', tag: 'DB');
  }

  // ── Close ──────────────────────────────────────────────────────────

  static Future<void> close() async {
    await _db?.close();
    _db = null;
    _initialised = false;
  }
}
