/**
 * webview_host.cpp — WebView2 COM implementation
 *
 * This is the bridge between native C++ and the HTML admin UI.
 *
 * Architecture:
 *
 *   +-------------------+      Win32 message loop      +-------------------+
 *   |   C++ App class   |  <--------------------------> |  WebView2 (Edge)  |
 *   |                   |                               |                   |
 *   |  - Docker CLI     |  postJson (C++ -> JS)         |  - HTML/CSS UI    |
 *   |  - MQTT broker    |  message event (JS -> C++)    |  - JS app.js      |
 *   |  - File system    |  executeScript                |  - fetch() REST   |
 *   |  - Shell exec     |                               |                   |
 *   +-------------------+                               +-------------------+
 *                                                              |
 *                                                              v
 *                                                       REST API :8393
 *
 * Build setup:
 *   CMakeLists.txt uses FetchContent to pull the WebView2 SDK from nuget at
 *   build time. The header is at build/_deps/webview2-src/include/WebView2.h
 *   and the loader lib is at build/_deps/webview2-src/lib/WebView2Loader.dll.lib
 *
 * Runtime requirements:
 *   - Windows 10 1809+ (Win11 has it preinstalled)
 *   - WebView2 Runtime (Evergreen): https://developer.microsoft.com/microsoft-edge/webview2/
 *
 * Note: this file is compiled ONLY on Windows. On Linux/macOS the WebViewHost
 * class exists as a stub returning false from initialize().
 */

#include "webview_host.h"
#include "logger.h"
#include <objbase.h>
#include <string>
#include <algorithm>

#ifdef _WIN32
// WebView2 headers — vendored via CMake FetchContent
#include <WebView2.h>
#include <WebView2EnvironmentOptions.h>
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleaut32.lib")
#endif

namespace virent {

WebViewHost::WebViewHost() {}

WebViewHost::~WebViewHost() {
#ifdef _WIN32
    if (webview_)    reinterpret_cast<IUnknown*>(webview_)->Release();
    if (controller_) reinterpret_cast<IUnknown*>(controller_)->Release();
    if (environment_) reinterpret_cast<IUnknown*>(environment_)->Release();
#endif
}

// ===== COM event handler interfaces (only compiled on Windows) =====
#ifdef _WIN32

// Handler: environment created -> create controller
class EnvironmentCreatedHandler : public ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler {
public:
    WebViewHost* host;
    ULONG refCount = 1;

    EnvironmentCreatedHandler(WebViewHost* h) : host(h) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler)) {
            *ppv = static_cast<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refCount); }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG c = InterlockedDecrement(&refCount);
        if (c == 0) delete this;
        return c;
    }
    HRESULT STDMETHODCALLTYPE Invoke(HRESULT hr, ICoreWebView2Environment* env) override {
        if (SUCCEEDED(hr) && env) {
            host->onEnvironmentCreated(env);
        } else {
            LOG_ERROR("WebView2 environment creation failed: HR=" + std::to_string(hr));
        }
        return S_OK;
    }
};

// Handler: controller created -> get webview, set up message handler, navigate
class ControllerCreatedHandler : public ICoreWebView2CreateCoreWebView2ControllerCompletedHandler {
public:
    WebViewHost* host;
    std::wstring initialUrl;
    ULONG refCount = 1;

    ControllerCreatedHandler(WebViewHost* h, const std::wstring& url) : host(h), initialUrl(url) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(ICoreWebView2CreateCoreWebView2ControllerCompletedHandler)) {
            *ppv = static_cast<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refCount); }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG c = InterlockedDecrement(&refCount);
        if (c == 0) delete this;
        return c;
    }
    HRESULT STDMETHODCALLTYPE Invoke(HRESULT hr, ICoreWebView2Controller* controller) override {
        if (SUCCEEDED(hr) && controller) {
            host->onControllerCreated(controller);
            host->navigate(initialUrl);
        } else {
            LOG_ERROR("WebView2 controller creation failed: HR=" + std::to_string(hr));
        }
        return S_OK;
    }
};

// Handler: message received from JavaScript
class MessageReceivedHandler : public ICoreWebView2WebMessageReceivedEventHandler {
public:
    WebViewHost* host;
    ULONG refCount = 1;

    MessageReceivedHandler(WebViewHost* h) : host(h) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(ICoreWebView2WebMessageReceivedEventHandler)) {
            *ppv = static_cast<ICoreWebView2WebMessageReceivedEventHandler*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refCount); }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG c = InterlockedDecrement(&refCount);
        if (c == 0) delete this;
        return c;
    }
    HRESULT STDMETHODCALLTYPE Invoke(ICoreWebView2* sender, ICoreWebView2WebMessageReceivedEventArgs* args) override {
        if (!args) return S_OK;
        LPWSTR raw = nullptr;
        args->TryGetWebMessageAsString(&raw);
        if (raw) {
            host->onMessageReceived(raw);
            CoTaskMemFree(raw);
        }
        return S_OK;
    }
};

// Handler: navigation completed
class NavigationCompletedHandler : public ICoreWebView2NavigationCompletedEventHandler {
public:
    WebViewHost* host;
    ULONG refCount = 1;
    NavigationCompletedHandler(WebViewHost* h) : host(h) {}
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(ICoreWebView2NavigationCompletedEventHandler)) {
            *ppv = static_cast<ICoreWebView2NavigationCompletedEventHandler*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refCount); }
    ULONG STDMETHODCALLTYPE Release() override {
        ULONG c = InterlockedDecrement(&refCount);
        if (c == 0) delete this;
        return c;
    }
    HRESULT STDMETHODCALLTYPE Invoke(ICoreWebView2* sender, ICoreWebView2NavigationCompletedEventArgs* args) override {
        host->onNavigationCompleted();
        return S_OK;
    }
};

#endif // _WIN32

// ===== Public API =====

bool WebViewHost::initialize(HWND parentHwnd, const std::wstring& userDataFolder) {
    parent_ = parentHwnd;
#ifdef _WIN32
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
        LOG_ERROR("CoInitializeEx failed: " + std::to_string(hr));
        return false;
    }

    // Create the WebView2 environment. This will trigger the async creation
    // of the controller, which then triggers navigation to the URL.
    auto* handler = new EnvironmentCreatedHandler(this);
    hr = CreateCoreWebView2EnvironmentWithOptions(
        nullptr,  // use installed Evergreen runtime
        userDataFolder.c_str(),
        nullptr,  // no environment options
        handler);
    if (FAILED(hr)) {
        LOG_ERROR("CreateCoreWebView2EnvironmentWithOptions failed: " + std::to_string(hr) +
                  ". Is the WebView2 Runtime installed? Get it from "
                  "https://developer.microsoft.com/microsoft-edge/webview2/");
        handler->Release();
        return false;
    }
    LOG_INFO("WebView2 environment creation requested");
    return true;
#else
    LOG_ERROR("WebView2 is only available on Windows");
    return false;
#endif
}

void WebViewHost::navigate(const std::wstring& url) {
#ifdef _WIN32
    if (!webview_) return;
    auto* wv = static_cast<ICoreWebView2*>(webview_);
    wv->Navigate(url.c_str());
    LOG_INFO("WebView2 navigating to: " + std::string(url.begin(), url.end()));
#endif
}

void WebViewHost::resize() {
#ifdef _WIN32
    if (!controller_ || !parent_) return;
    RECT bounds;
    GetClientRect(parent_, &bounds);
    auto* ctrl = static_cast<ICoreWebView2Controller*>(controller_);
    ctrl->put_Bounds(bounds);
#endif
}

void WebViewHost::setMessageHandler(MessageHandler handler) {
    handler_ = std::move(handler);
}

void WebViewHost::postJson(const std::string& json) {
#ifdef _WIN32
    if (!webview_) return;
    auto* wv = static_cast<ICoreWebView2*>(webview_);
    std::wstring wjson(json.begin(), json.end());
    wv->PostWebMessageAsString(wjson.c_str());
#endif
}

void WebViewHost::executeScript(const std::string& js) {
#ifdef _WIN32
    if (!webview_) return;
    auto* wv = static_cast<ICoreWebView2*>(webview_);
    std::wstring wjs(js.begin(), js.end());
    wv->ExecuteScript(wjs.c_str(), nullptr);
#endif
}

// ===== Internal callbacks (only meaningful on Windows) =====

#ifdef _WIN32
void WebViewHost::onEnvironmentCreated(void* environment) {
    environment_ = environment;
    auto* env = static_cast<ICoreWebView2Environment*>(environment);
    env->AddRef();

    // Now create the controller bound to our parent window
    // The URL to navigate to is stashed in the handler — but we read it back
    // from a member because the constructor was already called without it.
    // For simplicity, we navigate after controller is ready (see onControllerCreated).
    auto* handler = new ControllerCreatedHandler(this, L"about:blank");
    env->CreateCoreWebView2Controller(parent_, handler);
}

void WebViewHost::onControllerCreated(void* controller) {
    controller_ = controller;
    auto* ctrl = static_cast<ICoreWebView2Controller*>(controller);
    ctrl->AddRef();

    // Get the ICoreWebView2 from the controller
    ICoreWebView2* wv = nullptr;
    ctrl->get_CoreWebView2(&wv);
    if (!wv) {
        LOG_ERROR("Failed to get ICoreWebView2 from controller");
        return;
    }
    webview_ = wv;

    // Size to fill parent
    resize();

    // Register message handler
    auto* msgHandler = new MessageReceivedHandler(this);
    wv->add_WebMessageReceived(msgHandler, nullptr);
    msgHandler->Release();

    // Register navigation completed handler
    auto* navHandler = new NavigationCompletedHandler(this);
    wv->add_NavigationCompleted(navHandler, nullptr);
    navHandler->Release();

    controllerReady_ = true;
    LOG_INFO("WebView2 controller ready");
}

void WebViewHost::onNavigationCompleted() {
    LOG_INFO("WebView2 navigation completed");
}

void WebViewHost::onMessageReceived(const std::wstring& raw) {
    if (!handler_) return;
    std::string utf8;
    utf8.reserve(raw.size());
    for (wchar_t wc : raw) {
        if (wc < 0x80) utf8 += static_cast<char>(wc);
        else if (wc < 0x800) {
            utf8 += static_cast<char>(0xC0 | (wc >> 6));
            utf8 += static_cast<char>(0x80 | (wc & 0x3F));
        } else {
            utf8 += static_cast<char>(0xE0 | (wc >> 12));
            utf8 += static_cast<char>(0x80 | ((wc >> 6) & 0x3F));
            utf8 += static_cast<char>(0x80 | (wc & 0x3F));
        }
    }
    // Parse "METHOD|payload" format
    auto sep = utf8.find('|');
    std::string method = (sep == std::string::npos) ? utf8 : utf8.substr(0, sep);
    std::string payload = (sep == std::string::npos) ? "" : utf8.substr(sep + 1);
    std::string response = handler_(method, payload);
    if (!response.empty()) {
        postJson(response);
    }
}
#endif

} // namespace virent
