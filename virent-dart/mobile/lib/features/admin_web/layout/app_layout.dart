import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import 'sidebar.dart';
import 'header.dart';

// All page imports matching mockup structure
import '../pages/map_page.dart';
import '../pages/billing_debts_page.dart';
import '../pages/admin_roles_page.dart';
import '../pages/scooters_page.dart';
import '../pages/push_history_page.dart';
import '../pages/payme_transactions_page.dart';
import '../pages/promo_codes_page.dart';
import '../pages/hold_logs_page.dart';
import '../pages/tariffs_subscriptions_page.dart';
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

// Extra pages not in mockup but present in current
import '../pages/scooter_detail_page.dart';
import '../pages/bulk_prepaid_page.dart';
import '../pages/push_composer_page.dart';
import '../pages/zone_editor_page.dart';
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: return DashboardPage();
      case 1: return StatisticsPage();
      case 2: return AlertsPage();
      case 30: return MapPage();
      case 4: return ScootersPage();
      case 5: return PushHistoryPage();
      case 6: return PrepaidOrdersPage();
      case 7: return SelfiesPage();
      case 8: return InspectionDamagesPage();
      case 9: return BillingDebtsPage();
      case 90: return FinesPage();
      case 91: return BillingReceiptsPage();
      case 10: return PromoCodesPage();
      case 11: return BonusesPage();
      case 12: return TariffAbonementsPage();
      case 120: return TariffsPage();
      case 121: return TariffPricesPage();
      case 122: return TariffSubTariffsPage();
      case 124: return TariffsSubscriptionsPage();
      case 123: return TariffUntilDeadPage();
      case 13: return HoldLogsPage();
      case 130: return LogsTelemetryPage();
      case 133: return LogsUnconfirmedPage();
      case 134: return LogsPaymentsPage();
      case 136: return LogsScooterChangesPage();
      case 137: return LogsClientChangesPage();
      case 20: return SmsLogsPage();
      case 14: return AdminRolesPage();
      case 140: return AdminPermissionsPage();
      case 142: return AdminAgreementsPage();
      case 144: return AdminFaqPage();
      case 145: return AdminCompaniesPage();
      case 147: return AdminContactsPage();
      case 15: return TechniciansPage();
      case 151: return TaskTechniciansPage();
      case 153: return TechFeedbackPage();
      case 16: return GeozonesPage();
      case 17: return ClientGroupsPage();
      case 100: return PaymeTransactionsPage();
      case 101: return ClickTransactionsPage();
      case 170: return SettingsNotificationsPage();
      case 171: return SettingsConfigPage();
      case 172: return SettingsScooterGroupsPage();
      case 173: return SettingsDriversPage();
      case 18:
      case 19: return ChatLogsPage();
      case 111: return PromoSeriesPage();
      // Extra pages (not in mockup)
      case 3: return MapPage();
      case 60: return BulkPrepaidPage();
      case 1620: return PushComposerPage();
      case 1332: return ScooterDetailPage();
      case 200: return IotPage();
      case 201: return ServerPage();
      case 202: return SmsGatewayPage();
      case 203: return TripsPage();
      case 204: return CitiesPage();
      case 205: return JuicersPage();
      case 206: return SupportPage();
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
