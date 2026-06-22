/**
 * config.h — Configuration management for Virent Control Center
 *
 * Persists settings to %APPDATA%/VirentControlCenter/config.json
 * Per constitution: settings should be versioned and portable
 */

#pragma once
#include <string>
#include <filesystem>

namespace virent {

struct AppConfig {
    // Installation
    std::wstring installPath;         // e.g. L"C:\\Virent"
    std::wstring dockerPath;          // docker-compose.exe path
    bool isFirstRun = true;
    bool autoStartOnBoot = false;
    bool enableCloudflareTunnel = false;

    // Server connection
    std::wstring apiBaseUrl = L"http://localhost:8393/v1";
    std::wstring apiKey = L"admin_api_key_for_dashboard_2024";
    std::wstring adminEmail = L"admin@sparkrentals.local";
    std::wstring adminPassword = L"Admin123!";

    // Database
    std::wstring mongoUser = L"virent";
    std::wstring mongoPass = L"virent_secret_2024";
    int mongoPort = 27017;

    // MQTT
    int mqttPort = 1883;

    // UI
    bool darkTheme = true;
    int windowX = 100;
    int windowY = 100;
    int windowW = 1200;
    int windowH = 800;

    // Scooter firmware
    std::wstring firmwareDir;         // Path to firmware files
    std::wstring defaultFirmwareVersion = L"1.0.0";

    // Version
    std::wstring appVersion = L"1.0.0";

    // Get config file path
    static std::wstring getConfigDir() {
        wchar_t* appdata = nullptr;
        _wdupenv_s(&appdata, nullptr, L"APPDATA");
        if (!appdata) return L".";
        std::wstring dir = std::wstring(appdata) + L"\\VirentControlCenter";
        free(appdata);
        std::filesystem::create_directories(dir);
        return dir;
    }

    static std::wstring getConfigPath() {
        return getConfigDir() + L"\\config.json";
    }

    // Save/Load (simple JSON-like format)
    void save();
    void load();
    bool exists();
};

} // namespace virent
