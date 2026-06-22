/**
 * native_bridge.h — Bridge between JavaScript (in WebView2) and native C++.
 *
 * JavaScript calls:
 *   window.chrome.webview.postMessage('docker.status')
 *   window.chrome.webview.postMessage('iot.sendCommand|AA:BB:CC:DD:01:10|lock')
 *
 * C++ responds via WebViewHost::postJson(). The response is a JSON string.
 *
 * Supported methods:
 *   docker.status       — get container statuses
 *   docker.start        — start all containers
 *   docker.stop         — stop all containers
 *   docker.restart      — restart all containers
 *   docker.rebuild      — rebuild all images
 *   docker.logs         — get container logs
 *   docker.backup       — backup MongoDB
 *   docker.restore      — restore MongoDB from backup file
 *
 *   iot.sendCommand     — send command to scooter via REST API
 *   iot.scanBluetooth   — scan for nearby BLE scooters (stub)
 *
 *   shell.exec          — run a shell command (admin only, sandboxed)
 *   shell.openUrl       — open URL in default browser
 *   shell.openFile      — open file dialog, return path
 *
 *   fs.readFile         — read a text file
 *   fs.writeFile        — write a text file
 *   fs.listBackups      — list MongoDB backup files
 *
 *   api.get             — proxy GET to REST API (uses C++'s API client,
 *                         bypasses CORS issues)
 *   api.post            — proxy POST to REST API
 *
 *   app.getVersion      — get app version
 *   app.getConfigDir    — get config directory path
 */

#pragma once
#include <string>
#include <functional>

namespace virent {

class Docker;
class ApiClient;
struct AppConfig;

class NativeBridge {
public:
    // Callback for sending progress messages back to JavaScript during long
    // operations (e.g. APK download). The callback receives a JSON string
    // that the WebView host forwards to JS via postJson().
    using ProgressCallback = std::function<void(const std::string& json)>;

    NativeBridge(Docker* docker, ApiClient* api, AppConfig* config);

    // Set the progress callback — used by App to bridge to WebViewHost::postJson.
    void setProgressCallback(ProgressCallback cb) { progressCb_ = std::move(cb); }

    // Handle a message from JavaScript.
    // Format: "method" or "method|arg1|arg2|..."
    // Returns a JSON response string (or empty string for no response).
    std::string handle(const std::string& method, const std::string& payload);

private:
    Docker* docker_;
    ApiClient* api_;
    AppConfig* config_;
    ProgressCallback progressCb_;

    // Method handlers — each returns a JSON response string
    std::string handleDocker(const std::string& action, const std::string& payload);
    std::string handleIot(const std::string& action, const std::string& payload);
    std::string handleShell(const std::string& action, const std::string& payload);
    std::string handleFs(const std::string& action, const std::string& payload);
    std::string handleApi(const std::string& action, const std::string& payload);
    std::string handleApp(const std::string& action, const std::string& payload);
    std::string handleApk(const std::string& action, const std::string& payload);

    // Helpers
    static std::string jsonEscape(const std::string& s);
    static std::string splitField(const std::string& payload, size_t index);
};

} // namespace virent
