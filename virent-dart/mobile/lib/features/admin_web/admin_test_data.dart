// admin_test_data.dart — Realistic seed/sample data for the admin test mode.
//
// Used when `adminModeProvider` (in admin_web_providers.dart) is
// `AdminMode.test` or `AdminMode.testClient`. Keyed FutureProviders
// (scootersListProvider, customersListProvider, tripsListProvider,
// zonesListProvider, etc.) call `ref.watch(isAdminTestModeProvider)` and, when
// it returns true, swap their live API call for the matching list in this map.
//
// The seed data is intentionally realistic — plate numbers, phone numbers,
// statuses, battery levels and timestamps mirror what the production server
// would return so the UI looks identical to a live panel. None of these rows
// ever reach the server: test mode is purely client-side.
//
// Keys:
//   scooters, customers, trips, zones, orders, prepaids, promoCodes,
//   admins, smsLogs, auditLog, billingTransactions.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Realistic sample data shown in admin tables when test mode is active.
/// Each key matches the live provider it replaces — see the comments above
/// each FutureProvider in `admin_web_providers.dart`.
final adminTestDataProvider =
    Provider<Map<String, List<Map<String, dynamic>>>>((ref) {
  return const <String, List<Map<String, dynamic>>>{
    // ───────────────────────── Scooters ─────────────────────────
    'scooters': [
      {
        'id': 1001,
        'gosnomer': '01A123BC',
        'gsm': '+998901234567',
        'battery': 92,
        'status': 'ready',
        'model': 'Ninebot MAX G30',
        'company': 'ViRent',
      },
      {
        'id': 1002,
        'gosnomer': '02A456DE',
        'gsm': '+998902345678',
        'battery': 78,
        'status': 'active',
        'model': 'Xiaomi Pro 2',
        'company': 'ViRent',
      },
      {
        'id': 1003,
        'gosnomer': '03A789FG',
        'gsm': '+998903456789',
        'battery': 18,
        'status': 'lowbattery',
        'model': 'Kugoo M4 Pro',
        'company': 'ViRent',
      },
      {
        'id': 1004,
        'gosnomer': '04A012HI',
        'gsm': '+998904567890',
        'battery': 100,
        'status': 'charging',
        'model': 'Ninebot MAX G30',
        'company': 'ViRent',
      },
      {
        'id': 1005,
        'gosnomer': '05A345JK',
        'gsm': '+998905678901',
        'battery': 0,
        'status': 'offline',
        'model': 'Xiaomi 1S',
        'company': 'ViRent',
      },
      {
        'id': 1006,
        'gosnomer': '06A678LM',
        'gsm': '+998906789012',
        'battery': 65,
        'status': 'ready',
        'model': 'Ninebot ES4',
        'company': 'ViRent',
      },
      {
        'id': 1007,
        'gosnomer': '07A901NO',
        'gsm': '+998907890123',
        'battery': 41,
        'status': 'active',
        'model': 'Kugoo S3',
        'company': 'ViRent',
      },
    ],

    // ───────────────────────── Customers ─────────────────────────
    'customers': [
      {
        'id': 5001,
        'name': 'Алишер Каримов',
        'phone': '+998901112233',
        'balance': 25000,
        'status': 'active',
        'trips': 47,
        'created_at': '2024-03-12T09:14:00Z',
      },
      {
        'id': 5002,
        'name': 'Дилноза Юсупова',
        'phone': '+998905556677',
        'balance': 0,
        'status': 'blocked',
        'trips': 3,
        'created_at': '2024-08-02T17:42:00Z',
      },
      {
        'id': 5003,
        'name': 'Бекзод Ташмухамедов',
        'phone': '+998937778899',
        'balance': 120000,
        'status': 'active',
        'trips': 188,
        'created_at': '2023-11-21T11:00:00Z',
      },
      {
        'id': 5004,
        'name': 'Малика Рахимова',
        'phone': '+998911223344',
        'balance': -5000,
        'status': 'debt',
        'trips': 22,
        'created_at': '2024-06-15T08:30:00Z',
      },
      {
        'id': 5005,
        'name': 'Жасур Абдуллаев',
        'phone': '+998933445566',
        'balance': 78000,
        'status': 'active',
        'trips': 94,
        'created_at': '2024-01-08T14:22:00Z',
      },
    ],

    // ───────────────────────── Trips ─────────────────────────
    'trips': [
      {
        'id': 'T-2024-10001',
        'scooter_id': 1002,
        'user_id': 5001,
        'user_name': 'Алишер Каримов',
        'started_at': '2024-10-18T13:21:00Z',
        'ended_at': '2024-10-18T13:48:00Z',
        'duration_min': 27,
        'distance_km': 6.4,
        'cost': 16200,
        'status': 'completed',
      },
      {
        'id': 'T-2024-10002',
        'scooter_id': 1003,
        'user_id': 5004,
        'user_name': 'Малика Рахимова',
        'started_at': '2024-10-18T15:02:00Z',
        'ended_at': '2024-10-18T15:09:00Z',
        'duration_min': 7,
        'distance_km': 1.2,
        'cost': 4200,
        'status': 'refunded',
      },
      {
        'id': 'T-2024-10003',
        'scooter_id': 1007,
        'user_id': 5003,
        'user_name': 'Бекзод Ташмухамедов',
        'started_at': '2024-10-19T09:14:00Z',
        'ended_at': null,
        'duration_min': 0,
        'distance_km': 0,
        'cost': 0,
        'status': 'active',
      },
      {
        'id': 'T-2024-10004',
        'scooter_id': 1001,
        'user_id': 5005,
        'user_name': 'Жасур Абдуллаев',
        'started_at': '2024-10-19T11:33:00Z',
        'ended_at': '2024-10-19T11:51:00Z',
        'duration_min': 18,
        'distance_km': 4.1,
        'cost': 10800,
        'status': 'completed',
      },
    ],

    // ───────────────────────── Zones ─────────────────────────
    'zones': [
      {
        'id': 'Z-01',
        'name': 'Ташкент — Центр',
        'city': 'Ташкент',
        'color': '#7C69EF',
        'scooters': 142,
        'active': true,
      },
      {
        'id': 'Z-02',
        'name': 'Ташкент — Чиланзар',
        'city': 'Ташкент',
        'color': '#467FD0',
        'scooters': 38,
        'active': true,
      },
      {
        'id': 'Z-03',
        'name': 'Самарканд — Регистан',
        'city': 'Самарканд',
        'color': '#FFC107',
        'scooters': 24,
        'active': true,
      },
      {
        'id': 'Z-04',
        'name': 'Бухара — Старый город',
        'city': 'Бухара',
        'color': '#DF4759',
        'scooters': 0,
        'active': false,
      },
    ],

    // ───────────────────────── Orders ─────────────────────────
    'orders': [
      {
        'id': 'O-24001',
        'user_id': 5001,
        'user_name': 'Алишер Каримов',
        'amount': 16200,
        'status': 'paid',
        'created_at': '2024-10-18T13:48:00Z',
        'payment_method': 'click',
      },
      {
        'id': 'O-24002',
        'user_id': 5004,
        'user_name': 'Малика Рахимова',
        'amount': 4200,
        'status': 'refunded',
        'created_at': '2024-10-18T15:09:00Z',
        'payment_method': 'payme',
      },
      {
        'id': 'O-24003',
        'user_id': 5005,
        'user_name': 'Жасур Абдуллаев',
        'amount': 10800,
        'status': 'paid',
        'created_at': '2024-10-19T11:51:00Z',
        'payment_method': 'cash',
      },
    ],

    // ───────────────────────── Prepaids ─────────────────────────
    'prepaids': [
      {
        'id': 'P-9001',
        'code': 'VRR-AB12-CD34',
        'amount': 50000,
        'used': false,
        'created_at': '2024-09-30T10:00:00Z',
      },
      {
        'id': 'P-9002',
        'code': 'VRR-EF56-GH78',
        'amount': 100000,
        'used': true,
        'used_by': 5003,
        'created_at': '2024-09-25T12:00:00Z',
      },
    ],

    // ───────────────────────── Promo codes ─────────────────────────
    'promoCodes': [
      {
        'id': 'PR-001',
        'code': 'WELCOME10',
        'discount_percent': 10,
        'uses': 1284,
        'max_uses': 5000,
        'expires_at': '2024-12-31T23:59:59Z',
        'active': true,
      },
      {
        'id': 'PR-002',
        'code': 'SUMMER2024',
        'discount_percent': 15,
        'uses': 642,
        'max_uses': 1000,
        'expires_at': '2024-08-31T23:59:59Z',
        'active': false,
      },
    ],

    // ───────────────────────── Admins ─────────────────────────
    'admins': [
      {
        'id': 'A-01',
        'name': 'Шерзод Асилбеков',
        'email': 'sherzod@virent.uz',
        'role': 'superadmin',
        'last_login': '2024-10-19T08:00:00Z',
        'active': true,
      },
      {
        'id': 'A-02',
        'name': 'Оператор 1',
        'email': 'operator1@virent.uz',
        'role': 'operator',
        'last_login': '2024-10-18T17:33:00Z',
        'active': true,
      },
      {
        'id': 'A-03',
        'name': 'Техник Ташкент',
        'email': 'tech@virent.uz',
        'role': 'technician',
        'last_login': '2024-10-17T09:12:00Z',
        'active': false,
      },
    ],

    // ───────────────────────── SMS logs ─────────────────────────
    'smsLogs': [
      {
        'id': 'S-001',
        'phone': '+998901112233',
        'message': 'Код подтверждения: 123456',
        'status': 'sent',
        'created_at': '2024-10-19T08:01:00Z',
      },
      {
        'id': 'S-002',
        'phone': '+998905556677',
        'message': 'Код подтверждения: 654321',
        'status': 'pending',
        'created_at': '2024-10-19T08:05:00Z',
      },
    ],

    // ───────────────────────── Audit log ─────────────────────────
    'auditLog': [
      {
        'id': 'L-0001',
        'admin_id': 'A-01',
        'admin_name': 'Шерзод Асилбеков',
        'action': 'block_user',
        'target': '5002',
        'created_at': '2024-10-18T12:14:00Z',
      },
      {
        'id': 'L-0002',
        'admin_id': 'A-02',
        'admin_name': 'Оператор 1',
        'action': 'adjust_balance',
        'target': '5003 (+50000)',
        'created_at': '2024-10-18T15:48:00Z',
      },
      {
        'id': 'L-0003',
        'admin_id': 'A-01',
        'admin_name': 'Шерзод Асилбеков',
        'action': 'send_push',
        'target': 'broadcast: «Акция выходного дня»',
        'created_at': '2024-10-19T09:00:00Z',
      },
    ],

    // ───────────────────────── Billing transactions ─────────────────────────
    'billingTransactions': [
      {
        'id': 'TX-10001',
        'user_id': 5001,
        'amount': 16200,
        'type': 'topup',
        'provider': 'click',
        'status': 'success',
        'created_at': '2024-10-18T13:47:00Z',
      },
      {
        'id': 'TX-10002',
        'user_id': 5003,
        'amount': 50000,
        'type': 'topup',
        'provider': 'payme',
        'status': 'success',
        'created_at': '2024-10-17T19:22:00Z',
      },
      {
        'id': 'TX-10003',
        'user_id': 5004,
        'amount': 4200,
        'type': 'refund',
        'provider': 'payme',
        'status': 'success',
        'created_at': '2024-10-18T15:10:00Z',
      },
      {
        'id': 'TX-10004',
        'user_id': 5002,
        'amount': 12000,
        'type': 'topup',
        'provider': 'click',
        'status': 'failed',
        'created_at': '2024-10-16T11:05:00Z',
      },
    ],
  };
});
