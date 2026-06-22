/// Barrel file for Virent backend data models.
///
/// Re-exports all 20 backend data models ported from the original
/// Node.js backend (`backend/v1/models/*.js`) to Dart with null safety,
/// JSON serialisation, and rich doc comments.
///
/// Import this single file from feature code:
///
/// ```dart
/// import 'package:virent/core/backend/models/models.dart';
/// ```
///
/// The models are grouped logically:
///   * **Identity & access** — Admin, AuditLog
///   * **Geography**        — City, Zone, Geofence, Discovery
///   * **Operations**       — Trip, Transaction, IoT, Upload
///   * **People**           — UserSettings, Juicer, Mechanic
///   * **Engagement**       — Notification, PromoCode, Prepaid, Support
///   * **Infrastructure**   — Sms, Stats, System
library;

export 'json_helpers.dart'
    show stringifyId, stringifyIdNullable, toInt, toDouble, asString, parseDate;

// --- Identity & access ---------------------------------------------------
export 'admin_model.dart' show AdminModel;
export 'audit_log_model.dart' show AuditLogEntry;

// --- Geography -----------------------------------------------------------
export 'city_model.dart'
    show
        CityModel,
        CityRates,
        CityScooterStatus,
        CityOverview;
export 'zone_model.dart' show ZoneModel, ZoneType, ZoneActiveHours, GeoPoint;
export 'geofence_model.dart'
    show
        GeofenceCheck,
        GeofenceCity,
        GeofenceZone,
        GeofenceSpeedPolicy;
export 'discovery_model.dart'
    show
        NearestScooter,
        NearestScooterResult,
        DiscoveryCenter,
        QrResolution,
        normalizeQrCode,
        generateQrCode,
        haversineKm;

// --- Operations ----------------------------------------------------------
export 'trip_model.dart'
    show
        TripModel,
        TripList,
        TripStatus,
        TripEndZone,
        TripCoordinates,
        TripCostBreakdown,
        CityRateSnapshot;
export 'transaction_model.dart'
    show
        TransactionModel,
        TransactionList,
        TransactionType,
        TransactionStatus,
        PaymentMethod;
export 'iot_model.dart'
    show
        IoTCommand,
        Telemetry,
        IoTEvent,
        IoTCommandStatus,
        IoTCommandKind,
        IoTEventType;
export 'upload_model.dart'
    show
        UploadModel,
        UploadList,
        UploadPurpose,
        allowedUploadMimeTypes,
        maxUploadSizeBytes;

// --- People --------------------------------------------------------------
export 'user_settings_model.dart'
    show
        UserSettings,
        UserLanguage,
        UserTheme,
        UserNotificationSettings,
        UserPrivacy;
export 'juicer_model.dart'
    show
        JuicerModel,
        JuicerTask,
        JuicerEarnings,
        JuicerStatus,
        JuicerTaskStatus,
        TaskCoordinates;
export 'mechanic_model.dart'
    show
        MechanicModel,
        MaintenanceRequest,
        PartUsed,
        PartsInventory,
        InventoryHistoryEntry,
        MechanicStatus,
        MaintenanceStatus,
        MaintenancePriority,
        SparePart;

// --- Engagement ----------------------------------------------------------
export 'notification_model.dart'
    show
        NotificationModel,
        DeviceToken,
        NotificationType,
        NotificationStatus;
export 'promo_code_model.dart'
    show
        PromoCode,
        PromoRedemption,
        PromoDiscountPreview,
        ReferralSummary,
        PromoCodeType,
        PromoCodeStatus;
export 'prepaid_model.dart' show PrepaidCard, PrepaidStatus;
export 'support_model.dart'
    show
        SupportTicket,
        TicketMessage,
        SupportTicketType,
        SupportTicketStatus,
        SupportTicketPriority,
        ProblemCategory,
        MessageAuthor;

// --- Infrastructure ------------------------------------------------------
export 'sms_model.dart'
    show
        SmsLog,
        OtpCode,
        SmsProvider,
        SmsStatus,
        normalizePhone;
export 'stats_model.dart'
    show
        Stats,
        StatsOverview,
        StatsTimeSeries,
        StatsPoint,
        FleetUtilization,
        FleetCityBucket,
        FleetSummary,
        UserSummary,
        CitySummary,
        TripSummary,
        RevenueSummary,
        StatsGranularity,
        StatsPeriod;
export 'system_model.dart'
    show
        SystemInfo,
        SystemApp,
        SystemHost,
        SystemProcess,
        SystemMemory,
        SystemDisk,
        SystemDatabase,
        SystemFeatures;
