/**
 * app.h — Main application class
 *
 * Manages window lifecycle, tab navigation, and coordinates
 * between installer, dashboard, scooter manager, and API client.
 *
 * Architecture (2026-06-18):
 *   All admin website functionality moved here.
 *   Admin website & Webb-Client removed from the stack.
 */

#pragma once
#include <windows.h>
#include <commctrl.h>
#include <memory>
#include <string>
#include <vector>
#include "ui/theme.h"
#include "ui/webview_host.h"
#include "core/config.h"
#include "core/api_client.h"
#include "core/docker.h"
#include "core/scooter_mgr.h"
#include "core/installer_core.h"
#include "core/native_bridge.h"

namespace virent {

// Cached data for each admin tab — refreshed on tab switch and on timer
struct TabCache {
    // Raw JSON responses
    std::string scootersJson;
    std::string tripsJson;
    std::string usersJson;
    std::string citiesJson;
    std::string prepaidsJson;
    std::string juicersJson;
    std::string supportJson;
    std::string auditLogJson;
    std::string statsJson;
    std::string metricsJson;

    // Parsed values
    std::vector<ScooterInfo> scooters;
    DashboardStats stats{};

    // Timestamps (ms since epoch) — used for staleness check
    int64_t scootersLoadedAt = 0;
    int64_t tripsLoadedAt = 0;
    int64_t usersLoadedAt = 0;
    int64_t citiesLoadedAt = 0;
    int64_t prepaidsLoadedAt = 0;
    int64_t juicersLoadedAt = 0;
    int64_t supportLoadedAt = 0;
    int64_t auditLogLoadedAt = 0;
    int64_t statsLoadedAt = 0;

    // Search filters (current text in each tab's search box)
    std::wstring scooterSearch;
    std::wstring tripSearch;
    std::wstring userSearch;
    std::wstring citySearch;
    std::wstring prepaidSearch;
    std::wstring juicerSearch;
    std::wstring supportSearch;
    std::wstring auditSearch;

    bool isStale(int64_t t, int maxAgeMs = 30000) const;
};

class App {
public:
    App(HINSTANCE hInstance);
    ~App();

    int run();

    // Window proc handler
    LRESULT wndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

private:
    HINSTANCE hInstance_;
    HWND hWnd_ = nullptr;
    HWND hSidebar_ = nullptr;
    HWND hContent_ = nullptr;

    // Current state
    TabId currentTab_ = TabId::Dashboard;
    bool isInstalled_ = false;
    bool showInstaller_ = true;
    bool serverRunning_ = false;

    // URL display (Dashboard tab)
    HWND hUrlApi_ = nullptr;
    HWND hBtnOpenApi_ = nullptr;
    HWND hBtnStartServer_ = nullptr;
    HWND hBtnStopServer_ = nullptr;
    HWND hBtnRebuild_ = nullptr;

    // Auto-start on launch
    void autoStartIfNeeded();

    // Core objects
    AppConfig config_;
    std::unique_ptr<ApiClient> api_;
    std::unique_ptr<Docker> docker_;
    std::unique_ptr<ScooterManager> scooterMgr_;
    InstallerCore installer_;

    // WebView2 host + native bridge (the actual UI renderer)
    std::unique_ptr<WebViewHost> webview_;
    std::unique_ptr<NativeBridge> bridge_;
    bool useWebView_ = true;  // if false, fall back to Win32 GDI
    std::wstring pendingUrl_;  // URL to navigate to once WebView2 is ready

    // Per-tab UI handles — ListView + search box + action buttons
    // Index by TabId. Created lazily on first tab visit; hidden when switching away.
    struct TabUI {
        HWND hList = nullptr;          // ListView (report mode)
        HWND hSearch = nullptr;        // Edit control for filtering
        HWND hSearchLabel = nullptr;   // "Search:" label
        HWND hRefresh = nullptr;       // Refresh button
        HWND hAdd = nullptr;           // Add / New button
        HWND hExport = nullptr;        // Export button (CSV)
        bool created = false;
    };
    TabUI tabUI_[16];  // sized to TabId enum count

    // Fonts and brushes
    HFONT hFontMain_ = nullptr;
    HFONT hFontTitle_ = nullptr;
    HFONT hFontSmall_ = nullptr;
    HBRUSH hBrushBg_ = nullptr;
    HBRUSH hBrushSurface_ = nullptr;
    HBRUSH hBrushPrimary_ = nullptr;

    // Timer for auto-refresh
    UINT_PTR timerId_ = 0;
    static const UINT TIMER_INTERVAL = 5000; // 5 seconds

    // Installation progress
    HWND hProgressBar_ = nullptr;
    HWND hProgressLabel_ = nullptr;
    std::string installLog_;

    // Cached data per tab
    TabCache cache_;

    // ===== Methods =====
    bool createWindow();
    void createFonts();
    void createBrushes();
    void createSidebar();
    void switchTab(TabId tab);
    void showInstallerView();
    void showMainView();
    void initializeWebView();
    void drawSidebar(LPDRAWITEMSTRUCT dis);
    void drawContent();

    // Tab lifecycle helpers
    void ensureTabUI(TabId tab);
    void hideAllTabUI();
    void refreshCurrentTab();
    void refreshTabData(TabId tab);

    // Reusable UI builders
    void buildStandardTabHeader(TabId tab, HDC hdc, RECT& rect, const wchar_t* title);
    void populateListView(TabId tab);

    // Installer
    void onInstallClick();
    static DWORD WINAPI installThread(LPVOID param);

    // Dashboard tab (native — stats + container status)
    void drawDashboard(HDC hdc, RECT& rect);
    void drawUrlPanel(HDC hdc, RECT& rect);
    void updateDashboard();

    // Server tab (native — Docker management)
    void drawServerTab(HDC hdc, RECT& rect);
    void onServerAction(const std::string& action);
    void onStartServer();
    void onStopServer();
    void onRebuildServer();

    // Scooters tab (native — scan / provision / firmware / commands)
    void drawScootersTab(HDC hdc, RECT& rect);
    void onScanScooters();
    void onProvisionScooter();
    void onUpdateFirmware();
    void onScooterCommand(const std::string& mac, const std::string& cmd);

    // ===== Admin tabs (1:1 with former admin website) =====
    // Each tab uses a ListView populated from the API.
    void drawTripsTab(HDC hdc, RECT& rect);
    void drawCustomersTab(HDC hdc, RECT& rect);
    void drawCitiesTab(HDC hdc, RECT& rect);
    void drawZonesTab(HDC hdc, RECT& rect);
    void drawMapTab(HDC hdc, RECT& rect);
    void drawAnalyticsTab(HDC hdc, RECT& rect);
    void drawAuditLogTab(HDC hdc, RECT& rect);
    void drawPrepaidTab(HDC hdc, RECT& rect);
    void drawJuicersTab(HDC hdc, RECT& rect);
    void drawIoTTab(HDC hdc, RECT& rect);
    void drawSupportTab(HDC hdc, RECT& rect);

    // Settings tab (native — paths, API URL, version, Docker)
    void drawSettingsTab(HDC hdc, RECT& rect);
    void openUrl(const std::string& url);
    void launchAdminWebUI();

    // Logs tab (native — container logs viewer)
    void drawLogsTab(HDC hdc, RECT& rect);

    // Helpers
    void log(const std::string& msg);
    void showToast(const std::string& msg);
    std::string wToUtf8(const std::wstring& ws);
    std::wstring utf8ToW(const std::string& s);
};

} // namespace virent
