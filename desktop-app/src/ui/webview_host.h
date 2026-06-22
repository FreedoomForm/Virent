/**
 * webview_host.h — Embedded WebView2 renderer for Virent Control Center
 *
 * Renders the admin web UI (desktop-app/web-ui/index.html) inside the C++ app
 * window using Microsoft Edge WebView2 runtime. Provides a native bridge so
 * JavaScript can call C++ functions for: Docker management, IoT device I/O,
 * file system access (logs, backups), and shell commands.
 *
 * Why this design:
 *   - C++ keeps full control over: Docker CLI, MQTT broker, serial ports,
 *     Bluetooth, file system, Windows services
 *   - HTML/CSS/JS renders the entire UI (matches BarqScoot mockups 1:1)
 *   - The two halves talk via a typed JSON-RPC bridge over PostWebMessageAsJson
 *
 * Build requirements:
 *   - Windows 10/11 (WebView2 runtime ships with Win11 by default)
 *   - Visual Studio 2022 with C++ workload
 *   - CMake 3.20+
 *   - Internet on first build (FetchContent downloads WebView2 SDK from nuget)
 */

#pragma once
#include <windows.h>
#include <string>
#include <functional>
#include <memory>

namespace virent {

class WebViewHost {
public:
    using MessageHandler = std::function<std::string(const std::string& method,
                                                      const std::string& payload)>;

    WebViewHost();
    ~WebViewHost();

    // Initialize WebView2 inside the given parent window.
    // Returns true on success. The webview is sized to fill the parent's client area.
    bool initialize(HWND parentHwnd, const std::wstring& userDataFolder);

    // Navigate to a URL (file:// or http://).
    void navigate(const std::wstring& url);

    // Resize the webview to fill the parent window's client area.
    void resize();

    // Register a handler for messages from JavaScript.
    // JS calls: window.chrome.webview.postMessage(JSON.stringify({method, payload}))
    // C++ responds via postJson().
    void setMessageHandler(MessageHandler handler);

    // Send a JSON message to JavaScript.
    // JS receives: window.chrome.webview.addEventListener('message', e => ...)
    void postJson(const std::string& json);

    // Inject a JavaScript snippet to run in the page context.
    void executeScript(const std::string& js);

    // True if the WebView2 controller is ready.
    bool isReady() const { return controllerReady_; }

    // Internal COM event handlers (public so the COM callback classes in .cpp can call them)
    void onEnvironmentCreated(void* environment);
    void onControllerCreated(void* controller);
    void onNavigationCompleted();
    void onMessageReceived(const std::wstring& raw);

private:
    HWND parent_ = nullptr;
    void* environment_  = nullptr;  // ICoreWebView2Environment*
    void* controller_   = nullptr;  // ICoreWebView2Controller*
    void* webview_      = nullptr;  // ICoreWebView2*
    bool  controllerReady_ = false;
    MessageHandler handler_;
};

} // namespace virent
