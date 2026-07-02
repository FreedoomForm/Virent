import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sidebar.dart';
import 'header.dart';

import '../admin_web_providers.dart';
import '../../home/presentation/screens/home_screen.dart';

import '../pages/dashboard_page.dart';
import '../pages/statistics_page.dart';
import '../pages/alerts_page.dart';
import '../pages/map_page.dart';
import '../pages/scooters_page.dart';
import '../pages/clients_page.dart';
import '../pages/push_history_page.dart';
import '../pages/orders_page.dart';
import '../pages/prepaid_orders_page.dart';
import '../pages/selfies_page.dart';
import '../pages/inspection_damages_page.dart';
import '../pages/billing_debts_page.dart';
import '../pages/fines_page.dart';
import '../pages/billing_receipts_page.dart';
import '../pages/billing_invoices_page.dart';
import '../pages/bank_cards_page.dart';
import '../pages/payme_transactions_page.dart';
import '../pages/click_transactions_page.dart';
import '../pages/promo_codes_page.dart';
import '../pages/promo_series_page.dart';
import '../pages/bonuses_page.dart';
import '../pages/bonus_packages_page.dart';
import '../pages/hold_logs_page.dart';
import '../pages/tariff_abonements_page.dart';
import '../pages/tariff_offers_page.dart';
import '../pages/tariff_prices_page.dart';
import '../pages/tariffs_subscriptions_page.dart';
import '../pages/tariff_until_dead_page.dart';
import '../pages/logs_telemetry_page.dart';
import '../pages/logs_action_history_page.dart';
import '../pages/logs_auth_page.dart';
import '../pages/logs_unconfirmed_page.dart';
import '../pages/logs_payments_page.dart';
import '../pages/logs_scooter_changes_page.dart';
import '../pages/logs_client_changes_page.dart';
import '../pages/admin_accounts_page.dart';
import '../pages/admin_roles_page.dart';
import '../pages/admin_agreements_page.dart';
import '../pages/admin_permissions_page.dart';
import '../pages/admin_faq_page.dart';
import '../pages/admin_companies_page.dart';
import '../pages/admin_contacts_page.dart';
import '../pages/technicians_page.dart';
import '../pages/technician_tasks_page.dart';
import '../pages/raider_logs_page.dart';
import '../pages/tech_feedback_page.dart';
import '../pages/client_groups_page.dart';
import '../pages/geozones_page.dart';
import '../pages/dots_page.dart';
import '../pages/geozone_groups_page.dart';
import '../pages/settings_notifications_page.dart';
import '../pages/settings_config_page.dart';
import '../pages/scooter_groups_page.dart';
import '../pages/drivers_page.dart';
import '../pages/tarirov_page.dart';
import '../pages/models_page.dart';
import '../pages/online_chat_page.dart';
import '../pages/chat_logs_page.dart';
import '../pages/sms_logs_page.dart';
import '../pages/settings_drivers_page.dart';

class AppLayout extends ConsumerStatefulWidget {
  const AppLayout({super.key});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(adminModeProvider);
    final bool isTest =
        mode == AdminMode.test || mode == AdminMode.testClient;
    final bool isClient =
        mode == AdminMode.client || mode == AdminMode.testClient;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          if (isTest) _buildTestBanner(mode),
          Expanded(
            child: Stack(
              children: [
                // Underlying admin panel (sidebar + page content) is always
                // built so that switching modes doesn't lose page state.
                Row(
                  children: [
                    AppSidebar(
                      selectedIndex: _selectedIndex,
                      onItemSelected: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                    Expanded(
                      child: _getPage(_selectedIndex),
                    ),
                  ],
                ),
                // Mobile client UI overlay (client / testClient modes).
                if (isClient) _buildClientOverlay(mode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orange banner shown at the top whenever the admin is in a test mode.
  /// Reminds the user that table data is seed/sample data and that no real
  /// mutations are being made.
  Widget _buildTestBanner(AdminMode mode) {
    final String label = mode == AdminMode.testClient
        ? 'ТЕСТОВЫЙ РЕЖИМ КЛИЕНТА — изменения не влияют на реальные данные'
        : 'ТЕСТОВЫЙ РЕЖИМ — изменения не влияют на реальные данные';
    return Container(
      width: double.infinity,
      color: Colors.deepOrange,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () => ref.read(adminModeProvider.notifier).state =
                AdminMode.normal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Выйти из тестового режима',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen overlay of the mobile client UI ([HomeScreen]) on top of the
  /// admin panel. The client UI connects to the same server via the ngrok URL
  /// already configured in `apiClientProvider`. A floating exit button lets
  /// the admin return to the panel without going through the header dropdown.
  Widget _buildClientOverlay(AdminMode mode) {
    return Positioned.fill(
      child: Material(
        color: Colors.black87,
        child: Stack(
          children: [
            // The mobile client UI. Same HomeScreen the rider app shows —
            // it pulls live data from the server via the same providers.
            const Positioned.fill(
              child: HomeScreen(),
            ),
            // Floating exit button (top-right).
            Positioned(
              top: 12,
              right: 12,
              child: FloatingActionButton.extended(
                heroTag: 'exit_client_mode',
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.close),
                label: const Text('Выйти из режима клиента'),
                onPressed: () {
                  ref.read(adminModeProvider.notifier).state =
                      AdminMode.normal;
                },
              ),
            ),
            // Test-client-mode badge (top-left) — only when testClient.
            if (mode == AdminMode.testClient)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_outlined,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'ТЕСТ-КЛИЕНТ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: // Дашборд
        return DashboardPage();
      case 1: // Статистика
        return StatisticsPage();
      case 2: // Тревоги
        return AlertsPage();
      case 30: // Карта
        return MapPage();
      case 4: // Самокаты
        return ScootersPage();
      case 5: // Клиенты
        return ClientsPage();
      case 51: // Клиенты -> История Push
        return PushHistoryPage();
      case 6: // Заказы
        return OrdersPage();
      case 61: // Заказы (Предоплаченные)
        return PrepaidOrdersPage();
      case 7: // Селфи
        return SelfiesPage();
      case 8: // Осмотр (Damages)
        return InspectionDamagesPage();
      case 9: // Биллинг (Долги)
        return BillingDebtsPage();
      case 90: // Биллинг (Штрафы)
        return FinesPage();
      case 91: // Биллинг (Квитанции)
        return BillingReceiptsPage();
      case 92: // Биллинг (Счета)
        return BillingInvoicesPage();
      case 93: // Биллинг (Банковские карты)
        return BankCardsPage();
      case 100: // Биллинг (Транзакции Payme)
        return PaymeTransactionsPage();
      case 101: // Биллинг (Транзакции Click)
        return ClickTransactionsPage();
      case 10: // Промо (Промокоды)
        return PromoCodesPage();
      case 111: // Промо (Серии промокодов)
        return PromoSeriesPage();
      case 11: // Бонусы
        return BonusesPage();
      case 110: // Бонусы (Пакеты)
        return BonusPackagesPage();
      case 112: // Логи (Hold Logs)
        return HoldLogsPage();
      case 12: // Тарифы -> Абонементы
        return TariffAbonementsPage();
      case 120: // Тарифы -> Тарифы
        return TariffOffersPage();
      case 121: // Тарифы -> Цены
        return TariffPricesPage();
      case 122: // Тарифы -> Тариф подписка
        return TariffsSubscriptionsPage();
      case 123: // Тарифы -> Тариф пока не сядет
        return TariffUntilDeadPage();
      case 130: // Логи -> Телеметрия
        return LogsTelemetryPage();
      case 131: // Логи -> История действий
        return LogsActionHistoryPage();
      case 20: // Логи авторизации
        return LogsAuthPage();
      case 133: // Логи -> Неподтвержденные
        return LogsUnconfirmedPage();
      case 134: // Логи -> Логи платежей
        return LogsPaymentsPage();
      case 136: // Логи -> Логи изменения самоката
        return LogsScooterChangesPage();
      case 137: // Логи -> Логи изменения клиента
        return LogsClientChangesPage();
      case 14: // Админ -> Учетные записи
        return AdminAccountsPage();
      case 140: // Админ -> Разрешения
        return AdminPermissionsPage();
      case 141: // Админ -> Роли
        return AdminRolesPage();
      case 142: // Админ -> Договора и соглашения
        return AdminAgreementsPage();
      case 144: // Админ -> F.A.Q.
        return AdminFaqPage();
      case 145: // Администратор (Компании)
        return AdminCompaniesPage();
      case 147: // Админ -> Контакты
        return AdminContactsPage();
      case 15: // Техники
        return TechniciansPage();
      case 151: // Техники (Задачи)
        return TechnicianTasksPage();
      case 152: // Техники (Модели рейдеров)
        return RaiderLogsPage();
      case 153: // Техники (Фидбек)
        return TechFeedbackPage();
      case 16: // Геозоны
      case 162:
      case 163:
      case 164:
      case 165:
      case 166:
      case 167:
        return GeozonesPage();
      case 160: // Геозоны (Геоточки)
        return DotsPage();
      case 161: // Геозоны (Группы)
        return GeozoneGroupsPage();
      case 17: // Настройки (Группы Клиентов)
        return ClientGroupsPage();
      case 170: // Настройки (Уведомления)
        return SettingsNotificationsPage();
      case 171: // Настройки (Конфиг)
        return SettingsConfigPage();
      case 172: // Настройки (Группы Самокатов)
        return ScooterGroupsPage();
      case 173: // Настройки (Драйверы)
        return DriversPage();
      case 174: // Настройки (Тарирование)
        return TarirovPage();
      case 175: // Настройки (Модели)
        return ModelsPage();
      case 18: // Чат
        return OnlineChatPage();
      case 19: // Журнал чата
        return ChatLogsPage();
      default:
        return Center(
          child: Text(
            'Страница $index пока не реализована.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
    }
  }
}
