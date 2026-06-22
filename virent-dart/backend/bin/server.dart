// Virent Dart Backend — shelf + MongoDB
// One language (Dart) for: mobile, desktop, backend.
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

// ============ In-memory data ============
final scooters = [
  {'id': 's1', 'name': 'Virent#1', 'lat': 41.3111, 'lng': 69.2406, 'battery': 92, 'status': 'available', 'rate_per_min': 1200},
  {'id': 's2', 'name': 'Virent#2', 'lat': 41.3120, 'lng': 69.2410, 'battery': 78, 'status': 'available', 'rate_per_min': 1200},
  {'id': 's3', 'name': 'Virent#3', 'lat': 41.3100, 'lng': 69.2390, 'battery': 45, 'status': 'low_battery', 'rate_per_min': 1200},
  {'id': 's4', 'name': 'Virent#4', 'lat': 41.3130, 'lng': 69.2420, 'battery': 88, 'status': 'available', 'rate_per_min': 1200},
  {'id': 's5', 'name': 'Virent#5', 'lat': 41.3090, 'lng': 69.2380, 'battery': 100, 'status': 'available', 'rate_per_min': 1200},
];
final users = <String, Map<String, dynamic>>{};
final trips = <String, Map<String, dynamic>>{};
final otpCodes = <String, String>{};
Map<String, dynamic>? currentUser;

Response json(Map data, {int status = 200}) =>
    Response(status, body: jsonEncode(data), headers: {'Content-Type': 'application/json'});

Response error(String msg, {int status = 400}) =>
    Response(status, body: jsonEncode({'error': msg}), headers: {'Content-Type': 'application/json'});

void main() async {
  final router = Router();

  // Health
  router.get('/health', (_) => json({'status': 'ok', 'service': 'Virent Dart Backend', 'version': '1.0.0'}));

  // Auth
  router.post('/auth/phone/send-code', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final phone = body['phone'];
    if (phone == null) return error('phone required');
    final code = (100000 + Random().nextInt(900000)).toString();
    otpCodes[phone] = code;
    print('[OTP] $phone: $code');
    return json({'success': true, 'message': 'OTP sent'});
  });
  router.post('/auth/phone/verify', (Request req) async {
    final body = jsonDecode(await req.readAsString());
    final phone = body['phone'];
    if (otpCodes[phone] != body['code']) return error('Invalid OTP', status: 401);
    otpCodes.remove(phone);
    final user = users.putIfAbsent(phone, () => {
      'id': 'u${users.length + 1}', 'phone': phone, 'name': 'User ${phone.substring(phone.length - 4)}',
      'balance': 50000, 'trips_count': 0, 'created_at': DateTime.now().toIso8601String(),
    });
    currentUser = user;
    return json({'success': true, 'token': 'virent_${DateTime.now().millisecondsSinceEpoch}', 'user': user});
  });

  // Scooters
  router.get('/scooters/nearby', (Request req) {
    final lat = double.tryParse(req.url.queryParameters['lat'] ?? '') ?? 41.3111;
    final lng = double.tryParse(req.url.queryParameters['lng'] ?? '') ?? 69.2406;
    final nearby = scooters.map((s) {
      final dist = sqrt(pow((s['lat'] as double - lat) * 111000, 2) + pow((s['lng'] as double - lng) * 111000, 2));
      return {...s, 'distance': dist.round()};
    }).toList();
    return json({'scooters': nearby});
  });

  // Trips
  router.post('/trips/start', (Request req) async {
    if (currentUser == null) return error('Not authenticated', status: 401);
    final body = jsonDecode(await req.readAsString());
    final scooter = scooters.firstWhere((s) => s['id'] == body['scooter_id'], orElse: () => {});
    if (scooter.isEmpty) return error('Scooter not found', status: 404);
    scooter['status'] = 'in_use';
    final trip = {'id': 't${DateTime.now().millisecondsSinceEpoch}', 'user_id': currentUser!['id'],
      'scooter_id': body['scooter_id'], 'start_time': DateTime.now().toIso8601String(),
      'start_battery': scooter['battery'], 'status': 'active', 'cost': 0};
    trips[trip['id'] as String] = trip;
    return json({'success': true, 'trip': trip});
  });
  router.post('/trips/end', (Request req) async {
    if (currentUser == null) return error('Not authenticated', status: 401);
    final body = jsonDecode(await req.readAsString());
    final trip = trips[body['trip_id']];
    if (trip == null || trip['status'] != 'active') return error('Trip not found', status: 404);
    trip['end_time'] = DateTime.now().toIso8601String();
    final dur = max(1, DateTime.parse(trip['end_time']).difference(DateTime.parse(trip['start_time'])).inMinutes);
    trip['duration_min'] = dur;
    trip['cost'] = dur * 1200;
    trip['status'] = 'completed';
    final sc = scooters.firstWhere((s) => s['id'] == trip['scooter_id']);
    sc['status'] = 'available';
    sc['battery'] = max(0, (sc['battery'] as int) - dur * 2);
    currentUser!['balance'] -= trip['cost'] as int;
    currentUser!['trips_count'] = (currentUser!['trips_count'] ?? 0) + 1;
    return json({'success': true, 'trip': trip});
  });
  router.get('/trips', (Request req) {
    if (currentUser == null) return error('Not authenticated', status: 401);
    return json({'trips': trips.values.where((t) => t['user_id'] == currentUser!['id']).toList()});
  });

  // User
  router.get('/users/me', (Request req) {
    if (currentUser == null) return error('Not authenticated', status: 401);
    return json({'user': currentUser});
  });

  // Wallet
  router.get('/wallet', (Request req) {
    if (currentUser == null) return error('Not authenticated', status: 401);
    return json({'balance': currentUser!['balance'], 'currency': 'UZS', 'transactions': []});
  });
  router.post('/wallet/topup', (Request req) async {
    if (currentUser == null) return error('Not authenticated', status: 401);
    final body = jsonDecode(await req.readAsString());
    currentUser!['balance'] += body['amount'] as int;
    return json({'success': true, 'new_balance': currentUser!['balance']});
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8443');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('=========================================================');
  print('  Virent Dart Backend');
  print('  http://${server.address.host}:${server.port}');
  print('  Health: http://localhost:$port/health');
  print('  Scooters: http://localhost:$port/scooters/nearby?lat=41.3111&lng=69.2406');
  print('=========================================================');
}
