// admin_web_providers.dart — Riverpod providers for the admin web panel.
//
// Wires the 46-page admin web panel to the existing AdminRepository +
// embedded server. Each provider is `autoDispose` so pages refresh their
// data on every visit, and exposes typed data so the page widgets can
// stay stateless.
//
// Provider hierarchy:
//   adminWebRepositoryProvider  → singleton AdminRepository
//   ├── dashboardStatsProvider        → FutureProvider<Map>           (/admin/stats)
//   ├── scootersListProvider          → FutureProvider<List<Map>>     (/admin/scooters)
//   ├── zonesListProvider             → FutureProvider<List<Map>>     (/zones)
//   ├── customersListProvider         → FutureProvider<List<Map>>     (/admin/customers)
//   ├── auditLogProvider              → FutureProvider<List<Map>>     (/audit-log)
//   ├── tripsListProvider             → FutureProvider<List<Map>>     (/trips)
//   ├── prepaidOrdersProvider         → FutureProvider<List<Map>>     (/admin/prepaids)
//   ├── promoCodesProvider            → FutureProvider<List<Map>>     (/admin/promo-codes)
//   ├── adminListProvider             → FutureProvider<List<Map>>     (/admin/list)
//   ├── smsLogsProvider               → FutureProvider<List<Map>>     (/sms/pending)
//   ├── pushHistoryProvider           → FutureProvider<List<Map>>     (/admin/notifications/stats)
//   └── billingTransactionsProvider   → FutureProvider<List<Map>>     (/wallet/transactions)
//
// Action providers (FutureProvider-family wrappers that expose a run()
// method so pages can trigger mutations):
//   - blockUserAction
//   - unblockUserAction
//   - adjustBalanceAction
//   - refundTripAction
//   - sendIoTCommandAction
//   - sendBroadcastNotificationAction
//   - createZoneAction
//   - deleteZoneAction
//   - createPromoCodeAction
//   - bulkGeneratePrepaidsAction

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/configs/services/api_client.dart';
import '../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
export '../auth/presentation/providers/auth_providers.dart' show apiClientProvider;
import '../admin/data/services/admin_repository.dart';
import 'admin_test_data.dart' show adminTestDataProvider;

/// Singleton [AdminRepository] shared by every admin-web page.
final adminWebRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(apiClientProvider));
});

// ============================================================================
// READ PROVIDERS — fetch data from the embedded server
// ============================================================================

/// Aggregate fleet stats — used by the dashboard's 10 stat cards.
final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminWebRepositoryProvider).getStats();
});

/// List of every scooter in the fleet.
final scootersListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(isAdminTestModeProvider)) {
    return ref.read(adminTestDataProvider)['scooters'] ??
        const <Map<String, dynamic>>[];
  }
  return ref.read(adminWebRepositoryProvider).getScooters();
});

/// List of every geofenced zone.
final zonesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(isAdminTestModeProvider)) {
    return ref.read(adminTestDataProvider)['zones'] ??
        const <Map<String, dynamic>>[];
  }
  return ref.read(adminWebRepositoryProvider).getZones();
});

/// List of every customer (rider) account.
final customersListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(isAdminTestModeProvider)) {
    return ref.read(adminTestDataProvider)['customers'] ??
        const <Map<String, dynamic>>[];
  }
  return ref.read(adminWebRepositoryProvider).getCustomers();
});

/// Audit log entries — most recent first.
final auditLogProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminWebRepositoryProvider).getAuditLog();
});

/// All trips (history + active) for the admin trips explorer.
final tripsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(isAdminTestModeProvider)) {
    return ref.read(adminTestDataProvider)['trips'] ??
        const <Map<String, dynamic>>[];
  }
  final api = ref.read(apiClientProvider);
  final data = await api.get('/trips');
  final list = data['trips'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

/// Prepaid card orders (for the prepaid-orders page).
final prepaidOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/admin/prepaids');
    final list = data['prepaids'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
});

/// Promo codes (for the promo-codes page).
final promoCodesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/admin/promo-codes');
    final list = data['promos'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
});

/// Admin user accounts (for the admin-roles page).
final adminListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/admin/list');
    final list = data['admins'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
});

/// Pending SMS queue (for the sms-logs page).
final smsLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/sms/pending');
    final list = data['pending'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
});

/// Push notification history + delivery stats.
final pushHistoryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    return await api.get('/admin/notifications/stats');
  } catch (_) {
    return const {};
  }
});

/// Wallet transactions (for billing pages).
final billingTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/wallet/transactions');
    final list = data['transactions'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
});

// ============================================================================
// ACTION PROVIDERS — mutations triggered by admin button taps
// ============================================================================

/// Blocks a user with a reason. Call `ref.read(blockUserAction)(...)`.
final blockUserAction = Provider<Future<void> Function(String, String)>(
    (ref) => (userId, reason) async {
          await ref.read(adminWebRepositoryProvider).blockUser(userId, reason);
          ref.invalidate(customersListProvider);
        });

/// Unblocks a previously blocked user.
final unblockUserAction = Provider<Future<void> Function(String)>(
    (ref) => (userId) async {
          await ref.read(adminWebRepositoryProvider).unblockUser(userId);
          ref.invalidate(customersListProvider);
        });

/// Adjusts a customer's wallet balance.
final adjustBalanceAction =
    Provider<Future<void> Function(String userId, int delta, String reason)>(
        (ref) => (userId, delta, reason) async {
              await ref
                  .read(adminWebRepositoryProvider)
                  .adjustBalance(userId, delta, reason);
              ref.invalidate(customersListProvider);
            });

/// Refunds a trip.
final refundTripAction =
    Provider<Future<void> Function(String tripId, int amount, String reason)>(
        (ref) => (tripId, amount, reason) async {
              await ref
                  .read(adminWebRepositoryProvider)
                  .refundTrip(tripId, amount, reason);
              ref.invalidate(tripsListProvider);
            });

/// Sends an IoT command to a scooter (lock / unlock / alarm / reboot / ...).
final sendIoTCommandAction =
    Provider<Future<void> Function(String scooterMac, String command)>(
        (ref) => (scooterMac, command) async {
              await ref
                  .read(adminWebRepositoryProvider)
                  .sendIoTCommand(scooterMac, command);
              ref.invalidate(scootersListProvider);
            });

/// Broadcasts a push notification.
final sendBroadcastNotificationAction =
    Provider<Future<void> Function({required String title, required String body, String audience})>(
        (ref) => ({required title, required body, audience = 'all'}) async {
              await ref.read(adminWebRepositoryProvider).sendNotification(
                    title: title,
                    body: body,
                    audience: audience,
                  );
              ref.invalidate(pushHistoryProvider);
            });

/// Creates a new geofenced zone.
final createZoneAction =
    Provider<Future<void> Function(Map<String, dynamic> zone)>(
        (ref) => (zone) async {
              await ref.read(adminWebRepositoryProvider).createZone(zone);
              ref.invalidate(zonesListProvider);
            });

/// Deletes a geofenced zone by id.
final deleteZoneAction = Provider<Future<void> Function(String zoneId)>(
    (ref) => (zoneId) async {
          await ref.read(adminWebRepositoryProvider).deleteZone(zoneId);
          ref.invalidate(zonesListProvider);
        });

/// Generates a batch of prepaid top-up codes.
final bulkGeneratePrepaidsAction =
    Provider<Future<void> Function(int count, int amount)>(
        (ref) => (count, amount) async {
          final api = ref.read(apiClientProvider);
          await api.post('/admin/prepaids/bulk', {
            'count': count,
            'amount': amount,
          });
          ref.invalidate(prepaidOrdersProvider);
        });

/// Creates a new promo code.
final createPromoCodeAction =
    Provider<Future<void> Function(Map<String, dynamic> promo)>(
        (ref) => (promo) async {
          final api = ref.read(apiClientProvider);
          await api.post('/admin/promo-codes', promo);
          ref.invalidate(promoCodesProvider);
        });

/// Creates a new admin account (super_admin only).
final createAdminAction =
    Provider<Future<void> Function(Map<String, dynamic> admin)>(
        (ref) => (admin) async {
          final api = ref.read(apiClientProvider);
          await api.post('/admin/create', admin);
          ref.invalidate(adminListProvider);
        });

/// Deletes an admin account by id.
final deleteAdminAction = Provider<Future<void> Function(String adminId)>(
    (ref) => (adminId) async {
          final api = ref.read(apiClientProvider);
          await api.delete('/admin/delete/$adminId');
          ref.invalidate(adminListProvider);
        });

// ============================================================================
// EXTENDED READ PROVIDERS — for the remaining 38 pages
// ============================================================================

/// Generic fetch helper — wraps any GET endpoint and returns a List.
Future<List<Map<String, dynamic>>> _safeGetList(
    ApiClient api, String path, String listKey) async {
  try {
    final data = await api.get(path);
    final list = data[listKey] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return const [];
  }
}

/// Alerts / fleet alerts (Тревоги).
final alertsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/alerts', 'alerts'));

/// Cities list (Города).
final citiesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/cities', 'cities'));

/// Trips list (Поездки) — re-exported here for admin-web consumers.
final adminTripsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/trips', 'trips'));

/// Audit log entries (Журнал аудита).
final adminAuditLogProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) async {
  return ref.read(adminWebRepositoryProvider).getAuditLog();
});

/// Analytics data (Аналитика) — revenue/users/rides per day.
final analyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(apiClientProvider).get('/admin/analytics');
  } catch (_) {
    return const {};
  }
});

/// IoT command history (IoT логи).
final iotLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/iot/logs', 'logs'));

/// Juicers / charging team (Джусеры).
final juicersListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/juicers', 'juicers'));

/// Support tickets (Тикеты поддержки).
final supportTicketsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/support', 'tickets'));

/// Server / Docker containers status (Сервер).
final serverStatusProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(apiClientProvider).get('/admin/docker/status');
  } catch (_) {
    return const {};
  }
});

/// Server logs (Журнал сервера).
final serverLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs', 'logs'));

/// Billing receipts (Квитанции / Чеки).
final billingReceiptsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/receipts', 'receipts'));

/// Bank cards (Банковские карты).
final bankCardsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/bank-cards', 'cards'));

/// Billing debts (Долги).
final billingDebtsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/debts', 'debts'));

/// Billing invoices (Счета).
final billingInvoicesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/invoices', 'invoices'));

/// Fines (Штрафы).
final finesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/fines', 'fines'));

/// Payme transactions.
final paymeTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/payme', 'transactions'));

/// CLICK transactions.
final clickTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/click', 'transactions'));

/// Selfies (фото верификации).
final selfiesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/selfies', 'selfies'));

/// Inspection damages (Осмотр повреждений).
final inspectionDamagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/inspections', 'inspections'));

/// Client groups (Группы клиентов).
final clientGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/client-groups', 'groups'));

/// Bonuses (Бонусы).
final bonusesListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/bonuses', 'bonuses'));

/// Bonus packages (Пакеты бонусов).
final bonusPackagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/bonus-packages', 'packages'));

/// Promo series (Серии промокодов).
final promoSeriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/promo-series', 'series'));

/// Orders (Заказы) — list endpoint for the orders admin page.
final ordersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/orders', 'orders'));

/// Selfies (Селфи) — alias provider for the selfies admin page.
final selfiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/selfies', 'selfies'));

/// Tariffs list (Тарифы).
final tariffsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariffs', 'tariffs'));

/// Tariff prices (Цены тарифов).
final tariffPricesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariff-prices', 'prices'));

/// Tariff subscriptions (Подписки тарифов).
final tariffSubscriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariff-subscriptions', 'subscriptions'));

/// Tariff abonements (Абонементы).
final tariffAbonementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariff-abonements', 'abonements'));

/// Tariff subscriptions — singular alias (Подписочные тарифы).
final tariffSubscriptionProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariff-subscriptions', 'subscriptions'));

/// Tariff "until dead" (Тариф пока не сядет).
final tariffUntilDeadProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tariff-until-dead', 'tariffs'));

/// Tarirov / calibration entries (Тарирование).
final tarirovProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tarirov', 'entries'));

/// Models (Модели самокатов).
final modelsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/models', 'models'));

/// Technicians (Техники).
final techniciansListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/technicians', 'technicians'));

/// Technicians — singular alias (Техники).
final techniciansProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/technicians', 'technicians'));

/// Tech tasks (Задачи техников).
final techTasksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tech-tasks', 'tasks'));

/// Tech feedback (Фидбек техников).
final techFeedbackProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/tech-feedback', 'feedback'));

/// Chat logs (Журнал чата).
final chatLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/chat-logs', 'logs'));

/// Logs — telemetry (Логи телеметрии).
final logsTelemetryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/telemetry', 'logs'));

/// Logs — unconfirmed (Неподтвержденные).
final logsUnconfirmedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/unconfirmed', 'logs'));

/// Logs — payments (Логи платежей).
final logsPaymentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/payments', 'logs'));

/// Logs — scooter changes (Изменения самоката).
final logsScooterChangesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/scooter-changes', 'logs'));

/// Logs — client changes (Изменения клиента).
final logsClientChangesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/client-changes', 'logs'));

/// Logs — hold (Холд).
final holdLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/hold', 'logs'));

/// Logs — action history (История действий).
final logsActionHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/action-history', 'logs'));

/// Logs — auth (Логи авторизации).
final logsAuthProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/auth', 'logs'));

/// Logs — raider mode (Логи режим Raider).
final raiderLogsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/logs/raider', 'logs'));

/// Geozone groups (Группы геозон).
final geozoneGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/geozone-groups', 'groups'));

/// Dots / parking points (Dots).
final dotsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/dots', 'dots'));

/// Push history (История push-уведомлений).
final pushHistoryListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/push-history', 'pushes'));

/// Settings — config (Настройки / Конфиг).
final settingsConfigProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(apiClientProvider).get('/admin/settings/config');
  } catch (_) {
    return const {};
  }
});

/// Settings — drivers (Драйверы).
final settingsDriversProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/settings/drivers', 'drivers'));

/// Drivers — short alias (Драйверы).
final driversProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/settings/drivers', 'drivers'));

/// Settings — notifications (Уведомления).
final settingsNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(apiClientProvider).get('/admin/settings/notifications');
  } catch (_) {
    return const {};
  }
});

/// Settings — scooter groups (Группы самокатов).
final settingsScooterGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/settings/scooter-groups', 'groups'));

/// Scooter groups — short alias (Группы самокатов).
final scooterGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/settings/scooter-groups', 'groups'));

/// Admin agreements (Договора).
final adminAgreementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/agreements', 'agreements'));

/// Admin FAQ (Частые вопросы).
final adminFaqProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/faq', 'faq'));

/// Admin companies (Компании).
final adminCompaniesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/companies', 'companies'));

/// Admin contacts (Контакты).
final adminContactsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/contacts', 'contacts'));

/// Admin permissions (Разрешения).
final adminPermissionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/permissions', 'permissions'));

/// Admin roles (Роли).
final adminRolesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => _safeGetList(ref.read(apiClientProvider), '/admin/roles', 'roles'));

// ============================================================================
// EXTENDED ACTION PROVIDERS — for the remaining pages
// ============================================================================

/// Generic delete-by-id action. Invalidates the given provider after delete.
final genericDeleteAction =
    Provider<Future<void> Function(String endpoint, String id, AutoDisposeFutureProvider<List<Map<String, dynamic>>> invalidate)>(
        (ref) => (endpoint, id, invalidate) async {
              await ref.read(apiClientProvider).delete('$endpoint/$id');
              ref.invalidate(invalidate);
            });

/// Generic create action. Invalidates the given provider after create.
final genericCreateAction =
    Provider<Future<void> Function(String endpoint, Map<String, dynamic> body, AutoDisposeFutureProvider<List<Map<String, dynamic>>> invalidate)>(
        (ref) => (endpoint, body, invalidate) async {
              await ref.read(apiClientProvider).post(endpoint, body);
              ref.invalidate(invalidate);
            });

/// Generic update action. Invalidates the given provider after update.
final genericUpdateAction =
    Provider<Future<void> Function(String endpoint, String id, Map<String, dynamic> body, AutoDisposeFutureProvider<List<Map<String, dynamic>>> invalidate)>(
        (ref) => (endpoint, id, body, invalidate) async {
              await ref.read(apiClientProvider).put('$endpoint/$id', body);
              ref.invalidate(invalidate);
            });

// ============================================================================
// ADMIN MODE — toggles between normal / test / client / testClient modes.
// Set by the profile dropdown in the header (see layout/header.dart). Pages
// can watch [isAdminTestModeProvider] to swap live API data for the seed data
// in [adminTestDataProvider]. The layout (layout/app_layout.dart) watches
// [adminModeProvider] directly to overlay the mobile client UI when in client
// mode and to show the orange "ТЕСТОВЫЙ РЕЖИМ" banner when in test mode.
// ============================================================================

/// Modes that the admin header's profile dropdown can switch to.
enum AdminMode {
  /// Production admin panel — live data from the server.
  normal,

  /// Test mode — show seed/sample data in all tables; an orange banner is
  /// displayed at the top warning that changes do not affect real data.
  test,

  /// Client mode — overlay the mobile client UI (HomeScreen) on top of the
  /// admin panel. The client UI connects to the same server via the ngrok URL
  /// already configured in `apiClientProvider`.
  client,

  /// Test client mode — same as client mode but with test/seed data shown in
  /// the admin tables underneath the overlay.
  testClient,
}

/// Current admin mode. Set by the profile dropdown in the header.
final adminModeProvider = StateProvider<AdminMode>((ref) => AdminMode.normal);

/// True when the admin should see test/seed data instead of live API data —
/// i.e. when [adminModeProvider] is [AdminMode.test] or [AdminMode.testClient].
/// Read-only convenience provider used by individual FutureProviders so they
/// don't have to repeat the mode comparison.
final isAdminTestModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(adminModeProvider);
  return mode == AdminMode.test || mode == AdminMode.testClient;
});

/// True when the mobile client UI overlay should be shown on top of the admin
/// panel — i.e. when [adminModeProvider] is [AdminMode.client] or
/// [AdminMode.testClient].
final isClientModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(adminModeProvider);
  return mode == AdminMode.client || mode == AdminMode.testClient;
});
