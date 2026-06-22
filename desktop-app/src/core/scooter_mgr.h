/**
 * scooter_mgr.h — Universal scooter management
 *
 * Supports ALL scooter brands via:
 * 1. REST API (for registered scooters)
 * 2. MQTT (for real-time telemetry)
 * 3. BLE (for direct connection during provisioning)
 * 4. Serial/USB (for firmware updates)
 *
 * Universal protocol abstraction:
 * - Ninebot/Segway: BLE + MQTT
 * - Xiaomi: BLE (py9b protocol)
 * - Custom ESP32: MQTT + OTA
 * - Generic: REST API polling
 */

#pragma once
#include <string>
#include <vector>
#include <functional>
#include "api_client.h"

namespace virent {

// Supported scooter brands
enum class ScooterBrand {
    Ninebot,       // Segway-Ninebot MAX G30, ES4, etc.
    Xiaomi,        // Xiaomi Pro 2, 1S, Mi3
    CustomESP32,   // Custom ESP32-based controller
    Generic,       // Any REST API compatible
    Unknown
};

// Scooter firmware info
struct FirmwareInfo {
    std::string version;
    std::string filePath;
    std::string description;
    std::string compatibleBrands;
    int fileSize = 0;
    std::string checksum;
};

// Connected scooter (for provisioning/firmware update)
struct ConnectedScooter {
    std::string id;
    std::string name;
    ScooterBrand brand = ScooterBrand::Unknown;
    std::string macAddress;
    std::string ipAddress;
    std::string serialNumber;
    std::string firmwareVersion;
    int batteryLevel = 0;
    bool isOnline = false;
    std::string connectionType;  // "BLE", "MQTT", "USB", "WiFi"
};

// Scooter provisioning data
struct ProvisioningData {
    std::string cityId;
    std::string serialNumber;
    std::string macAddress;
    ScooterBrand brand;
    double latitude = 0;
    double longitude = 0;
    int initialBattery = 100;
    std::string simNumber;
    std::string imei;
};

class ScooterManager {
public:
    ScooterManager(ApiClient& api);

    // Get all scooters from API
    bool refreshScooters();
    const std::vector<ScooterInfo>& getScooters() const { return scooters_; }

    // Provision a new scooter (universal — works with any brand)
    struct ProvisionResult {
        bool success = false;
        std::string scooterId;
        std::string message;
    };
    ProvisionResult provisionNew(const ProvisioningData& data);

    // Scan for nearby scooters (BLE/USB/WiFi)
    std::vector<ConnectedScooter> scanNearby();

    // Send command to scooter
    bool sendCommand(const std::string& macAddress, const std::string& command);

    // Firmware management
    std::vector<FirmwareInfo> listAvailableFirmware();
    bool uploadFirmware(const std::string& filePath, const std::string& version,
                        const std::string& description);
    bool updateFirmware(const std::string& scooterMac,
                        const std::string& firmwareVersion,
                        std::function<void(int percent, const std::string& status)> progress);

    // Brand detection
    static ScooterBrand detectBrand(const std::string& macAddress,
                                     const std::string& serialNumber);
    static std::wstring brandToString(ScooterBrand brand);
    static std::wstring brandToIcon(ScooterBrand brand);

private:
    ApiClient& api_;
    std::vector<ScooterInfo> scooters_;
    std::vector<FirmwareInfo> firmwareList_;
    std::string firmwareDir_;
};

} // namespace virent
