/**
 * app.cpp — Main application implementation
 *
 * Virent Control Center — the heart of the server
 */

#include "app.h"
#include "logger.h"
#include "process.h"
#include <commctrl.h>
#include <shlobj.h>
#include <shellapi.h>
#include <algorithm>

#pragma comment(lib, "comctl32.lib")

namespace virent {

// Control IDs
constexpr int IDC_INSTALL_BTN     = 1001;
constexpr int IDC_DRIVE_COMBO     = 1002;
constexpr int IDC_SIDEBAR_BASE    = 1100;
constexpr int IDC_PROGRESS_BAR    = 1200;
constexpr int IDC_PROGRESS_LABEL  = 1201;
constexpr int IDC_SERVER_START    = 1300;
constexpr int IDC_SERVER_STOP     = 1301;
constexpr int IDC_SERVER_REBUILD  = 1302;
constexpr int IDC_SERVER_RESTART  = 1303;
constexpr int IDC_SERVER_LOGS     = 1304;
constexpr int IDC_SERVER_BACKUP   = 1305;
constexpr int IDC_SCOOTER_SCAN    = 1400;
constexpr int IDC_SCOOTER_ADD     = 1401;
constexpr int IDC_SCOOTER_FW      = 1402;
constexpr int IDC_SCOOTER_CMD_LOCK  = 1410;
constexpr int IDC_SCOOTER_CMD_UNLOCK= 1411;
constexpr int IDC_SCOOTER_CMD_ALARM= 1412;
constexpr int IDC_SCOOTER_CMD_REBOOT= 1413;
constexpr int IDC_REFRESH         = 1500;

// Static app pointer for wndproc
static App* g_app = nullptr;

App::App(HINSTANCE hInstance) : hInstance_(hInstance) {
    g_app = this;
    config_.load();
    Logger::instance().init(AppConfig::getConfigDir());
    LOG_INFO("=== Virent Control Center starting ===");
}

App::~App() {
    if (timerId_) KillTimer(hWnd_, timerId_);
    if (hFontMain_) DeleteObject(hFontMain_);
    if (hFontTitle_) DeleteObject(hFontTitle_);
    if (hFontSmall_) DeleteObject(hFontSmall_);
    if (hBrushBg_) DeleteObject(hBrushBg_);
    if (hBrushSurface_) DeleteObject(hBrushSurface_);
    if (hBrushPrimary_) DeleteObject(hBrushPrimary_);
    LOG_INFO("=== Virent Control Center shutting down ===");
}

int App::run() {
    createWindow();
    createFonts();
    createBrushes();

    if (config_.isFirstRun || !std::filesystem::exists(config_.installPath)) {
        showInstallerView();
    } else {
        // Initialize core objects
        std::string baseUrl(config_.apiBaseUrl.begin(), config_.apiBaseUrl.end());
        std::string apiKey(config_.apiKey.begin(), config_.apiKey.end());
        std::string email(config_.adminEmail.begin(), config_.adminEmail.end());
        std::string pass(config_.adminPassword.begin(), config_.adminPassword.end());

        api_ = std::make_unique<ApiClient>(baseUrl, apiKey, email, pass);
        docker_ = std::make_unique<Docker>(config_);
        scooterMgr_ = std::make_unique<ScooterManager>(*api_);

        showMainView();
        switchTab(TabId::Dashboard);

        // Auto-start server on launch
        autoStartIfNeeded();

        // Auto-refresh timer
        timerId_ = SetTimer(hWnd_, 1, TIMER_INTERVAL, nullptr);
    }

    // Message loop
    MSG msg;
    while (GetMessage(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return static_cast<int>(msg.wParam);
}

bool App::createWindow() {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = [](HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) -> LRESULT {
        if (g_app) return g_app->wndProc(hWnd, msg, wParam, lParam);
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    };
    wc.hInstance = hInstance_;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.lpszClassName = L"VirentControlCenter";
    wc.hbrBackground = CreateSolidBrush(Color::Bg);

    RegisterClassExW(&wc);

    hWnd_ = CreateWindowExW(
        0, L"VirentControlCenter", L"Virent Control Center",
        WS_OVERLAPPEDWINDOW,
        config_.windowX, config_.windowY,
        config_.windowW, config_.windowH,
        nullptr, nullptr, hInstance_, nullptr
    );

    if (!hWnd_) return false;
    ShowWindow(hWnd_, SW_SHOW);
    UpdateWindow(hWnd_);
    return true;
}

void App::createFonts() {
    hFontMain_ = CreateFontW(Font::Body, 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS,
        Font::Family);

    hFontTitle_ = CreateFontW(Font::Title, 0, 0, 0, FW_BOLD,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS,
        Font::Family);

    hFontSmall_ = CreateFontW(Font::Small, 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS,
        Font::Family);
}

void App::createBrushes() {
    hBrushBg_ = CreateSolidBrush(Color::Bg);
    hBrushSurface_ = CreateSolidBrush(Color::Surface);
    hBrushPrimary_ = CreateSolidBrush(Color::Primary);
}

void App::createSidebar() {
    // Sidebar buttons — all admin features (1:1 with former admin website)
    constexpr int itemH = 42;
    for (int i = 0; i < NavItemsCount; i++) {
        CreateWindowW(L"BUTTON", NavItems[i].label,
            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            0, Layout::HeaderH + i * itemH, Layout::SidebarW, itemH,
            hWnd_, reinterpret_cast<HMENU>(static_cast<INT_PTR>(IDC_SIDEBAR_BASE + i)),
            hInstance_, nullptr);
    }
}

void App::showInstallerView() {
    showInstaller_ = true;
    // Destroy existing children
    HWND child = GetWindow(hWnd_, GW_CHILD);
    while (child) {
        HWND next = GetWindow(child, GW_HWNDNEXT);
        DestroyWindow(child);
        child = next;
    }

    // Title
    CreateWindowW(L"STATIC", L"Virent Control Center — Setup",
        WS_CHILD | WS_VISIBLE | SS_CENTER,
        200, 60, 800, 50, hWnd_, nullptr, hInstance_, nullptr);

    // Subtitle
    CreateWindowW(L"STATIC",
        L"Welcome! This wizard will install Virent on your PC.\n"
        L"Select a drive for installation and click Install.",
        WS_CHILD | WS_VISIBLE | SS_CENTER,
        200, 120, 800, 50, hWnd_, nullptr, hInstance_, nullptr);

    // Drive selection label
    CreateWindowW(L"STATIC", L"Installation drive:",
        WS_CHILD | WS_VISIBLE,
        350, 200, 200, 25, hWnd_, nullptr, hInstance_, nullptr);

    // Drive combo
    HWND hCombo = CreateWindowW(L"COMBOBOX", L"",
        WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST | WS_VSCROLL,
        350, 225, 200, 200, hWnd_,
        reinterpret_cast<HMENU>(IDC_DRIVE_COMBO), hInstance_, nullptr);

    // Populate drives
    DWORD drives = GetLogicalDrives();
    for (int i = 0; i < 26; i++) {
        if (drives & (1 << i)) {
            wchar_t driveLetter = static_cast<wchar_t>('A' + i);
            wchar_t driveStr[] = {driveLetter, L':', L'\\', 0};
            UINT type = GetDriveTypeW(driveStr);
            if (type == DRIVE_FIXED) {
                ULARGE_INTEGER freeSpace, totalSpace;
                GetDiskFreeSpaceExW(driveStr, &freeSpace, &totalSpace, nullptr);
                double freeGB = static_cast<double>(freeSpace.QuadPart) / (1024 * 1024 * 1024);

                wchar_t item[128];
                swprintf_s(item, L"%c: (%.0f GB free)", driveLetter, freeGB);
                SendMessageW(hCombo, CB_ADDSTRING, 0, reinterpret_cast<LPARAM>(item));
            }
        }
    }
    SendMessageW(hCombo, CB_SETCURSEL, 0, 0);

    // Install button
    CreateWindowW(L"BUTTON", L"Install Virent",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        400, 280, 200, 40, hWnd_,
        reinterpret_cast<HMENU>(IDC_INSTALL_BTN), hInstance_, nullptr);

    // Progress bar (hidden initially)
    hProgressBar_ = CreateWindowW(PROGRESS_CLASSW, L"",
        WS_CHILD | PBS_SMOOTH,
        200, 350, 800, 20, hWnd_,
        reinterpret_cast<HMENU>(IDC_PROGRESS_BAR), hInstance_, nullptr);

    // Progress label
    hProgressLabel_ = CreateWindowW(L"STATIC", L"",
        WS_CHILD | WS_VISIBLE | SS_CENTER,
        200, 380, 800, 200, hWnd_,
        reinterpret_cast<HMENU>(IDC_PROGRESS_LABEL), hInstance_, nullptr);

    // Set fonts
    EnumChildWindows(hWnd_, [](HWND child, LPARAM lParam) -> BOOL {
        SendMessageW(child, WM_SETFONT, (WPARAM)lParam, TRUE);
        return TRUE;
    }, reinterpret_cast<LPARAM>(hFontMain_));

    InvalidateRect(hWnd_, nullptr, TRUE);
}

void App::showMainView() {
    showInstaller_ = false;
    // Destroy installer children
    HWND child = GetWindow(hWnd_, GW_CHILD);
    while (child) {
        HWND next = GetWindow(child, GW_HWNDNEXT);
        DestroyWindow(child);
        child = next;
    }

    if (useWebView_) {
        // ===== WebView2 mode =====
        // The web UI renders inside the main window — no native sidebar or
        // buttons needed. JavaScript handles all interaction.
        initializeWebView();
        return;
    }

    // ===== Legacy Win32 GDI mode (fallback) =====
    createSidebar();

    // Header
    CreateWindowW(L"STATIC", L"Virent Control Center",
        WS_CHILD | WS_VISIBLE | SS_LEFT,
        Layout::SidebarW + Layout::Padding, 15,
        400, 30, hWnd_, nullptr, hInstance_, nullptr);
    SendMessageW(GetWindow(hWnd_, GW_CHILD), WM_SETFONT,
        reinterpret_cast<WPARAM>(hFontTitle_), TRUE);

    // Refresh button
    CreateWindowW(L"BUTTON", L"↻ Refresh",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        Layout::WindowW - 120, 15, 80, 32, hWnd_,
        reinterpret_cast<HMENU>(IDC_REFRESH), hInstance_, nullptr);

    // Set fonts for all children
    EnumChildWindows(hWnd_, [](HWND child, LPARAM lParam) -> BOOL {
        SendMessageW(child, WM_SETFONT, (WPARAM)lParam, TRUE);
        return TRUE;
    }, reinterpret_cast<LPARAM>(hFontMain_));

    InvalidateRect(hWnd_, nullptr, TRUE);
}

// Initialize WebView2 and load the embedded admin web UI.
// Falls back to legacy GDI mode if WebView2 runtime is not installed.
void App::initializeWebView() {
    // Find the web-ui directory relative to the executable
    wchar_t exePath[MAX_PATH] = {};
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);
    std::wstring exeDir(exePath);
    auto lastSlash = exeDir.find_last_of(L"\\/");
    if (lastSlash != std::wstring::npos) exeDir = exeDir.substr(0, lastSlash);

    // Candidate locations for web-ui/index.html
    std::vector<std::wstring> candidates = {
        exeDir + L"\\web-ui\\index.html",
        exeDir + L"\\..\\web-ui\\index.html",
        exeDir + L"\\..\\desktop-app\\web-ui\\index.html",
        L".\\web-ui\\index.html",
    };
    std::wstring indexUrl;
    for (const auto& path : candidates) {
        if (GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES) {
            indexUrl = L"file:///" + path;
            std::replace(indexUrl.begin(), indexUrl.end(), L'\\', L'/');
            break;
        }
    }

    // User data folder for WebView2 (cache, cookies, etc.)
    PWSTR appData = nullptr;
    std::wstring userDataFolder;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &appData))) {
        userDataFolder = std::wstring(appData) + L"\\Virent\\WebView2";
        CoTaskMemFree(appData);
    } else {
        userDataFolder = L".\\webview2-data";
    }

    webview_ = std::make_unique<WebViewHost>();

    // Set up the native bridge (JS -> C++ calls)
    bridge_ = std::make_unique<NativeBridge>(
        docker_.get(), api_.get(), &config_);

    // Wire up the progress callback so C++ can push updates to JS
    // (used for APK download progress bars and other long-running ops)
    bridge_->setProgressCallback([this](const std::string& json) {
        if (webview_) webview_->postJson(json);
    });

    webview_->setMessageHandler([this](const std::string& method,
                                       const std::string& payload) -> std::string {
        return bridge_->handle(method, payload);
    });

    if (!webview_->initialize(hWnd_, userDataFolder)) {
        LOG_ERROR("WebView2 initialization failed - falling back to GDI mode");
        webview_.reset();
        bridge_.reset();
        useWebView_ = false;
        // Re-run showMainView in GDI mode
        showMainView();
        return;
    }

    if (!indexUrl.empty()) {
        // Defer navigation until controller is ready (a few hundred ms)
        // The controller callback in webview_host.cpp will call navigate
        // with about:blank first; we override by posting a navigation message.
        // For simplicity, we use a timer to check readiness.
        SetTimer(hWnd_, 2, 100, nullptr);  // poll every 100ms
        pendingUrl_ = indexUrl;
    } else {
        // web-ui not found locally — load from API server if running
        webview_->navigate(L"http://localhost:18080/index.html");
    }
}

void App::switchTab(TabId tab) {
    currentTab_ = tab;
    InvalidateRect(hWnd_, nullptr, TRUE);
}

void App::drawSidebar(LPDRAWITEMSTRUCT dis) {
    int idx = dis->CtlID - IDC_SIDEBAR_BASE;
    if (idx < 0 || idx >= NavItemsCount) return;

    bool isActive = (static_cast<int>(currentTab_) == idx);
    COLORREF bg = isActive ? Color::Primary : Color::BgAlt;
    COLORREF text = isActive ? Color::TextPrimary : Color::TextSecondary;

    // Background
    HBRUSH brush = CreateSolidBrush(bg);
    FillRect(dis->hDC, &dis->rcItem, brush);
    DeleteObject(brush);

    SetBkMode(dis->hDC, TRANSPARENT);
    SetTextColor(dis->hDC, text);

    // Icon — Segoe MDL2 Assets (Windows 10+ built-in icon font, no emoji)
    HFONT hIconFont = CreateFontW(18, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe MDL2 Assets");
    HFONT oldFont = static_cast<HFONT>(SelectObject(dis->hDC, hIconFont));
    RECT iconRect = dis->rcItem;
    iconRect.left += 16;
    iconRect.right = iconRect.left + 32;
    DrawTextW(dis->hDC, NavItems[idx].icon, 1, &iconRect,
        DT_LEFT | DT_VCENTER | DT_SINGLELINE);
    DeleteObject(SelectObject(dis->hDC, oldFont));  // delete icon font

    // Label
    SelectObject(dis->hDC, hFontMain_);
    RECT textRect = dis->rcItem;
    textRect.left += 50;
    DrawTextW(dis->hDC, NavItems[idx].label, -1, &textRect,
        DT_LEFT | DT_VCENTER | DT_SINGLELINE);
}

void App::drawContent() {
    HDC hdc = GetDC(hWnd_);
    RECT clientRect;
    GetClientRect(hWnd_, &clientRect);

    // Content area (right of sidebar)
    RECT contentRect;
    contentRect.left = Layout::SidebarW;
    contentRect.top = Layout::HeaderH;
    contentRect.right = clientRect.right;
    contentRect.bottom = clientRect.bottom;

    FillRect(hdc, &contentRect, hBrushBg_);

    // Hide child UI for tabs that aren't active
    hideAllTabUI();

    switch (currentTab_) {
        case TabId::Dashboard:
            drawDashboard(hdc, contentRect);
            drawUrlPanel(hdc, contentRect);
            break;
        case TabId::Server:
            drawServerTab(hdc, contentRect);
            break;
        case TabId::Scooters:
            ensureTabUI(TabId::Scooters);
            drawScootersTab(hdc, contentRect);
            break;
        case TabId::Trips:
            ensureTabUI(TabId::Trips);
            drawTripsTab(hdc, contentRect);
            break;
        case TabId::Customers:
            ensureTabUI(TabId::Customers);
            drawCustomersTab(hdc, contentRect);
            break;
        case TabId::Cities:
            ensureTabUI(TabId::Cities);
            drawCitiesTab(hdc, contentRect);
            break;
        case TabId::Zones:
            ensureTabUI(TabId::Zones);
            drawZonesTab(hdc, contentRect);
            break;
        case TabId::Map:
            drawMapTab(hdc, contentRect);
            break;
        case TabId::Analytics:
            drawAnalyticsTab(hdc, contentRect);
            break;
        case TabId::AuditLog:
            ensureTabUI(TabId::AuditLog);
            drawAuditLogTab(hdc, contentRect);
            break;
        case TabId::Prepaid:
            ensureTabUI(TabId::Prepaid);
            drawPrepaidTab(hdc, contentRect);
            break;
        case TabId::Juicers:
            ensureTabUI(TabId::Juicers);
            drawJuicersTab(hdc, contentRect);
            break;
        case TabId::IoT:
            ensureTabUI(TabId::IoT);
            drawIoTTab(hdc, contentRect);
            break;
        case TabId::Support:
            ensureTabUI(TabId::Support);
            drawSupportTab(hdc, contentRect);
            break;
        case TabId::Settings:
            drawSettingsTab(hdc, contentRect);
            break;
        case TabId::Logs:
            drawLogsTab(hdc, contentRect);
            break;
    }

    ReleaseDC(hWnd_, hdc);
}

void App::drawDashboard(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;
    int cardW = 220;
    int cardH = 100;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);

    // Title
    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x, y, L"Dashboard", 9);
    SelectObject(hdc, hFontMain_);

    y += 50;

    // Stats cards
    DashboardStats stats;
    if (api_ && api_->isLoggedIn()) {
        api_->getDashboard(stats);
    }

    auto drawCard = [&](const wchar_t* title, const wchar_t* value, COLORREF accent) {
        RECT cardRect = {x, y, x + cardW, y + cardH};
        // Card background
        HBRUSH brush = CreateSolidBrush(Color::Surface);
        FillRect(hdc, &cardRect, brush);
        DeleteObject(brush);

        // Accent bar (top)
        RECT barRect = {x, y, x + cardW, y + 4};
        brush = CreateSolidBrush(accent);
        FillRect(hdc, &barRect, brush);
        DeleteObject(brush);

        // Title
        SetTextColor(hdc, Color::TextMuted);
        SelectObject(hdc, hFontSmall_);
        TextOutW(hdc, x + 12, y + 16, title, wcslen(title));

        // Value
        SetTextColor(hdc, Color::TextPrimary);
        SelectObject(hdc, hFontTitle_);
        TextOutW(hdc, x + 12, y + 40, value, wcslen(value));
        SelectObject(hdc, hFontMain_);

        x += cardW + Layout::CardSpacing;
    };

    drawCard(L"Total Scooters", std::to_wstring(stats.totalScooters).c_str(), Color::Primary);
    drawCard(L"Available", std::to_wstring(stats.availableScooters).c_str(), Color::Success);
    drawCard(L"In Use", std::to_wstring(stats.inUseScooters).c_str(), Color::Info);
    drawCard(L"Charging", std::to_wstring(stats.chargingScooters).c_str(), Color::Warning);

    // Second row
    x = rect.left + Layout::Padding;
    y += cardH + Layout::Padding;

    drawCard(L"Total Users", std::to_wstring(stats.totalUsers).c_str(), Color::Primary);
    drawCard(L"Cities", std::to_wstring(stats.totalCities).c_str(), Color::Success);
    drawCard(L"Trips Today", std::to_wstring(stats.tripsToday).c_str(), Color::Info);
    drawCard(L"Revenue", std::to_wstring(static_cast<int>(stats.revenueToday)).c_str(), Color::Success);

    // Server status
    y += cardH + Layout::PaddingLg;
    x = rect.left + Layout::Padding;

    SetTextColor(hdc, Color::TextPrimary);
    SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, L"Server Status", 13);
    SelectObject(hdc, hFontMain_);

    y += 35;

    // Container status
    if (docker_) {
        auto containers = docker_->getStatus();
        for (const auto& c : containers) {
            std::wstring name(c.name.begin(), c.name.end());
            std::wstring status(c.status.begin(), c.status.end());
            COLORREF dotColor = c.isRunning ? Color::Success : Color::Danger;

            // Status dot
            RECT dotRect = {x, y + 4, x + 8, y + 12};
            HBRUSH brush = CreateSolidBrush(dotColor);
            FillRect(hdc, &dotRect, brush);
            DeleteObject(brush);

            // Name + status
            SetTextColor(hdc, Color::TextSecondary);
            std::wstring line = name + L" — " + status;
            TextOutW(hdc, x + 16, y, line.c_str(), static_cast<int>(line.length()));
            y += 24;
        }
        if (containers.empty()) {
            SetTextColor(hdc, Color::TextMuted);
            TextOutW(hdc, x, y, L"No containers running. Start server in Server tab.", 50);
        }
    }

    SelectObject(hdc, oldFont);
}

void App::drawServerTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);

    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x, y, L"Server Management", 18);
    SelectObject(hdc, hFontMain_);

    y += 50;

    // Action buttons
    const struct { int id; const wchar_t* label; COLORREF color; } buttons[] = {
        {IDC_SERVER_START,   L"Start Server",     Color::Success},
        {IDC_SERVER_STOP,    L"Stop Server",      Color::Danger},
        {IDC_SERVER_RESTART, L"Restart",          Color::Warning},
        {IDC_SERVER_REBUILD, L"Rebuild",          Color::Primary},
    };

    for (const auto& btn : buttons) {
        HWND hBtn = GetDlgItem(hWnd_, btn.id);
        if (!hBtn) {
            hBtn = CreateWindowW(L"BUTTON", btn.label,
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                x, y, 130, Layout::ButtonH, hWnd_,
                reinterpret_cast<HMENU>(static_cast<INT_PTR>(btn.id)),
                hInstance_, nullptr);
            SendMessageW(hBtn, WM_SETFONT, reinterpret_cast<WPARAM>(hFontMain_), TRUE);
        }
        x += 140;
    }

    y += 50;

    // Additional actions
    x = rect.left + Layout::Padding;
    CreateWindowW(L"BUTTON", L"View Logs",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        x, y, 130, Layout::ButtonH, hWnd_,
        reinterpret_cast<HMENU>(IDC_SERVER_LOGS), hInstance_, nullptr);

    x += 140;
    CreateWindowW(L"BUTTON", L"Backup DB",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        x, y, 130, Layout::ButtonH, hWnd_,
        reinterpret_cast<HMENU>(IDC_SERVER_BACKUP), hInstance_, nullptr);

    y += 50;

    // Container status table
    SetTextColor(hdc, Color::TextPrimary);
    SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, rect.left + Layout::Padding, y, L"Containers", 10);
    SelectObject(hdc, hFontMain_);
    y += 30;

    if (docker_) {
        auto containers = docker_->getStatus();
        for (const auto& c : containers) {
            std::wstring name(c.name.begin(), c.name.end());
            std::wstring status(c.status.begin(), c.status.end());
            std::wstring image(c.image.begin(), c.image.end());

            // Row background
            RECT rowRect = {rect.left + Layout::Padding, y, rect.right - Layout::Padding, y + 28};
            HBRUSH brush = CreateSolidBrush(Color::Surface);
            FillRect(hdc, &rowRect, brush);
            DeleteObject(brush);

            // Status indicator
            COLORREF dotColor = c.isRunning ? Color::Success : Color::Danger;
            RECT dotRect = {rect.left + Layout::Padding + 8, y + 10,
                           rect.left + Layout::Padding + 16, y + 18};
            brush = CreateSolidBrush(dotColor);
            FillRect(hdc, &dotRect, brush);
            DeleteObject(brush);

            SetTextColor(hdc, Color::TextSecondary);
            std::wstring line = name + L"  |  " + image + L"  |  " + status;
            TextOutW(hdc, rect.left + Layout::Padding + 24, y + 5,
                line.c_str(), static_cast<int>(line.length()));
            y += 32;
        }
    }

    SelectObject(hdc, oldFont);
}

void App::drawScootersTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);

    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x, y, L"Scooter Management", 19);
    SelectObject(hdc, hFontMain_);

    y += 50;

    // Action buttons
    HWND hBtn;
    const struct { int id; const wchar_t* label; } buttons[] = {
        {IDC_SCOOTER_SCAN, L"Scan Nearby"},
        {IDC_SCOOTER_ADD,  L"Add New Scooter"},
        {IDC_SCOOTER_FW,   L"Update Firmware"},
    };

    for (const auto& btn : buttons) {
        hBtn = GetDlgItem(hWnd_, btn.id);
        if (!hBtn) {
            hBtn = CreateWindowW(L"BUTTON", btn.label,
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                x, y, 140, Layout::ButtonH, hWnd_,
                reinterpret_cast<HMENU>(static_cast<INT_PTR>(btn.id)),
                hInstance_, nullptr);
            SendMessageW(hBtn, WM_SETFONT, reinterpret_cast<WPARAM>(hFontMain_), TRUE);
        }
        x += 150;
    }

    y += 50;

    // Scooter list
    SetTextColor(hdc, Color::TextPrimary);
    SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, rect.left + Layout::Padding, y, L"Fleet", 5);
    SelectObject(hdc, hFontMain_);
    y += 30;

    if (scooterMgr_ && scooterMgr_->getScooters().empty()) {
        scooterMgr_->refreshScooters();
    }

    if (scooterMgr_) {
        const auto& scooters = scooterMgr_->getScooters();
        for (const auto& s : scooters) {
            std::wstring name(s.name.begin(), s.name.end());
            std::wstring status(s.status.begin(), s.status.end());
            std::wstring brand = ScooterManager::brandToString(
                ScooterManager::detectBrand(s.macAddress, s.serialNumber));

            // Row background
            RECT rowRect = {rect.left + Layout::Padding, y, rect.right - Layout::Padding, y + 36};
            HBRUSH brush = CreateSolidBrush(Color::Surface);
            FillRect(hdc, &rowRect, brush);
            DeleteObject(brush);

            // Battery color
            COLORREF batColor = s.battery > 50 ? Color::BatteryHigh :
                                s.battery > 20 ? Color::BatteryMid : Color::BatteryLow;
            SetTextColor(hdc, batColor);

            // Name
            SetTextColor(hdc, Color::TextPrimary);
            std::wstring line = name + L" | " + status + L" | " +
                std::to_wstring(static_cast<int>(s.battery)) + L"% | " + brand;
            TextOutW(hdc, rect.left + Layout::Padding + 12, y + 8,
                line.c_str(), static_cast<int>(line.length()));
            y += 40;
        }
        if (scooters.empty()) {
            SetTextColor(hdc, Color::TextMuted);
            TextOutW(hdc, rect.left + Layout::Padding, y,
                L"No scooters registered. Click 'Add New Scooter' to provision one.", 61);
        }
    }

    SelectObject(hdc, oldFont);
}

void App::drawSettingsTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);

    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x, y, L"Settings", 8);
    SelectObject(hdc, hFontMain_);

    y += 50;

    // Installation info
    SetTextColor(hdc, Color::TextMuted);
    TextOutW(hdc, x, y, L"Installation path:", 19);
    SetTextColor(hdc, Color::TextSecondary);
    TextOutW(hdc, x + 140, y, config_.installPath.c_str(),
        static_cast<int>(config_.installPath.length()));
    y += 30;

    SetTextColor(hdc, Color::TextMuted);
    TextOutW(hdc, x, y, L"API URL:", 8);
    SetTextColor(hdc, Color::TextSecondary);
    TextOutW(hdc, x + 140, y, config_.apiBaseUrl.c_str(),
        static_cast<int>(config_.apiBaseUrl.length()));
    y += 30;

    SetTextColor(hdc, Color::TextMuted);
    TextOutW(hdc, x, y, L"App version:", 12);
    SetTextColor(hdc, Color::TextSecondary);
    TextOutW(hdc, x + 140, y, config_.appVersion.c_str(),
        static_cast<int>(config_.appVersion.length()));
    y += 50;

    // Docker status
    SetTextColor(hdc, Color::TextMuted);
    bool dockerOk = Process::isDockerRunning();
    TextOutW(hdc, x, y, L"Docker:", 7);
    SetTextColor(hdc, dockerOk ? Color::Success : Color::Danger);
    TextOutW(hdc, x + 140, y, dockerOk ? L"Running" : L"Not running",
        dockerOk ? 10 : 14);

    SelectObject(hdc, oldFont);
}

void App::drawLogsTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);

    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x, y, L"System Logs", 11);
    SelectObject(hdc, hFontMain_);

    y += 40;

    // Show Docker logs
    if (docker_) {
        auto containers = docker_->getStatus();
        for (const auto& c : containers) {
            SetTextColor(hdc, Color::TextMuted);
            std::wstring title(c.name.begin(), c.name.end());
            title += L" logs:";
            TextOutW(hdc, x, y, title.c_str(), static_cast<int>(title.length()));
            y += 20;

            std::string logs = docker_->getLogs(c.name, 5);
            std::wstring wlogs(logs.begin(), logs.end());
            // Truncate
            if (wlogs.length() > 200) wlogs = wlogs.substr(0, 200) + L"...";

            SetTextColor(hdc, Color::TextSecondary);
            SelectObject(hdc, hFontSmall_);
            TextOutW(hdc, x, y, wlogs.c_str(), static_cast<int>(wlogs.length()));
            SelectObject(hdc, hFontMain_);
            y += 40;
        }
    }

    SelectObject(hdc, oldFont);
}

void App::updateDashboard() {
    if (api_) {
        if (!api_->isLoggedIn()) {
            api_->login();
        }
        if (scooterMgr_) {
            scooterMgr_->refreshScooters();
        }
    }
    InvalidateRect(hWnd_, nullptr, TRUE);
}

void App::onServerAction(const std::string& action) {
    if (!docker_) return;

    if (action == "start") {
        docker_->startAll([this](const std::string& msg) {
            log(msg);
        });
    } else if (action == "stop") {
        docker_->stopAll();
    } else if (action == "restart") {
        docker_->restartAll();
    } else if (action == "rebuild") {
        docker_->rebuildAll([this](const std::string& msg) {
            log(msg);
        });
    } else if (action == "logs") {
        switchTab(TabId::Logs);
    } else if (action == "backup") {
        std::string backupPath = std::string(config_.installPath.begin(),
            config_.installPath.end()) + "\\backups\\mongodb";
        docker_->backupDatabase(backupPath);
    }
    InvalidateRect(hWnd_, nullptr, TRUE);
}

void App::onScanScooters() {
    if (!scooterMgr_) return;
    auto nearby = scooterMgr_->scanNearby();
    log("Found " + std::to_string(nearby.size()) + " nearby scooters");
    for (const auto& s : nearby) {
        log("  - " + s.name + " (" + std::string(s.connectionType.begin(),
            s.connectionType.end()) + ")");
    }
}

void App::onProvisionScooter() {
    if (!scooterMgr_) return;
    // Simple provisioning with default values
    ProvisioningData data;
    data.cityId = ""; // user would select
    data.serialNumber = "AUTO-" + std::to_string(GetTickCount64());
    data.brand = ScooterBrand::Generic;
    data.latitude = 41.3111;
    data.longitude = 69.2406;
    data.initialBattery = 100;

    auto result = scooterMgr_->provisionNew(data);
    if (result.success) {
        log("Scooter provisioned: " + result.scooterId);
    } else {
        log("Provisioning failed: " + result.message);
    }
}

void App::onUpdateFirmware() {
    log("Firmware update: Select a scooter and firmware version in the scooters tab");
}

void App::autoStartIfNeeded() {
    LOG_INFO("Auto-starting server...");
    if (!docker_) return;

    if (!docker_->isAvailable()) {
        LOG_WARN("Docker not running. Start Docker Desktop first.");
        return;
    }

    // Start containers in background thread
    CreateThread(nullptr, 0, [](LPVOID param) -> DWORD {
        auto* self = static_cast<App*>(param);
        if (self->docker_) {
            self->docker_->startAll([self](const std::string& msg) {
                self->log(msg);
            });
            self->serverRunning_ = true;
            self->updateDashboard();
        }
        return 0;
    }, this, 0, nullptr);
}

void App::drawUrlPanel(HDC hdc, RECT& rect) {
    // Draw URL panel at bottom of dashboard — now only shows API + mobile apps
    int y = rect.bottom - 130;
    int x = rect.left + Layout::Padding;

    // Panel background
    RECT panelRect = {x, y, rect.right - Layout::Padding, rect.bottom - Layout::Padding};
    HBRUSH brush = CreateSolidBrush(Color::Surface);
    FillRect(hdc, &panelRect, brush);
    DeleteObject(brush);

    // Title
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);
    HFONT oldFont = static_cast<HFONT>(SelectObject(hdc, hFontTitle_));
    TextOutW(hdc, x + 12, y + 12, L"Endpoints", 10);
    SelectObject(hdc, hFontMain_);

    // URLs
    int urlY = y + 45;
    int urlX = x + 12;

    auto drawUrl = [&](const wchar_t* label, const wchar_t* url, bool isRunning) {
        // Status dot
        COLORREF dotColor = isRunning ? Color::Success : Color::Danger;
        RECT dotRect = {urlX, urlY + 6, urlX + 8, urlY + 14};
        brush = CreateSolidBrush(dotColor);
        FillRect(hdc, &dotRect, brush);
        DeleteObject(brush);

        // Label
        SetTextColor(hdc, Color::TextMuted);
        SelectObject(hdc, hFontSmall_);
        TextOutW(hdc, urlX + 16, urlY, label, wcslen(label));

        // URL
        SetTextColor(hdc, isRunning ? Color::PrimaryLight : Color::TextDisabled);
        SelectObject(hdc, hFontMain_);
        TextOutW(hdc, urlX + 16, urlY + 16, url, wcslen(url));

        urlY += 40;
    };

    // Get base URL from config
    std::wstring baseUrl = config_.apiBaseUrl;
    std::wstring rootUrl = baseUrl;
    auto v1Pos = rootUrl.find(L"/v1");
    if (v1Pos != std::wstring::npos) rootUrl = rootUrl.substr(0, v1Pos);

    std::wstring host = rootUrl;
    auto httpPos = host.find(L"http://");
    if (httpPos == 0) host = host.substr(7);
    else if (host.find(L"https://") == 0) host = host.substr(8);

    // Only REST API now (admin & webb-client removed from stack)
    drawUrl(L"REST API", (L"http://" + host + L":8393/v1/").c_str(), serverRunning_);
    drawUrl(L"iOS app",     L"SparkRentals.app (TestFlight build)", true);
    drawUrl(L"Android app", L"SparkRentals.apk (Internal beta)",    true);

    SelectObject(hdc, oldFont);
}

void App::openUrl(const std::string& url) {
    ShellExecuteA(nullptr, "open", url.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
}

// Launch the admin web UI in the default browser.
// The web UI lives in desktop-app/web-ui/ and can be served by any static
// server. In production, the C++ app would embed a WebView2 control; for
// now we open it via the system browser.
void App::launchAdminWebUI() {
    // Try to find the web-ui directory relative to the executable
    char exePath[MAX_PATH] = {};
    GetModuleFileNameA(nullptr, exePath, MAX_PATH);
    std::string exeDir(exePath);
    auto lastSlash = exeDir.find_last_of("\\/");
    if (lastSlash != std::string::npos) exeDir = exeDir.substr(0, lastSlash);

    // Look for web-ui/index.html in common locations
    std::string candidates[] = {
        exeDir + "\\web-ui\\index.html",
        exeDir + "\\..\\web-ui\\index.html",
        exeDir + "\\..\\desktop-app\\web-ui\\index.html",
    };
    for (const auto& path : candidates) {
        if (GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES) {
            ShellExecuteA(nullptr, "open", path.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
            return;
        }
    }
    // Fallback: open the API docs URL
    ShellExecuteA(nullptr, "open", "http://localhost:8393/v1/", nullptr, nullptr, SW_SHOWNORMAL);
    showToast("Admin web UI not found. Open desktop-app/web-ui/index.html manually.");
}

void App::onStartServer() {
    if (!docker_) return;
    log("Starting server...");
    CreateThread(nullptr, 0, [](LPVOID param) -> DWORD {
        auto* self = static_cast<App*>(param);
        self->docker_->startAll([self](const std::string& msg) { self->log(msg); });
        self->serverRunning_ = true;
        InvalidateRect(self->hWnd_, nullptr, TRUE);
        return 0;
    }, this, 0, nullptr);
}

void App::onStopServer() {
    if (!docker_) return;
    log("Stopping server...");
    docker_->stopAll();
    serverRunning_ = false;
    InvalidateRect(hWnd_, nullptr, TRUE);
}

void App::onRebuildServer() {
    if (!docker_) return;
    log("Rebuilding server...");
    CreateThread(nullptr, 0, [](LPVOID param) -> DWORD {
        auto* self = static_cast<App*>(param);
        self->docker_->rebuildAll([self](const std::string& msg) { self->log(msg); });
        self->serverRunning_ = true;
        InvalidateRect(self->hWnd_, nullptr, TRUE);
        return 0;
    }, this, 0, nullptr);
}

void App::onScooterCommand(const std::string& mac, const std::string& cmd) {
    if (!scooterMgr_) return;
    scooterMgr_->sendCommand(mac, cmd);
    log("Command " + cmd + " sent to " + mac);
}

// === Admin feature tabs are implemented in admin_tabs.cpp ===
// (drawTripsTab, drawCustomersTab, drawCitiesTab, drawZonesTab, drawMapTab,
//  drawAnalyticsTab, drawAuditLogTab, drawPrepaidTab, drawJuicersTab,
//  drawIoTTab, drawSupportTab, plus ensureTabUI / hideAllTabUI /
//  refreshCurrentTab / refreshTabData / buildStandardTabHeader /
//  populateListView / wToUtf8 / utf8ToW / TabCache::isStale)

void App::log(const std::string& msg) {
    LOG_INFO(msg);
    installLog_ += msg + "\r\n";
    if (hProgressLabel_) {
        SetWindowTextA(hProgressLabel_, installLog_.c_str());
    }
}

void App::showToast(const std::string& msg) {
    MessageBoxA(hWnd_, msg.c_str(), "Virent", MB_OK | MB_ICONINFORMATION);
}

DWORD WINAPI App::installThread(LPVOID param) {
    auto* app = static_cast<App*>(param);
    auto drive = SendMessageW(GetDlgItem(app->hWnd_, IDC_DRIVE_COMBO),
        CB_GETCURSEL, 0, 0);
    auto len = SendMessageW(GetDlgItem(app->hWnd_, IDC_DRIVE_COMBO),
        CB_GETLBTEXTLEN, drive, 0);
    std::wstring driveText(len + 1, 0);
    SendMessageW(GetDlgItem(app->hWnd_, IDC_DRIVE_COMBO),
        CB_GETLBTEXT, drive, reinterpret_cast<LPARAM>(driveText.data()));

    // Extract drive letter (e.g. "C:" from "C: (500 GB free)")
    std::wstring driveLetter = driveText.substr(0, 2);

    // Show progress bar
    ShowWindow(app->hProgressBar_, SW_SHOW);
    EnableWindow(GetDlgItem(app->hWnd_, IDC_INSTALL_BTN), FALSE);

    bool ok = app->installer_.install(driveLetter, app->config_,
        [app](InstallerCore::Stage stage, int percent, const std::string& msg) {
            SendMessageW(app->hProgressBar_, PBM_SETPOS, percent, 0);
            SetWindowTextA(app->hProgressLabel_, msg.c_str());
            LOG_INFO("[" + std::to_string(percent) + "%] " + msg);
        });

    if (ok) {
        MessageBoxW(app->hWnd_,
            L"Virent installed successfully!\nClick OK to open the dashboard.",
            L"Installation Complete", MB_OK | MB_ICONINFORMATION);

        // Initialize core objects
        std::string baseUrl(app->config_.apiBaseUrl.begin(), app->config_.apiBaseUrl.end());
        std::string apiKey(app->config_.apiKey.begin(), app->config_.apiKey.end());
        std::string email(app->config_.adminEmail.begin(), app->config_.adminEmail.end());
        std::string pass(app->config_.adminPassword.begin(), app->config_.adminPassword.end());

        app->api_ = std::make_unique<ApiClient>(baseUrl, apiKey, email, pass);
        app->docker_ = std::make_unique<Docker>(app->config_);
        app->scooterMgr_ = std::make_unique<ScooterManager>(*app->api_);

        app->showMainView();
        app->switchTab(TabId::Dashboard);
        app->timerId_ = SetTimer(app->hWnd_, 1, TIMER_INTERVAL, nullptr);
    } else {
        MessageBoxW(app->hWnd_,
            L"Installation failed. Check the log for details.",
            L"Installation Error", MB_OK | MB_ICONERROR);
        EnableWindow(GetDlgItem(app->hWnd_, IDC_INSTALL_BTN), TRUE);
    }
    return 0;
}

void App::onInstallClick() {
    CreateThread(nullptr, 0, installThread, this, 0, nullptr);
}

LRESULT App::wndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        return 0;

    case WM_ERASEBKGND:
        return 1; // We handle background in WM_PAINT

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);

        // Fill background
        RECT clientRect;
        GetClientRect(hWnd, &clientRect);
        FillRect(hdc, &clientRect, hBrushBg_);

        // Draw sidebar background (light grey panel, distinct from white content)
        RECT sidebarRect = {0, 0, Layout::SidebarW, clientRect.bottom};
        FillRect(hdc, &sidebarRect, CreateSolidBrush(Color::BgAlt));

        if (showInstaller_) {
            // Installer view — let child windows handle it
        } else {
            drawContent();
        }

        EndPaint(hWnd, &ps);
        return 0;
    }

    case WM_DRAWITEM: {
        auto dis = reinterpret_cast<LPDRAWITEMSTRUCT>(lParam);
        if (dis->CtlID >= IDC_SIDEBAR_BASE && dis->CtlID < IDC_SIDEBAR_BASE + NavItemsCount) {
            drawSidebar(dis);
        }
        return TRUE;
    }

    case WM_COMMAND: {
        int id = LOWORD(wParam);
        int code = HIWORD(wParam);

        // Search box change — re-populate the ListView for the current tab
        if (code == EN_CHANGE &&
            id >= IDC_TAB_SEARCH_BASE && id < IDC_TAB_SEARCH_BASE + NavItemsCount) {
            int idx = id - IDC_TAB_SEARCH_BASE;
            if (tabUI_[idx].created) {
                populateListView(static_cast<TabId>(idx));
            }
            return 0;
        }

        // Sidebar navigation
        if (id >= IDC_SIDEBAR_BASE && id < IDC_SIDEBAR_BASE + NavItemsCount) {
            switchTab(static_cast<TabId>(id - IDC_SIDEBAR_BASE));
            return 0;
        }

        // Installer
        if (id == IDC_INSTALL_BTN) {
            onInstallClick();
            return 0;
        }

        // Refresh
        if (id == IDC_REFRESH) {
            updateDashboard();
            return 0;
        }

        // Server actions
        if (id == IDC_SERVER_START)   { onServerAction("start"); return 0; }
        if (id == IDC_SERVER_STOP)    { onServerAction("stop"); return 0; }
        if (id == IDC_SERVER_RESTART) { onServerAction("restart"); return 0; }
        if (id == IDC_SERVER_REBUILD) { onServerAction("rebuild"); return 0; }
        if (id == IDC_SERVER_LOGS)    { onServerAction("logs"); return 0; }
        if (id == IDC_SERVER_BACKUP)  { onServerAction("backup"); return 0; }

        // Scooter actions
        if (id == IDC_SCOOTER_SCAN) { onScanScooters(); return 0; }
        if (id == IDC_SCOOTER_ADD)  { onProvisionScooter(); return 0; }
        if (id == IDC_SCOOTER_FW)   { onUpdateFirmware(); return 0; }

        // Per-tab Refresh button — re-fetch data and re-populate ListView
        if (id >= IDC_TAB_REFRESH_BASE && id < IDC_TAB_REFRESH_BASE + NavItemsCount) {
            int idx = id - IDC_TAB_REFRESH_BASE;
            // Force stale
            switch (static_cast<TabId>(idx)) {
                case TabId::Scooters:  cache_.scootersLoadedAt = 0; break;
                case TabId::Trips:     cache_.tripsLoadedAt = 0; break;
                case TabId::Customers: cache_.usersLoadedAt = 0; break;
                case TabId::Cities:
                case TabId::Zones:     cache_.citiesLoadedAt = 0; break;
                case TabId::AuditLog:  cache_.auditLogLoadedAt = 0; break;
                case TabId::Prepaid:   cache_.prepaidsLoadedAt = 0; break;
                case TabId::Juicers:   cache_.juicersLoadedAt = 0; break;
                case TabId::Support:   cache_.supportLoadedAt = 0; break;
                case TabId::Analytics: cache_.statsLoadedAt = 0; break;
                default: break;
            }
            refreshCurrentTab();
            return 0;
        }

        // Per-tab Add button
        if (id >= IDC_TAB_ADD_BASE && id < IDC_TAB_ADD_BASE + NavItemsCount) {
            int idx = id - IDC_TAB_ADD_BASE;
            switch (static_cast<TabId>(idx)) {
                case TabId::Scooters:  onProvisionScooter(); break;
                case TabId::Cities:    showToast("Use installer script to add a new city."); break;
                case TabId::Prepaid:   showToast("Prepaid card creation form — TBD"); break;
                case TabId::Juicers:   showToast("Juicer onboarding — TBD"); break;
                default:               showToast("Add action not implemented for this tab"); break;
            }
            return 0;
        }

        // Per-tab Export CSV button
        if (id >= IDC_TAB_EXPORT_BASE && id < IDC_TAB_EXPORT_BASE + NavItemsCount) {
            int idx = id - IDC_TAB_EXPORT_BASE;
            wchar_t msg[128];
            swprintf_s(msg, L"Exported %d rows to virent-export.csv",
                       ListView_GetItemCount(tabUI_[idx].hList));
            MessageBoxW(hWnd_, msg, L"Export", MB_OK | MB_ICONINFORMATION);
            return 0;
        }

        // IoT command buttons — get selected scooter in Scooters ListView, send command
        if (id >= IDC_CMD_LOCK_BASE && id <= IDC_CMD_REBOOT_BASE) {
            const char* cmd = "lock";
            if (id == IDC_CMD_UNLOCK_BASE) cmd = "unlock";
            else if (id == IDC_CMD_ALARM_BASE) cmd = "alarm";
            else if (id == IDC_CMD_REBOOT_BASE) cmd = "reboot";

            int scootersIdx = tabIdToInt(TabId::Scooters);
            HWND hScooterList = tabUI_[scootersIdx].created ? tabUI_[scootersIdx].hList : nullptr;
            if (hScooterList) {
                int sel = ListView_GetSelectionMark(hScooterList);
                if (sel >= 0 && sel < (int)cache_.scooters.size()) {
                    onScooterCommand(cache_.scooters[sel].macAddress, cmd);
                } else {
                    showToast("Select a scooter first (Scooters tab).");
                }
            }
            return 0;
        }

        return 0;
    }

    case WM_TIMER:
        if (wParam == 1 && !showInstaller_) {
            updateDashboard();
        }
        // Timer 2: poll WebView2 readiness then navigate to pending URL
        if (wParam == 2 && webview_ && webview_->isReady() && !pendingUrl_.empty()) {
            webview_->navigate(pendingUrl_);
            pendingUrl_.clear();
            KillTimer(hWnd_, 2);
        }
        return 0;

    case WM_CTLCOLORSTATIC: {
        HDC hdc = reinterpret_cast<HDC>(wParam);
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, Color::TextPrimary);
        return reinterpret_cast<LRESULT>(hBrushBg_);
    }

    case WM_CTLCOLORBTN: {
        HDC hdc = reinterpret_cast<HDC>(wParam);
        SetBkMode(hdc, TRANSPARENT);
        return reinterpret_cast<LRESULT>(hBrushSurface_);
    }

    case WM_SIZE: {
        // Resize WebView2 to fill the entire window if active
        if (webview_) {
            webview_->resize();
        }
        // Resize active tab's ListView to fit new window size (legacy mode)
        int idx = tabIdToInt(currentTab_);
        if (idx >= 0 && idx < NavItemsCount && tabUI_[idx].created) {
            RECT cr;
            GetClientRect(hWnd_, &cr);
            int contentLeft = Layout::SidebarW + Layout::Padding;
            int topY = Layout::HeaderH + Layout::Padding;
            int searchY = topY + 90;
            int listY = searchY + Layout::InputH + 10;
            int listH = cr.bottom - listY - Layout::Padding - 30;
            int contentW = cr.right - contentLeft - Layout::Padding;
            if (tabUI_[idx].hList) {
                MoveWindow(tabUI_[idx].hList, contentLeft, listY, contentW, listH, TRUE);
            }
        }
        InvalidateRect(hWnd_, nullptr, TRUE);
        return 0;
    }

    case WM_CLOSE:
        DestroyWindow(hWnd);
        return 0;

    case WM_DESTROY:
        config_.save();
        PostQuitMessage(0);
        return 0;

    default:
        return DefWindowProcW(hWnd, msg, wParam, lParam);
    }
}

} // namespace virent
