import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// In-memory data store (replace with mongo_dart in production).
class DataService {
  static final _scooters = [
    {'id': 's1', 'name': 'Virent#1', 'lat': 41.3111, 'lng': 69.2406, 'battery': 92, 'status': 'available', 'rate_per_min': 1200},
    {'id': 's2', 'name': 'Virent#2', 'lat': 41.3120, 'lng': 69.2410, 'battery': 78, 'status': 'available', 'rate_per_min': 1200},
    {'id': 's3', 'name': 'Virent#3', 'lat': 41.3100, 'lng': 69.2390, 'battery': 45, 'status': 'low_battery', 'rate_per_min': 1200},
    {'id': 's4', 'name': 'Virent#4', 'lat': 41.3130, 'lng': 69.2420, 'battery': 88, 'status': 'available', 'rate_per_min': 1200},
    {'id': 's5', 'name': 'Virent#5', 'lat': 41.3090, 'lng': 69.2380, 'battery': 100, 'status': 'available', 'rate_per_min': 1200},
  ];
  static final _users = <String, Map<String, dynamic>>{};
  static final _trips = <String, Map<String, dynamic>>{};
  static final _otpCodes = <String, String>{};
  static final _transactions = <String, List<Map<String, dynamic>>>{};
  static Map<String, dynamic>? currentUser;

  static List<Map<String, dynamic>> get scooters => _scooters;
}

Response _json(Map<String, dynamic> data, {int status = 200}) =>
    Response(status, body: jsonEncode(data), headers: {'Content-Type': 'application/json'});

Response _error(String message, {int status = 400}) =>
    Response(status, body: jsonEncode({'error': message}), headers: {'Content-Type': 'application/json'});

// ============ Auth ============
class AuthRouter {
  Router get router {
    final r = Router();
    r.post('/phone/send-code', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final phone = body['phone'];
      if (phone == null) return _error('phone required');
      final code = (100000 + Random().nextInt(900000)).toString();
      DataService._otpCodes[phone] = code;
      print('[OTP] $phone: $code');
      return _json({'success': true, 'message': 'OTP sent'});
    });
    r.post('/phone/verify', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final phone = body['phone'];
      final code = body['code'];
      if (DataService._otpCodes[phone] != code) return _error('Invalid OTP', status: 401);
      DataService._otpCodes.remove(phone);
      final user = DataService._users.putIfAbsent(phone, () => {
        'id': 'u${DataService._users.length + 1}', 'phone': phone, 'name': 'User ${phone.substring(phone.length - 4)}',
        'balance': 50000, 'trips_count': 0, 'created_at': DateTime.now().toIso8601String(),
      });
      DataService.currentUser = user;
      return _json({'success': true, 'token': 'virent_${DateTime.now().millisecondsSinceEpoch}', 'user': user});
    });
    return r;
  }
}

// ============ Scooters ============
class ScootersRouter {
  Router get router {
    final r = Router();
    r.get('/nearby', (Request req) {
      final lat = double.tryParse(req.url.queryParameters['lat'] ?? '') ?? 41.3111;
      final lng = double.tryParse(req.url.queryParameters['lng'] ?? '') ?? 69.2406;
      final nearby = DataService.scooters.map((s) {
        final dist = sqrt(pow((s['lat'] as double - lat) * 111000, 2) + pow((s['lng'] as double - lng) * 111000, 2));
        return {...s, 'distance': dist.round()};
      }).toList();
      return _json({'scooters': nearby});
    });
    r.get('/<id>', (Request req, String id) {
      final s = DataService.scooters.firstWhere((s) => s['id'] == id, orElse: () => {});
      if (s.isEmpty) return _error('Not found', status: 404);
      return _json({'scooter': s});
    });
    return r;
  }
}

// ============ Trips ============
class TripsRouter {
  Router get router {
    final r = Router();
    r.post('/start', (Request req) async {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      final body = jsonDecode(await req.readAsString());
      final scooter = DataService.scooters.firstWhere((s) => s['id'] == body['scooter_id'], orElse: () => {});
      if (scooter.isEmpty) return _error('Scooter not found', status: 404);
      scooter['status'] = 'in_use';
      final trip = {'id': 't${DateTime.now().millisecondsSinceEpoch}', 'user_id': DataService.currentUser!['id'],
        'scooter_id': body['scooter_id'], 'start_time': DateTime.now().toIso8601String(),
        'start_battery': scooter['battery'], 'status': 'active', 'cost': 0};
      DataService._trips[trip['id'] as String] = trip;
      return _json({'success': true, 'trip': trip});
    });
    r.post('/end', (Request req) async {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      final body = jsonDecode(await req.readAsString());
      final trip = DataService._trips[body['trip_id']];
      if (trip == null || trip['status'] != 'active') return _error('Active trip not found', status: 404);
      trip['end_time'] = DateTime.now().toIso8601String();
      final dur = max(1, DateTime.parse(trip['end_time']).difference(DateTime.parse(trip['start_time'])).inMinutes);
      trip['duration_min'] = dur;
      trip['cost'] = dur * 1200;
      trip['status'] = 'completed';
      final scooter = DataService.scooters.firstWhere((s) => s['id'] == trip['scooter_id']);
      scooter['status'] = 'available';
      scooter['battery'] = max(0, (scooter['battery'] as int) - dur * 2);
      return _json({'success': true, 'trip': trip});
    });
    r.get('/', (Request req) {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      final userTrips = DataService._trips.values.where((t) => t['user_id'] == DataService.currentUser!['id']).toList();
      return _json({'trips': userTrips});
    });
    return r;
  }
}

// ============ Users ============
class UsersRouter {
  Router get router {
    final r = Router();
    r.get('/me', (Request req) {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      return _json({'user': DataService.currentUser});
    });
    return r;
  }
}

// ============ Wallet ============
class WalletRouter {
  Router get router {
    final r = Router();
    r.get('/', (Request req) {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      final user = DataService.currentUser!;
      return _json({'balance': user['balance'], 'currency': 'UZS', 'transactions': DataService._transactions[user['id']] ?? []});
    });
    r.post('/topup', (Request req) async {
      if (DataService.currentUser == null) return _error('Not authenticated', status: 401);
      final body = jsonDecode(await req.readAsString());
      final amount = body['amount'] as int;
      if (amount <= 0) return _error('Invalid amount');
      DataService.currentUser!['balance'] += amount;
      return _json({'success': true, 'new_balance': DataService.currentUser!['balance']});
    });
    return r;
  }
}
