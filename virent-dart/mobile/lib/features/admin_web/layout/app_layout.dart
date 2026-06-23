import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ngrok_tunnel_service.dart';
import '../../../main.dart';
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
          // ── Server status bar ──
          const _ServerStatusBar(),
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
      case 0: return const DashboardPage();
      case 1: return const StatisticsPage();
      case 2: return const AlertsPage();
      case 30: return const MapPage();
      case 4: return const ScootersPage();
      case 5: return const PushHistoryPage();
      case 6: return const PrepaidOrdersPage();
      case 7: return const SelfiesPage();
      case 8: return const InspectionDamagesPage();
      case 9: return const BillingDebtsPage();
      case 90: return const FinesPage();
      case 91: return const BillingReceiptsPage();
      case 10: return const PromoCodesPage();
      case 11: return const BonusesPage();
      case 12: return const TariffAbonementsPage();
      case 120: return const TariffsPage();
      case 121: return const TariffPricesPage();
      case 122: return const TariffSubTariffsPage();
      case 124: return const TariffsSubscriptionsPage();
      case 123: return const TariffUntilDeadPage();
      case 13: return const HoldLogsPage();
      case 130: return const LogsTelemetryPage();
      case 133: return const LogsUnconfirmedPage();
      case 134: return const LogsPaymentsPage();
      case 136: return const LogsScooterChangesPage();
      case 137: return const LogsClientChangesPage();
      case 20: return const SmsLogsPage();
      case 14: return const AdminRolesPage();
      case 140: return const AdminPermissionsPage();
      case 142: return const AdminAgreementsPage();
      case 144: return const AdminFaqPage();
      case 145: return const AdminCompaniesPage();
      case 147: return const AdminContactsPage();
      case 15: return const TechniciansPage();
      case 151: return const TaskTechniciansPage();
      case 153: return const TechFeedbackPage();
      case 16: return const GeozonesPage();
      case 17: return const ClientGroupsPage();
      case 100: return const PaymeTransactionsPage();
      case 101: return const ClickTransactionsPage();
      case 170: return const SettingsNotificationsPage();
      case 171: return const SettingsConfigPage();
      case 172: return const SettingsScooterGroupsPage();
      case 173: return const SettingsDriversPage();
      case 18:
      case 19: return const ChatLogsPage();
      case 111: return const PromoSeriesPage();
      // Extra pages (not in mockup)
      case 3: return const MapPage();
      case 60: return const BulkPrepaidPage();
      case 1620: return const PushComposerPage();
      case 1332: return const ScooterDetailPage();
      case 200: return const IotPage();
      case 201: return const ServerPage();
      case 202: return const SmsGatewayPage();
      case 203: return const TripsPage();
      case 204: return const CitiesPage();
      case 205: return const JuicersPage();
      case 206: return const SupportPage();
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
