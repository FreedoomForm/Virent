// Virent Dart Backend — Full API (production parity with embedded server)
// One language (Dart) for: mobile, desktop, backend.
//
// Mounts Auth, Scooters, Trips, Wallet, Admin, IoT, SMS routes.
// Deploy: docker build -t virent-backend . && docker run -p 8443:8443 virent-backend

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/routes/all_routes.dart';

void main() async {
  final router = Router();

  // ── Health ─────────────────────────────────────────────────────────
  router.get('/health', (_) => Response.ok(
    '{"status":"ok","service":"Virent Dart Backend","version":"1.0.0"}',
    headers: {'Content-Type': 'application/json'},
  ));

  // ── Mount route groups ─────────────────────────────────────────────
  router.mount('/auth/', AuthRouter().router);
  router.mount('/scooters/', ScootersRouter().router);
  router.mount('/trips/', TripsRouter().router);
  router.mount('/users/', UsersRouter().router);
  router.mount('/wallet/', WalletRouter().router);
  router.mount('/admin/', AdminRouter().router);
  router.mount('/iot/', IotRouter().router);
  router.mount('/sms/', SmsRouter().router);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8443');
  final server = await io.serve(handler, '0.0.0.0', port);
  print('=========================================================');
  print('  Virent Dart Backend — Full API');
  print('  http://${server.address.host}:${server.port}');
  print('  Health:   http://localhost:$port/health');
  print('  Auth:     POST /auth/phone/send-code');
  print('  Admin:    POST /admin/login');
  print('  IoT:      POST /iot/telemetry');
  print('  SMS:      GET  /sms/pending');
  print('=========================================================');
}
