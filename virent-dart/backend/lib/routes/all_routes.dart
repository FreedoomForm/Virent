import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart' show sha256;

// ═══════════════════════════════════════════════════════════════════════════
// Virent Standalone Backend — Full API (production parity with embedded server)
// ═══════════════════════════════════════════════════════════════════════════
//
// Same API surface as mobile/lib/core/backend/embedded_server.dart.
// Swap the embedded server for this standalone binary when deploying to a VPS.

/// In-memory data store with seed data (swap for Postgres in production).
class DataService {
  // ── Scooters ─────────────────────────────────────────────────────────
  static final _scooters = [
    {'id':'s1','name':'Virent#1','mac_address':'AA:BB:CC:00:00:01','lat':41.3111,'lng':69.2406,'battery':92,'status':'available','rate_per_min':1200,'last_seen':null},
    {'id':'s2','name':'Virent#2','mac_address':'AA:BB:CC:00:00:02','lat':41.3120,'lng':69.2410,'battery':78,'status':'available','rate_per_min':1200,'last_seen':null},
    {'id':'s3','name':'Virent#3','mac_address':'AA:BB:CC:00:00:03','lat':41.3100,'lng':69.2390,'battery':45,'status':'low_battery','rate_per_min':1200,'last_seen':null},
    {'id':'s4','name':'Virent#4','mac_address':'AA:BB:CC:00:00:04','lat':41.3130,'lng':69.2420,'battery':88,'status':'available','rate_per_min':1200,'last_seen':null},
    {'id':'s5','name':'Virent#5','mac_address':'AA:BB:CC:00:00:05','lat':41.3090,'lng':69.2380,'battery':100,'status':'available','rate_per_min':1200,'last_seen':null},
  ];

  // ── Users, Trips, Auth ───────────────────────────────────────────────
  static final _users = <String, Map<String, dynamic>>{};
  static final _trips = <String, Map<String, dynamic>>{};
  static final _otpCodes = <String, String>{};
  static final _transactions = <String, List<Map<String, dynamic>>>{};
  static final _blockedTokens = <String>{};
  static Map<String, dynamic>? currentUser;
  static Map<String, dynamic>? currentAdmin;

  // ── Admin accounts ───────────────────────────────────────────────────
  static final _admins = [
    {'id':'admin-1','email':'admin@virent.io','name':'Virent Super Admin','password':sha256.convert('Admin123!'.codeUnits).toString(),'role':'super_admin','permissions':['*'],'phone':'+998900000001','created_at':DateTime.now().toIso8601String(),'last_login_at':null},
  ];
  static final _adminTokens = <String, Map<String, dynamic>>{};

  // ── Zones, Prepaids, Notifications ───────────────────────────────────
  static final _zones = [
    {'id':'z1','name':'Amir Parking','type':'parking','speed_limit':0,'vertices':4,'color':'#16A34A','created_at':DateTime.now().toIso8601String()},
    {'id':'z2','name':'Old Town - No Ride','type':'no_ride','speed_limit':0,'vertices':4,'color':'#DC2626','created_at':DateTime.now().toIso8601String()},
    {'id':'z3','name':'School Zone','type':'slow','speed_limit':10,'vertices':4,'color':'#D97706','created_at':DateTime.now().toIso8601String()},
    {'id':'z4','name':'Charging Hub','type':'charging','speed_limit':0,'vertices':4,'color':'#3489FF','created_at':DateTime.now().toIso8601String()},
  ];
  static final _prepaids = <Map<String, dynamic>>[];
  static final _notifications = <Map<String, dynamic>>[];
  static final _promoCodes = <Map<String, dynamic>>[];
  static final _bonuses = <Map<String, dynamic>>[];

  // ── IoT ──────────────────────────────────────────────────────────────
  static final _iotCommands = <String, Map<String, dynamic>>{};
  static final _telemetryLog = <String, List<Map<String, dynamic>>>{};
  static const _validCommands = ['lock','unlock','alarm_on','alarm_off','led_on','led_off','update_firmware','reboot','locate'];

  // ── Support, Audit ───────────────────────────────────────────────────
  static final _supportTickets = <String, Map<String, dynamic>>{};
  static final _auditLog = <Map<String, dynamic>>[];

  // ── Convenience getters ──────────────────────────────────────────────
  static List<Map<String, dynamic>> get scooters => _scooters;
  static List<Map<String, dynamic>> get zones => _zones;
  static List<Map<String, dynamic>> get admins => _admins;
  static Map<String, Map<String, dynamic>> get adminTokens => _adminTokens;
  static Map<String, Map<String, dynamic>> get iotCommands => _iotCommands;

  static void audit(String action, String entity, String entityId, {String? actor, Map<String,dynamic>? details}) {
    _auditLog.add({'action':action,'entity':entity,'entity_id':entityId,'actor':actor ?? 'system','details':details,'timestamp':DateTime.now().toIso8601String()});
  }
}

// ═══════════════════════════════════════════════════════════════════════════

Response j(Map<String, dynamic> data, {int s = 200}) =>
    Response(s, body: jsonEncode(data), headers: {'Content-Type':'application/json'});
Response e(String msg, {int s = 400}) =>
    Response(s, body: jsonEncode({'error':msg}), headers: {'Content-Type':'application/json'});
Future<Map<String,dynamic>> body(Request req) async => jsonDecode(await req.readAsString()) as Map<String,dynamic>;

// ── Admin helpers ─────────────────────────────────────────────────────────
bool _isAdmin(Request req) {
  final auth = req.headers['Authorization'] ?? '';
  final token = auth.replaceFirst('Bearer ', '');
  if (DataService.adminTokens.containsKey(token)) return true;
  return DataService.currentAdmin != null;
}
Map<String,dynamic>? _adminByPhone(String phone) {
  try { return DataService.admins.firstWhere((a) => a['phone'] == phone); }
  catch (_) { return null; }
}
Map<String,dynamic> _publicAdmin(Map<String,dynamic> a) {
  final copy = Map<String,dynamic>.from(a);
  copy.remove('password');
  return copy;
}

// ═══════════════════════════════════════════════════════════════════════════

class AuthRouter {
  Router get router {
    final r = Router();

    r.post('/phone/send-code', (req) async {
      final b = body(await req.readAsString());
      final phone = b['phone'] as String?;
      if (phone == null || phone.isEmpty) return e('phone required');

      // Admin auto-login
      final admin = _adminByPhone(phone);
      if (admin != null) {
        admin['last_login_at'] = DateTime.now().toIso8601String();
        final user = DataService._users.putIfAbsent(phone, () => {
          'id':'u${DataService._users.length+1}','phone':phone,'name':admin['name']??'Admin','balance':0,'trips_count':0,'status':'active_user','role':admin['role'],'email':admin['email'],'created_at':DateTime.now().toIso8601String(),
        });
        user['role'] = admin['role'];
        user['email'] = admin['email'];
        DataService.currentUser = user;
        DataService.currentAdmin = admin;
        final token = 'admin_${DateTime.now().millisecondsSinceEpoch}';
        DataService._adminTokens[token] = admin;
        print('[AUTH] Admin auto-login $phone');
        return j({'success':true,'message':'Admin auto-verified','auto_verified':true,'token':token,'user':user,'is_admin':true,'admin':_publicAdmin(admin),'admin_token':token});
      }

      final code = (100000 + Random().nextInt(900000)).toString();
      DataService._otpCodes[phone] = code;
      print('[OTP] $phone: $code');
      return j({'success':true,'message':'OTP sent','verification_id':'vid_${DateTime.now().millisecondsSinceEpoch}'});
    });

    r.post('/phone/verify', (req) async {
      final b = body(await req.readAsString());
      final phone = b['phone'] as String?;
      final code = b['code'] as String?;
      if (DataService._otpCodes[phone] != code) return e('Invalid OTP', s:401);
      DataService._otpCodes.remove(phone);
      final user = DataService._users.putIfAbsent(phone, () => {
        'id':'u${DataService._users.length+1}','phone':phone,'name':'User ${phone!.substring(phone.length-4)}','balance':50000,'trips_count':0,'status':'active_user','created_at':DateTime.now().toIso8601String(),
      });
      DataService.currentUser = user;
      final token = 'virent_${DateTime.now().millisecondsSinceEpoch}';

      final admin = _adminByPhone(phone!);
      if (admin != null) {
        admin['last_login_at'] = DateTime.now().toIso8601String();
        user['role'] = admin['role'];
        user['email'] = admin['email'];
        DataService.currentAdmin = admin;
        final at = 'admin_${DateTime.now().millisecondsSinceEpoch}';
        DataService._adminTokens[at] = admin;
        return j({'success':true,'token':token,'user':user,'is_admin':true,'admin':_publicAdmin(admin),'admin_token':at});
      }
      return j({'success':true,'token':token,'user':user,'is_admin':false});
    });

    r.post('/logout', (req) {
      DataService.currentUser = null;
      DataService.currentAdmin = null;
      return j({'success':true});
    });

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class ScootersRouter {
  Router get router {
    final r = Router();

    r.get('/nearby', (req) {
      final lat = double.tryParse(req.url.queryParameters['lat']??'') ?? 41.3111;
      final lng = double.tryParse(req.url.queryParameters['lng']??'') ?? 69.2406;
      final nearby = DataService.scooters.map((s) {
        final dist = sqrt(pow((s['lat']as double-lat)*111000,2)+pow((s['lng']as double-lng)*111000,2));
        return {...s, 'distance':dist.round()};
      }).toList()..sort((a,b)=>(a['distance']as int).compareTo(b['distance']as int));
      return j({'scooters':nearby});
    });

    r.get('/<id>', (req, String id) {
      try {
        final s = DataService.scooters.firstWhere((s)=>s['id']==id);
        return j({'scooter':s});
      } catch (_) { return e('Not found', s:404); }
    });

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class TripsRouter {
  Router get router {
    final r = Router();

    r.post('/start', (req) async {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      final b = body(await req.readAsString());
      try {
        final scooter = DataService.scooters.firstWhere((s)=>s['id']==b['scooter_id']);
        if (scooter['status'] != 'available') return e('Scooter unavailable');
        scooter['status'] = 'in_use';
        final trip = {'id':'t${DateTime.now().millisecondsSinceEpoch}','user_id':DataService.currentUser!['id'],'scooter_id':b['scooter_id'],'start_time':DateTime.now().toIso8601String(),'start_battery':scooter['battery'],'status':'active','cost':0};
        DataService._trips[trip['id']as String] = trip;
        DataService.audit('trip.start','trip',trip['id']as String,actor:DataService.currentUser!['phone']);
        return j({'success':true,'trip':trip});
      } catch (_) { return e('Scooter not found', s:404); }
    });

    r.post('/end', (req) async {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      final b = body(await req.readAsString());
      final trip = DataService._trips[b['trip_id']];
      if (trip == null || trip['status']!='active') return e('Active trip not found', s:404);
      trip['end_time'] = DateTime.now().toIso8601String();
      final dur = max(1, DateTime.parse(trip['end_time']).difference(DateTime.parse(trip['start_time'])).inMinutes);
      trip['duration_min'] = dur;
      trip['cost'] = dur * (trip['rate_per_min']??1200);
      trip['status'] = 'completed';
      try {
        final sc = DataService.scooters.firstWhere((s)=>s['id']==trip['scooter_id']);
        sc['status'] = 'available';
        sc['battery'] = max(0,(sc['battery']as int)-dur*2);
      } catch (_) {}
      DataService.audit('trip.end','trip',trip['id']as String,actor:DataService.currentUser!['phone']);
      return j({'success':true,'trip':trip});
    });

    r.get('/history', (req) {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      final userTrips = DataService._trips.values.where((t)=>t['user_id']==DataService.currentUser!['id']).toList()..sort((a,b)=>'${b['start_time']}'.compareTo('${a['start_time']}'));
      return j({'trips':userTrips});
    });

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class WalletRouter {
  Router get router {
    final r = Router();

    r.get('/', (req) {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      final u = DataService.currentUser!;
      return j({'balance':u['balance'],'currency':'UZS','transactions':DataService._transactions[u['id']]??[]});
    });

    r.post('/topup', (req) async {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      final b = body(await req.readAsString());
      final amount = (b['amount']as num?)?.toInt()??0;
      if (amount <= 0) return e('Invalid amount');
      DataService.currentUser!['balance'] = (DataService.currentUser!['balance']??0)+amount;
      DataService._transactions.putIfAbsent(DataService.currentUser!['id'],()=>[]).add({'type':'topup','amount':amount,'at':DateTime.now().toIso8601String()});
      return j({'success':true,'new_balance':DataService.currentUser!['balance']});
    });

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class UsersRouter {
  Router get router {
    final r = Router();

    r.get('/me', (req) {
      if (DataService.currentUser == null) return e('Not authenticated', s:401);
      return j({'user': DataService.currentUser});
    });

    return r;
  }
}

class AdminRouter {
  Router get router {
    final r = Router();

    // ── Auth ──────────────────────────────────────────────────────────
    r.post('/login', (req) async {
      final b = body(await req.readAsString());
      final email = (b['email']as String?)?.trim().toLowerCase();
      final pw = b['password'] as String?;
      final hash = sha256.convert((pw??'').codeUnits).toString();
      try {
        final a = DataService.admins.firstWhere((a)=>(a['email']as String).toLowerCase()==email);
        if (a['password']!=hash) return e('Invalid credentials', s:401);
        a['last_login_at'] = DateTime.now().toIso8601String();
        final token = 'admin_${DateTime.now().millisecondsSinceEpoch}';
        DataService._adminTokens[token] = a;
        DataService.currentAdmin = a;
        DataService.audit('admin.login','admin',a['id']as String,actor:a['email']as String);
        return j({'success':true,'token':token,'admin':_publicAdmin(a)});
      } catch (_) { return e('Invalid credentials', s:401); }
    });

    r.get('/list', (req) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      return j({'admins':DataService.admins.map(_publicAdmin).toList()});
    });

    r.post('/create', (req) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final admin = {'id':'admin-${DateTime.now().millisecondsSinceEpoch}','email':b['email'],'name':b['name'],'password':sha256.convert((b['password']as String).codeUnits).toString(),'role':b['role']??'admin','permissions':b['permissions']??[],'phone':b['phone'],'created_at':DateTime.now().toIso8601String(),'last_login_at':null};
      DataService._admins.add(admin);
      DataService.audit('admin.create','admin',admin['id']as String);
      return j({'success':true,'admin':_publicAdmin(admin)});
    });

    r.delete('/delete/<id>', (req, String id) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      DataService._admins.removeWhere((a)=>a['id']==id);
      return j({'success':true});
    });

    // ── Dashboard ─────────────────────────────────────────────────────
    r.get('/stats', (req) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      return j({
        'total':DataService.scooters.length,
        'online':DataService.scooters.where((s)=>s['status']=='available').length,
        'offline':DataService.scooters.where((s)=>s['status']!='available').length,
        'warehouse':DataService.scooters.where((s)=>s['status']=='maintenance').length,
        'service':DataService.scooters.where((s)=>s['status']=='charging_needed').length,
        'free':DataService.scooters.where((s)=>s['status']=='available').length,
        'reserved':DataService.scooters.where((s)=>s['status']=='reserved').length,
        'in_rent':DataService.scooters.where((s)=>s['status']=='in_use').length,
        'online_total':DataService.scooters.where((s)=>s['battery']>0).length,
        'offline_total':DataService.scooters.where((s)=>s['battery']==0).length,
        'users':DataService._users.length,
        'trips':DataService._trips.length,
        'revenue':DataService._trips.values.where((t)=>t['status']=='completed').fold<int>(0,(s,t)=>s+((t['cost']??0)as num).toInt()),
        'blocked_users':DataService._users.values.where((u)=>u['status']=='blocked').length,
      });
    });

    // ── Scooters management ───────────────────────────────────────────
    r.get('/scooters', (req) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      return j({'scooters':DataService.scooters,'total':DataService.scooters.length});
    });

    r.post('/scooters', (req) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final sc = {'id':'s${DataService.scooters.length+1}','name':b['name']??'Virent#${DataService.scooters.length+1}','mac_address':b['mac_address'],'lat':b['lat']??41.3111,'lng':b['lng']??69.2406,'battery':b['battery']??100,'status':'available','rate_per_min':1200,'last_seen':null};
      DataService._scooters.add(sc);
      return j({'success':true,'scooter':sc});
    });

    r.put('/scooters/<id>', (req, String id) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      try {
        final sc = DataService.scooters.firstWhere((s)=>s['id']==id);
        final b = body(await req.readAsString());
        if (b['name']!=null) sc['name']=b['name'];
        if (b['status']!=null) sc['status']=b['status'];
        if (b['battery']!=null) sc['battery']=b['battery'];
        if (b['lat']!=null) sc['lat']=b['lat'];
        if (b['lng']!=null) sc['lng']=b['lng'];
        return j({'success':true,'scooter':sc});
      } catch (_) { return e('Scooter not found', s:404); }
    });

    r.delete('/scooters/<id>', (req, String id) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      DataService._scooters.removeWhere((s)=>s['id']==id);
      return j({'success':true});
    });

    // ── Users management ──────────────────────────────────────────────
    r.get('/users', (req) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      return j({'users':DataService._users.values.toList(),'total':DataService._users.length});
    });

    r.post('/users/<id>/block', (req, String id) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final user = DataService._users.values.firstWhere((u)=>u['id']==id,orElse:()=><String,dynamic>{});
      if (user.isEmpty) return e('User not found', s:404);
      user['status']='blocked';
      user['blocked_reason']=b['reason']??'';
      user['blocked_at']=DateTime.now().toIso8601String();
      return j({'success':true});
    });

    r.post('/users/<id>/unblock', (req, String id) {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final user = DataService._users.values.firstWhere((u)=>u['id']==id,orElse:()=><String,dynamic>{});
      if (user.isEmpty) return e('User not found', s:404);
      user['status']='active_user';
      user.remove('blocked_reason');
      user.remove('blocked_at');
      return j({'success':true});
    });

    // ── Zones ─────────────────────────────────────────────────────────
    r.get('/zones', (req) => j({'zones':DataService.zones}));
    r.post('/zones', (req) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final zone = {'id':'z${DateTime.now().millisecondsSinceEpoch}','name':b['name'],'type':b['type']??'no_ride','speed_limit':b['speed_limit']??0,'vertices':(b['vertices']as List?)?.length??0,'color':b['color']??'#3489FF','created_at':DateTime.now().toIso8601String()};
      DataService._zones.add(zone);
      return j({'success':true,'zone':zone});
    });

    // ── Notifications ─────────────────────────────────────────────────
    r.post('/notifications/send', (req) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final n = {'id':'n${DateTime.now().millisecondsSinceEpoch}','title':b['title'],'body':b['body'],'segment':b['segment']??'all','sent_at':DateTime.now().toIso8601String()};
      DataService._notifications.add(n);
      return j({'success':true,'notification_id':n['id']});
    });

    r.get('/notifications/stats', (req) => j({'notifications':DataService._notifications.reversed.take(50).toList()}));

    // ── Prepaids ──────────────────────────────────────────────────────
    r.post('/prepaids/bulk', (req) async {
      if (!_isAdmin(req)) return e('Admin required', s:401);
      final b = body(await req.readAsString());
      final count = min((b['count']as num?)?.toInt()??0,1000);
      final amount = (b['amount']as num?)?.toDouble();
      if (count<1 || amount==null || amount<=0) return e('count and amount required');
      final codes = <String>[];
      for (var i=0;i<count;i++) {
        final code = 'VIRENT-${Random().nextInt(999999).toString().padLeft(6,'0')}';
        codes.add(code);
        DataService._prepaids.add({'code':code,'amount':amount,'currency':'UZS','status':'unused','created_at':DateTime.now().toIso8601String()});
      }
      return j({'success':true,'count':count,'codes':codes});
    });

    // ── Audit log ─────────────────────────────────────────────────────
    r.get('/audit-log', (req) => j({'audit_log':DataService._auditLog.reversed.take(100).toList()}));

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class IotRouter {
  Router get router {
    final r = Router();

    r.post('/telemetry', (req) async {
      final b = body(await req.readAsString());
      final mac = b['scooter_mac'] as String?;
      if (mac==null) return e('scooter_mac required');
      try {
        final sc = DataService.scooters.firstWhere((s)=>s['mac_address']==mac);
        sc['last_seen']=DateTime.now().toIso8601String();
        if (b['battery']!=null) sc['battery']=(b['battery']as num).toInt();
        if (b['coordinates']!=null) sc['coordinates']=b['coordinates'];
        final log = DataService._telemetryLog.putIfAbsent(sc['id']as String,()=>[]);
        log.add({'timestamp':DateTime.now().toIso8601String(),'battery':b['battery'],'speed':b['speed']});
        if (log.length>100) log.removeRange(0,log.length-100);
        return j({'success':true});
      } catch (_) { return e('Scooter not provisioned', s:404); }
    });

    r.post('/event', (req) async {
      final b = body(await req.readAsString());
      print('[IoT] Event ${b['event_type']} from ${b['scooter_mac']}');
      return j({'success':true});
    });

    r.get('/command', (req) {
      final mac = req.url.queryParameters['scooter_mac'];
      if (mac==null) return e('scooter_mac required');
      final pending = DataService.iotCommands.values.where((c)=>c['scooter_mac']==mac && c['status']=='pending').toList()..sort((a,b)=>'${a['created_at']}'.compareTo('${b['created_at']}'));
      for (final c in pending.take(5)) { c['status']='delivered'; c['delivered_at']=DateTime.now().toIso8601String(); }
      return j({'commands':pending.take(5).toList()});
    });

    r.post('/command/send', (req) async {
      final b = body(await req.readAsString());
      if (!DataService._validCommands.contains(b['command'])) return e('Invalid command');
      final id = 'cmd_${DateTime.now().millisecondsSinceEpoch}';
      DataService._iotCommands[id] = {'id':id,'scooter_mac':b['scooter_mac'],'command':b['command'],'params':b['params']??{},'status':'pending','created_at':DateTime.now().toIso8601String()};
      return j({'success':true,'command_id':id});
    });

    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class SmsRouter {
  Router get router {
    final r = Router();

    r.get('/pending', (req) {
      final pending = DataService._otpCodes.entries.map((e)=> {'phone':e.key,'code':e.value}).toList();
      return j({'pending':pending});
    });

    r.post('/sent', (req) async {
      final b = body(await req.readAsString());
      print('[SMS] Admin confirmed SMS sent to ${b['phone']}');
      return j({'success':true});
    });

    return r;
  }
}
