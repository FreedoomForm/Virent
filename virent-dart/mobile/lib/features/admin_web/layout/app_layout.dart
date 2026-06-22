import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import 'sidebar.dart';
import 'header.dart';

import '../pages/map_page.dart';
import '../pages/billing_debts_page.dart';
import '../pages/admin_roles_page.dart';
import '../pages/scooters_page.dart';
import '../pages/push_history_page.dart';
import '../pages/payme_transactions_page.dart';
import '../pages/promo_codes_page.dart';
import '../pages/hold_logs_page.dart';
import '../pages/sms_logs_page.dart';
import '../pages/technicians_page.dart';
import '../pages/client_groups_page.dart';
import '../pages/inspection_damages_page.dart';
import '../pages/prepaid_orders_page.dart';
import '../pages/promo_series_page.dart';
import '../pages/selfies_page.dart';
import '../pages/admin_permissions_page.dart';
import '../pages/settings_notifications_page.dart';
import '../pages/settings_config_page.dart';
import '../pages/settings_scooter_groups_page.dart';
import '../pages/bonuses_page.dart';
import '../pages/fines_page.dart';
import '../pages/geozones_page.dart';
import '../pages/settings_drivers_page.dart';
import '../pages/chat_logs_page.dart';
import '../pages/statistics_page.dart';
import '../pages/alerts_page.dart';
import '../pages/task_technicians_page.dart';
import '../pages/billing_receipts_page.dart';
import '../pages/admin_contacts_page.dart';
import '../pages/click_transactions_page.dart';
import '../pages/admin_agreements_page.dart';
import '../pages/admin_faq_page.dart';
import '../pages/admin_companies_page.dart';
import '../pages/tariffs_page.dart';
import '../pages/logs_telemetry_page.dart';
import '../pages/logs_unconfirmed_page.dart';
import '../pages/logs_scooter_changes_page.dart';
import '../pages/tech_feedback_page.dart';
import '../pages/logs_client_changes_page.dart';
import '../pages/logs_payments_page.dart';
import '../pages/tariff_prices_page.dart';
import '../pages/tariff_abonements_page.dart';
import '../pages/tariff_subtariffs_page.dart';
import '../pages/tariff_until_dead_page.dart';
import '../pages/tariffs_subscriptions_page.dart';
import '../pages/iot_page.dart';
import '../pages/server_page.dart';
import '../pages/sms_gateway_page.dart';
import '../pages/trips_page.dart';
import '../pages/cities_page.dart';
import '../pages/juicers_page.dart';
import '../pages/support_page.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  // We can track the current active view here based on sidebar selection
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Header
          const AppHeader(),
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar
                AppSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                // Main Page Content
                Expanded(
                  child: _getPage(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: // Дашборд
        return const DashboardPage();
      case 1: // Статистика
        return const StatisticsPage();
      case 2: // Тревоги
        return const AlertsPage();
      case 3: // Карта (sidebar top-level)
      case 30: // Карта (Обычная)
        return const MapPage();
      case 4: // Самокаты
        return const ScootersPage();
      case 5: // Клиенты (история push)
        return const PushHistoryPage();
      case 6: // Заказы (Предоплаченные)
        return const PrepaidOrdersPage();
      case 7: // Селфи
        return const SelfiesPage();
      case 8: // Осмотр (Damages)
        return const InspectionDamagesPage();
      case 9: // Биллинг (Долги)
        return const BillingDebtsPage();
      case 90: // Биллинг (Штрафы - подраздел)
        return const FinesPage();
      case 91: // Биллинг (Квитанции / Чеки)
        return const BillingReceiptsPage();
      case 10: // Промо (Промокоды)
        return const PromoCodesPage();
      case 11: // Бонусы
        return const BonusesPage();
      case 12: // Тарифы -> Абонементы
        return const TariffAbonementsPage();
      case 120: // Тарифы -> Тарифы
        return const TariffsPage();
      case 121: // Тарифы -> Цены
        return const TariffPricesPage();
      case 122: // Тарифы -> Тариф подписка
        return const TariffSubTariffsPage();
      case 124: // Тарифы -> Абонементы (подписки)
        return const TariffsSubscriptionsPage();
      case 123: // Тарифы -> Тариф пока не сядет
        return const TariffUntilDeadPage();
      case 13: // Логи
        return const HoldLogsPage();
      case 130: // Логи -> Телеметрия
        return const LogsTelemetryPage();
      case 133: // Логи -> Неподтвержденные
        return const LogsUnconfirmedPage();
      case 134: // Логи -> Логи платежей
        return const LogsPaymentsPage();
      case 136: // Логи -> Логи изменения самоката
        return const LogsScooterChangesPage();
      case 137: // Логи -> Логи изменения клиента
        return const LogsClientChangesPage();
      case 20: // Логи (Авторизации - временный индекс)
        return const SmsLogsPage();
      case 14: // Администратор (Роли)
        return const AdminRolesPage();
      case 15: // Техники
        return const TechniciansPage();
      case 151: // Техники (Задачи)
        return const TaskTechniciansPage();
      case 153: // Техники (Фидбек)
        return const TechFeedbackPage();
      case 17: // Настройки (Группы Клиентов)
        return const ClientGroupsPage();
      case 100: // Биллинг (Payme транзакции) - временный индекс для просмотра
        return const PaymeTransactionsPage();
      case 101: // Биллинг (CLICK транзакции)
        return const ClickTransactionsPage();
      case 140: // Администратор (Разрешения)
        return const AdminPermissionsPage();
      case 142: // Администратор (Договора)
        return const AdminAgreementsPage();
      case 144: // Администратор (FAQ)
        return const AdminFaqPage();
      case 145: // Администратор (Компании)
        return const AdminCompaniesPage();
      case 147: // Администратор (Контакты)
        return const AdminContactsPage();
      case 16: // Геозоны
        return const GeozonesPage();
      case 170: // Настройки (Уведомления)
        return const SettingsNotificationsPage();
      case 171: // Настройки (Конфиг)
        return const SettingsConfigPage();
      case 172: // Настройки (Группы Самокатов)
        return const SettingsScooterGroupsPage();
      case 173: // Настройки (Драйверы)
        return const SettingsDriversPage();
      case 18: // Чат
      case 19: // Журнал чата
        return const ChatLogsPage();
      case 111: // Промо (Серии)
        return const PromoSeriesPage();
      // ---- Extra pages (ported from old admin) ----
      case 200:
        return const IotPage();
      case 201:
        return const ServerPage();
      case 202:
        return const SmsGatewayPage();
      case 203:
        return const TripsPage();
      case 204:
        return const CitiesPage();
      case 205:
        return const JuicersPage();
      case 206:
        return const SupportPage();
      default:
        return Center(
          child: Text(
            'Страница $index пока не реализована.\nВыберите "Дашборд" (0), "Карта" (3), "Самокаты" (4), "Клиенты" (5), "Биллинг" (9) или "Администратор" (14).',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
    }
  }
}
