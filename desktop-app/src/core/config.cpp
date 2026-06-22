/**
 * config.cpp — Configuration save/load implementation
 */

#include "config.h"
#include <fstream>
#include <sstream>
#include <string>

namespace virent {

// Simple key=value parser (avoids JSON library dependency)
// Lines: key=value

void AppConfig::save() {
    std::wofstream f(getConfigPath());
    if (!f.is_open()) return;

    auto w = [&](const std::wstring& key, const std::wstring& val) {
        f << key << L"=" << val << L"\n";
    };
    auto wb = [&](const std::wstring& key, bool val) {
        w(key, val ? L"true" : L"false");
    };
    auto wi = [&](const std::wstring& key, int val) {
        w(key, std::to_wstring(val));
    };

    w(L"installPath", installPath);
    w(L"dockerPath", dockerPath);
    wb(L"isFirstRun", isFirstRun);
    wb(L"autoStartOnBoot", autoStartOnBoot);
    wb(L"enableCloudflareTunnel", enableCloudflareTunnel);
    w(L"apiBaseUrl", apiBaseUrl);
    w(L"apiKey", apiKey);
    w(L"adminEmail", adminEmail);
    w(L"adminPassword", adminPassword);
    w(L"mongoUser", mongoUser);
    w(L"mongoPass", mongoPass);
    wi(L"mongoPort", mongoPort);
    wi(L"mqttPort", mqttPort);
    wb(L"darkTheme", darkTheme);
    wi(L"windowX", windowX);
    wi(L"windowY", windowY);
    wi(L"windowW", windowW);
    wi(L"windowH", windowH);
    w(L"firmwareDir", firmwareDir);
    w(L"defaultFirmwareVersion", defaultFirmwareVersion);
    w(L"appVersion", appVersion);
    f.close();
}

void AppConfig::load() {
    std::wifstream f(getConfigPath());
    if (!f.is_open()) return;

    std::wstring line;
    while (std::getline(f, line)) {
        auto pos = line.find(L'=');
        if (pos == std::wstring::npos) continue;
        std::wstring key = line.substr(0, pos);
        std::wstring val = line.substr(pos + 1);

        if (key == L"installPath") installPath = val;
        else if (key == L"dockerPath") dockerPath = val;
        else if (key == L"isFirstRun") isFirstRun = (val == L"true");
        else if (key == L"autoStartOnBoot") autoStartOnBoot = (val == L"true");
        else if (key == L"enableCloudflareTunnel") enableCloudflareTunnel = (val == L"true");
        else if (key == L"apiBaseUrl") apiBaseUrl = val;
        else if (key == L"apiKey") apiKey = val;
        else if (key == L"adminEmail") adminEmail = val;
        else if (key == L"adminPassword") adminPassword = val;
        else if (key == L"mongoUser") mongoUser = val;
        else if (key == L"mongoPass") mongoPass = val;
        else if (key == L"mongoPort") mongoPort = std::stoi(val);
        else if (key == L"mqttPort") mqttPort = std::stoi(val);
        else if (key == L"darkTheme") darkTheme = (val == L"true");
        else if (key == L"windowX") windowX = std::stoi(val);
        else if (key == L"windowY") windowY = std::stoi(val);
        else if (key == L"windowW") windowW = std::stoi(val);
        else if (key == L"windowH") windowH = std::stoi(val);
        else if (key == L"firmwareDir") firmwareDir = val;
        else if (key == L"defaultFirmwareVersion") defaultFirmwareVersion = val;
        else if (key == L"appVersion") appVersion = val;
    }
    f.close();
}

bool AppConfig::exists() {
    return std::filesystem::exists(getConfigPath());
}

} // namespace virent
