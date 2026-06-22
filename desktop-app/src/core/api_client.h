/**
 * api_client.h — HTTP client for Virent REST API
 *
 * Used by the Windows desktop app to talk to the Virent backend.
 * All admin features (former admin website) are driven through this client.
 */

#pragma once
#include <string>
#include <functional>
#include <vector>
#include <unordered_map>

namespace virent {

struct ApiResponse {
    int statusCode = 0;
    std::string body;
    std::string error;
    bool success() const { return statusCode >= 200 && statusCode < 300; }
};

struct ScooterInfo {
    std::string id;
    std::string name;
    std::string model;
    std::string status;
    double battery = 0;
    std::string macAddress;
    std::string serialNumber;
    std::string coordinates;
    std::string lastSeen;
};

struct DashboardStats {
    int totalScooters = 0;
    int availableScooters = 0;
    int inUseScooters = 0;
    int chargingScooters = 0;
    int maintenanceScooters = 0;
    int totalUsers = 0;
    int totalCities = 0;
    int tripsToday = 0;
    double revenueToday = 0;
};

/**
 * Minimal JSON value parser — enough to read API responses without
 * pulling in nlohmann/json (which complicates the Windows build).
 *
 * Usage:
 *   JsonValue v;
 *   if (v.parse(body)) {
 *     auto& data = v["data"];
 *     for (auto& item : data.array()) {
 *       std::string name = item["name"].str();
 *       int battery = item["battery"].num();
 *     }
 *   }
 */
class JsonValue {
public:
    enum class Type { Null, Bool, Number, String, Array, Object };

    JsonValue() = default;
    explicit JsonValue(Type t) : type_(t) {}

    bool parse(const std::string& src);

    Type type() const { return type_; }
    bool isNull() const { return type_ == Type::Null; }
    bool isBool() const { return type_ == Type::Bool; }
    bool isNumber() const { return type_ == Type::Number; }
    bool isString() const { return type_ == Type::String; }
    bool isArray() const { return type_ == Type::Array; }
    bool isObject() const { return type_ == Type::Object; }

    bool        asBool()   const { return boolVal_; }
    double      asNumber() const { return numVal_; }
    int         asInt()    const { return static_cast<int>(numVal_); }
    std::string asString() const { return strVal_; }
    std::wstring asWString() const;

    const std::vector<JsonValue>& array() const { return arrVal_; }
    const std::unordered_map<std::string, JsonValue>& object() const { return objVal_; }

    const JsonValue& operator[](const std::string& key) const;
    const JsonValue& operator[](size_t idx) const;

private:
    Type type_ = Type::Null;
    bool boolVal_ = false;
    double numVal_ = 0;
    std::string strVal_;
    std::vector<JsonValue> arrVal_;
    std::unordered_map<std::string, JsonValue> objVal_;

    friend class JsonParser;
    // Allow the static parse functions in api_client.cpp to access private members
    friend const char* parseString(const char*, std::string&);
    friend const char* parseObject(const char*, JsonValue&);
    friend const char* parseArray(const char*, JsonValue&);
    friend const char* parseNumber(const char*, JsonValue&);
    friend const char* parseValue(const char*, JsonValue&);
    static JsonValue null_;
};

class ApiClient {
public:
    ApiClient(const std::string& baseUrl, const std::string& apiKey,
              const std::string& email, const std::string& password);

    // Auth
    bool login();
    bool isLoggedIn() const { return !token_.empty(); }
    std::string token() const { return token_; }

    // Dashboard
    ApiResponse getDashboard(DashboardStats& outStats);
    ApiResponse getHealth();

    // Scooters
    ApiResponse getScooters(std::vector<ScooterInfo>& outScooters);
    ApiResponse getScootersJson(std::string& outJson);
    ApiResponse registerScooter(const std::string& cityId,
                                 double lat, double lng,
                                 int battery, const std::string& status);
    ApiResponse updateScooterStatus(const std::string& scooterId,
                                     const std::string& status);
    ApiResponse sendScooterCommand(const std::string& macAddress,
                                    const std::string& command);

    // Cities & Zones
    ApiResponse getCities(std::string& outJson);
    ApiResponse getCitiesOverview(std::string& outJson);
    ApiResponse getZones(std::string& outJson);

    // Customers (users)
    ApiResponse getUsers(std::string& outJson);
    ApiResponse getUsersOverview(std::string& outJson);
    ApiResponse getUserHistory(const std::string& userId, std::string& outJson);

    // Trips
    ApiResponse getTrips(std::string& outJson);
    ApiResponse getActiveTrips(std::string& outJson);
    ApiResponse getTripHistory(std::string& outJson);

    // Prepaid
    ApiResponse getPrepaids(std::string& outJson);
    ApiResponse createPrepaid(const std::string& body, std::string& outJson);
    ApiResponse updatePrepaid(const std::string& body, std::string& outJson);
    ApiResponse deletePrepaid(const std::string& prepaidId);

    // Juicers
    ApiResponse getJuicers(std::string& outJson);
    ApiResponse getJuicerTasks(std::string& outJson);

    // Support
    ApiResponse getSupportTickets(std::string& outJson);
    ApiResponse replySupportTicket(const std::string& ticketId, const std::string& message);

    // Audit log
    ApiResponse getAuditLog(std::string& outJson);

    // Analytics
    ApiResponse getStats(std::string& outJson);
    ApiResponse getMetrics(std::string& outMetrics);

    // IoT
    ApiResponse sendIoTCommand(const std::string& scooterId, const std::string& command);

    // System
    ApiResponse getSystemInfo(std::string& outJson);

    // ===== Extended admin features (admin_ext.js) =====
    ApiResponse blockUser(const std::string& userId, const std::string& reason);
    ApiResponse unblockUser(const std::string& userId);
    ApiResponse adjustUserBalance(const std::string& userId, double delta, const std::string& reason);
    ApiResponse refundTrip(const std::string& tripId, double amount, const std::string& reason);
    ApiResponse bulkGeneratePrepaids(int count, double amount, const std::string& prefix, int expiresInDays, std::string& outJson);
    ApiResponse sendNotification(const std::string& title, const std::string& body, const std::string& segment);
    ApiResponse getNotificationStats(std::string& outJson);
    ApiResponse retireScooter(const std::string& scooterId, const std::string& reason);
    ApiResponse getScooterTelemetry(const std::string& scooterId, std::string& outJson);
    ApiResponse getScooterCommands(const std::string& scooterId, std::string& outJson);
    ApiResponse closeSupportTicket(const std::string& ticketId, const std::string& resolution);
    ApiResponse reopenSupportTicket(const std::string& ticketId);
    ApiResponse assignSupportTicket(const std::string& ticketId, const std::string& assignee);
    ApiResponse getAuditLogFiltered(const std::string& actor, const std::string& action,
                                    const std::string& entity, const std::string& from,
                                    const std::string& to, std::string& outJson);

    // Generic
    ApiResponse get(const std::string& path);
    ApiResponse post(const std::string& path, const std::string& body);
    ApiResponse put(const std::string& path, const std::string& body);
    ApiResponse del(const std::string& path);

private:
    std::string baseUrl_;
    std::string apiKey_;
    std::string email_;
    std::string password_;
    std::string token_;

    ApiResponse request(const std::string& method,
                        const std::string& path,
                        const std::string& body = "",
                        bool needsAuth = true);
};

} // namespace virent
