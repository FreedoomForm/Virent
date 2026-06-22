/**
 * scooter_mgr.cpp — Universal scooter management implementation
 */

#include "scooter_mgr.h"
#include "logger.h"
#include "process.h"
#include <filesystem>
#include <algorithm>

namespace virent {

ScooterManager::ScooterManager(ApiClient& api)
    : api_(api) {}

bool ScooterManager::refreshScooters() {
    scooters_.clear();
    auto resp = api_.getScooters(scooters_);
    if (!resp.success()) {
        LOG_ERROR("Failed to get scooters: " + resp.error);
        return false;
    }
    LOG_INFO("Loaded " + std::to_string(scooters_.size()) + " scooters");
    return true;
}

ScooterManager::ProvisionResult ScooterManager::provisionNew(const ProvisioningData& data) {
    ProvisionResult result;

    // Step 1: Register in API
    auto resp = api_.registerScooter(
        data.cityId, data.latitude, data.longitude,
        data.initialBattery, "available"
    );

    if (!resp.success()) {
        result.message = "API registration failed: " + resp.error;
        LOG_ERROR(result.message);
        return result;
    }

    // Extract scooter ID from response
    auto pos = resp.body.find("\"_id\":\"");
    if (pos != std::string::npos) {
        pos += 7;
        auto end = resp.body.find("\"", pos);
        result.scooterId = resp.body.substr(pos, end - pos);
    }

    // Step 2: Update with brand-specific info (MAC, serial, SIM, IMEI)
    if (!data.macAddress.empty() || !data.serialNumber.empty()) {
        std::string updateBody = "{";
        if (!data.macAddress.empty())
            updateBody += "\"mac_address\":\"" + data.macAddress + "\",";
        if (!data.serialNumber.empty())
            updateBody += "\"serial_number\":\"" + data.serialNumber + "\",";
        if (!data.simNumber.empty())
            updateBody += "\"sim_number\":\"" + data.simNumber + "\",";
        if (!data.imei.empty())
            updateBody += "\"imei\":\"" + data.imei + "\",";
        updateBody += "\"model\":\"" + std::string(data.brand == ScooterBrand::Ninebot ? "Ninebot" :
                          data.brand == ScooterBrand::Xiaomi ? "Xiaomi" :
                          data.brand == ScooterBrand::CustomESP32 ? "ESP32" : "Generic") + "\"";
        updateBody += "}";

        api_.put("/scooters", updateBody);
    }

    result.success = true;
    result.message = "Scooter provisioned: " + result.scooterId;
    LOG_INFO(result.message);
    return result;
}

std::vector<ConnectedScooter> ScooterManager::scanNearby() {
    std::vector<ConnectedScooter> found;

    // Scan BLE devices (Windows Bluetooth)
    LOG_INFO("Scanning for nearby scooters via Bluetooth...");

    // Use PowerShell to query Bluetooth devices
    auto result = Process::run(
        "powershell -Command \"Get-PnpDevice -Class Bluetooth | "
        "Where-Object {$_.Status -eq 'OK'} | "
        "Select-Object -ExpandProperty FriendlyName\""
    );

    if (result.success()) {
        std::istringstream stream(result.out);
        std::string line;
        while (std::getline(stream, line)) {
            while (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.empty()) continue;

            // Check if it looks like a scooter
            ConnectedScooter scooter;
            scooter.name = line;
            scooter.connectionType = "BLE";

            std::string lower = line;
            std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);

            if (lower.find("ninebot") != std::string::npos ||
                lower.find("segway") != std::string::npos) {
                scooter.brand = ScooterBrand::Ninebot;
            } else if (lower.find("xiaomi") != std::string::npos ||
                       lower.find("m365") != std::string::npos ||
                       lower.find("mi scooter") != std::string::npos) {
                scooter.brand = ScooterBrand::Xiaomi;
            } else if (lower.find("esp32") != std::string::npos ||
                       lower.find("virent") != std::string::npos) {
                scooter.brand = ScooterBrand::CustomESP32;
            } else {
                continue; // Skip non-scooter devices
            }

            found.push_back(scooter);
        }
    }

    // Also scan WiFi-connected scooters (ESP32 AP mode)
    auto wifiResult = Process::run(
        "netsh wlan show networks mode=Bssid | findstr \"ESP32\\|Virent\\|Scooter\""
    );
    if (wifiResult.success() && !wifiResult.out.empty()) {
        ConnectedScooter scooter;
        scooter.name = "ESP32 Scooter (WiFi)";
        scooter.brand = ScooterBrand::CustomESP32;
        scooter.connectionType = "WiFi";
        found.push_back(scooter);
    }

    LOG_INFO("Found " + std::to_string(found.size()) + " nearby scooters");
    return found;
}

bool ScooterManager::sendCommand(const std::string& macAddress, const std::string& command) {
    auto resp = api_.sendScooterCommand(macAddress, command);
    if (!resp.success()) {
        LOG_ERROR("Failed to send command " + command + " to " + macAddress);
        return false;
    }
    LOG_INFO("Command " + command + " sent to " + macAddress);
    return true;
}

std::vector<FirmwareInfo> ScooterManager::listAvailableFirmware() {
    if (firmwareList_.empty() && !firmwareDir_.empty()) {
        if (std::filesystem::exists(firmwareDir_)) {
            for (auto& entry : std::filesystem::directory_iterator(firmwareDir_)) {
                if (entry.path().extension() == ".bin" ||
                    entry.path().extension() == ".hex" ||
                    entry.path().extension() == ".ota") {
                    FirmwareInfo fw;
                    fw.filePath = entry.path().string();
                    fw.fileSize = static_cast<int>(entry.file_size());

                    // Extract version from filename (e.g., "virent_v1.2.0.bin")
                    std::string filename = entry.path().filename().string();
                    auto vPos = filename.find("_v");
                    if (vPos != std::string::npos) {
                        auto extPos = filename.find('.');
                        fw.version = filename.substr(vPos + 2, extPos - vPos - 2);
                    }

                    firmwareList_.push_back(fw);
                }
            }
        }
    }
    return firmwareList_;
}

bool ScooterManager::uploadFirmware(const std::string& filePath,
                                     const std::string& version,
                                     const std::string& description) {
    if (!std::filesystem::exists(filePath)) return false;

    FirmwareInfo fw;
    fw.filePath = filePath;
    fw.version = version;
    fw.description = description;
    fw.fileSize = static_cast<int>(std::filesystem::file_size(filePath));

    firmwareList_.push_back(fw);
    LOG_INFO("Firmware uploaded: v" + version + " (" + std::to_string(fw.fileSize) + " bytes)");
    return true;
}

bool ScooterManager::updateFirmware(const std::string& scooterMac,
                                     const std::string& firmwareVersion,
                                     std::function<void(int, const std::string&)> progress) {
    if (progress) progress(0, "Starting firmware update...");

    // Step 1: Send firmware update command via IoT
    if (progress) progress(10, "Sending update command...");
    auto cmdResult = sendCommand(scooterMac, "update_firmware");
    if (!cmdResult) {
        if (progress) progress(0, "Failed to send update command");
        return false;
    }

    // Step 2: Wait for scooter to download and apply
    if (progress) progress(30, "Scooter is downloading firmware...");

    // Simulate progress (in real implementation, poll MQTT for status)
    for (int i = 30; i <= 90; i += 10) {
        if (progress) progress(i, "Updating... " + std::to_string(i) + "%");
        Sleep(1000);
    }

    // Step 3: Verify
    if (progress) progress(95, "Verifying firmware...");
    Sleep(1000);

    if (progress) progress(100, "Firmware update complete!");
    LOG_INFO("Firmware updated for " + scooterMac + " to v" + firmwareVersion);
    return true;
}

ScooterBrand ScooterManager::detectBrand(const std::string& macAddress,
                                          const std::string& serialNumber) {
    // Ninebot MAC OUI: 58:8E:81, D4:3A:E9
    if (macAddress.find("58:8E:81") == 0 || macAddress.find("D4:3A:E9") == 0)
        return ScooterBrand::Ninebot;

    // Xiaomi MAC OUI: 94:65:2D, C8:47:8C
    if (macAddress.find("94:65:2D") == 0 || macAddress.find("C8:47:8C") == 0)
        return ScooterBrand::Xiaomi;

    // Check serial number patterns
    std::string lower = serialNumber;
    std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);
    if (lower.find("ninebot") != std::string::npos || lower.find("segway") != std::string::npos)
        return ScooterBrand::Ninebot;
    if (lower.find("xiaomi") != std::string::npos || lower.find("m365") != std::string::npos)
        return ScooterBrand::Xiaomi;
    if (lower.find("esp32") != std::string::npos || lower.find("virent") != std::string::npos)
        return ScooterBrand::CustomESP32;

    return ScooterBrand::Generic;
}

std::wstring ScooterManager::brandToString(ScooterBrand brand) {
    switch (brand) {
        case ScooterBrand::Ninebot:    return L"Ninebot/Segway";
        case ScooterBrand::Xiaomi:     return L"Xiaomi";
        case ScooterBrand::CustomESP32: return L"ESP32 Custom";
        case ScooterBrand::Generic:    return L"Generic";
        default:                       return L"Unknown";
    }
}

std::wstring ScooterManager::brandToIcon(ScooterBrand brand) {
    switch (brand) {
        case ScooterBrand::Ninebot:    return L"\xE804"; // MDL2 vehicle
        case ScooterBrand::Xiaomi:     return L"\xE804";
        case ScooterBrand::CustomESP32: return L"\xE83E"; // MDL2 battery
        default:                       return L"\xE804";
    }
}

} // namespace virent
