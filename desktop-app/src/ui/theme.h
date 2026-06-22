/**
 * theme.h — Modern dark theme for Virent Control Center
 *
 * Per Frontend Design System v2.0: consistent visual design
 * Dark theme matching the web/mobile apps
 *
 * Architecture (2026-06-18):
 *   Virent = iOS + Android + Windows Desktop + REST API
 *   Admin website REMOVED — all admin functions moved to this Windows app
 *   Webb-client REMOVED — mobile apps handle the client side
 *
 * Admin tabs (1:1 mapping with former admin website):
 *   Dashboard, Server, Scooters, Trips, Customers, Cities, Zones, Map,
 *   Analytics, AuditLog, Prepaid, Juicers, IoT, Support, Settings, Logs
 */

#pragma once
#include <windows.h>
// GDI+ requires OLE2 to be included first on newer Windows SDKs (10.0.26100+)
// otherwise PROPID / IImageBytes are undefined and the build fails with
// 'missing type specifier' errors in GdiplusImaging.h.
#include <objbase.h>
#include <ocidl.h>
#include <gdiplus.h>

namespace virent {

// Per design-tokens.css — Virent style guide (BarqScoot-inspired, light theme)
namespace Color {
    // Neutral (light theme)
    constexpr COLORREF Bg          = RGB(255, 255, 255);    // #FFFFFF
    constexpr COLORREF BgAlt       = RGB(249, 250, 251);    // #F9FAFB
    constexpr COLORREF Surface     = RGB(255, 255, 255);    // #FFFFFF
    constexpr COLORREF SurfaceAlt  = RGB(243, 244, 246);    // #F3F4F6
    constexpr COLORREF SurfaceHover= RGB(249, 250, 251);    // #F9FAFB
    constexpr COLORREF Border      = RGB(229, 231, 235);    // #E5E7EB
    constexpr COLORREF BorderStrong= RGB(209, 213, 219);    // #D1D5DB

    // Text
    constexpr COLORREF TextPrimary  = RGB(17, 24, 39);     // #111827
    constexpr COLORREF TextSecondary= RGB(75, 85, 99);     // #4B5563
    constexpr COLORREF TextMuted    = RGB(156, 163, 175);  // #9CA3AF
    constexpr COLORREF TextDisabled = RGB(209, 213, 219);  // #D1D5DB

    // Primary (BarqScoot teal-blue #3489FF)
    constexpr COLORREF Primary      = RGB(52, 137, 255);   // #3489FF
    constexpr COLORREF PrimaryHover = RGB(42, 117, 224);   // #2A75E0
    constexpr COLORREF PrimaryLight = RGB(96, 165, 250);   // #60A5FA
    constexpr COLORREF PrimaryBg    = RGB(239, 246, 255);  // #EFF6FF

    // Semantic
    constexpr COLORREF Success      = RGB(22, 163, 74);    // #16A34A
    constexpr COLORREF SuccessBg    = RGB(220, 252, 231);  // #DCFCE7
    constexpr COLORREF Warning      = RGB(217, 119, 6);    // #D97706
    constexpr COLORREF WarningBg    = RGB(254, 243, 199);  // #FEF3C7
    constexpr COLORREF Danger       = RGB(220, 38, 38);    // #DC2626
    constexpr COLORREF DangerBg     = RGB(254, 226, 226);  // #FEE2E2
    constexpr COLORREF Info         = RGB(2, 132, 199);    // #0284C7
    constexpr COLORREF InfoBg       = RGB(224, 242, 254);  // #E0F2FE

    // Accent (scooter battery colors)
    constexpr COLORREF BatteryHigh  = RGB(22, 163, 74);
    constexpr COLORREF BatteryMid   = RGB(217, 119, 6);
    constexpr COLORREF BatteryLow   = RGB(220, 38, 38);

    // ListView palette
    constexpr COLORREF ListHeaderBg   = RGB(243, 244, 246);  // surfaceAlt
    constexpr COLORREF ListRowAltBg   = RGB(249, 250, 251);  // bgAlt
    constexpr COLORREF ListSelectedBg = RGB(52, 137, 255);   // primary
}

// Layout constants (per design-tokens §2)
namespace Layout {
    constexpr int WindowW      = 1280;
    constexpr int WindowH      = 860;
    constexpr int SidebarW     = 220;
    constexpr int HeaderH      = 60;
    constexpr int TabBarH      = 0; // no tab bar, sidebar navigation
    constexpr int Padding      = 16;
    constexpr int PaddingSm    = 8;
    constexpr int PaddingLg    = 24;
    constexpr int Radius       = 8;
    constexpr int ButtonH      = 36;
    constexpr int InputH       = 32;
    constexpr int CardSpacing  = 12;
    constexpr int TableRowH    = 28;
    constexpr int TableHeaderH = 32;
    constexpr int SearchW      = 240;
}

// Font sizes (per design-tokens §5)
namespace Font {
    constexpr int Tiny    = 11;
    constexpr int Small   = 12;
    constexpr int Body    = 14;
    constexpr int BodyL   = 16;
    constexpr int Heading = 20;
    constexpr int Title   = 28;
    constexpr int Display = 40;

    // Font family
    constexpr const wchar_t* Family = L"Segoe UI";
}

// Tab IDs — ALL admin features 1:1 with former admin website
enum class TabId {
    Dashboard  = 0,
    Server     = 1,   // Native to desktop: Docker, install, backup
    Scooters   = 2,
    Trips      = 3,   // NEW (was missing)
    Customers  = 4,   // renamed from Users
    Cities     = 5,
    Zones      = 6,   // NEW (was missing)
    Map        = 7,   // NEW (was missing)
    Analytics  = 8,
    AuditLog   = 9,
    Prepaid    = 10,
    Juicers    = 11,
    IoT        = 12,
    Support    = 13,
    Settings   = 14,
    Logs       = 15,
};

// Navigation items — matches admin website sidebar 1:1
// Icons use Segoe MDL2 Assets codepoints (Windows 10+ built-in icon font).
// Set the font of the icon slot to "Segoe MDL2 Assets" and call DrawIcon to render.
struct NavItem {
    TabId id;
    const wchar_t* label;
    const wchar_t* icon;  // single MDL2 glyph
};

inline const NavItem NavItems[] = {
    { TabId::Dashboard,  L"Dashboard",     L"\xE80F" },  // Home
    { TabId::Server,     L"Server",        L"\xE713" },  // Settings (gear)
    { TabId::Scooters,   L"Scooters",      L"\xE804" },  // Mopud / vehicle — fallback to "Car"
    { TabId::Trips,      L"Trips",         L"\xE7BC" },  // Route
    { TabId::Customers,  L"Customers",     L"\xE716" },  // People
    { TabId::Cities,     L"Cities",        L"\xE7C4" },  // MapPin
    { TabId::Zones,      L"Zones",         L"\xE8E5" },  // Region (paint outline)
    { TabId::Map,        L"Map",           L"\xE707" },  // MapLayers
    { TabId::Analytics,  L"Analytics",     L"\ECA5" },  // BarChartH
    { TabId::AuditLog,   L"Audit Log",     L"\E9D5" },  // Audit (checklist)
    { TabId::Prepaid,    L"Prepaid",       L"\xE8C7" },  // CreditCard
    { TabId::Juicers,    L"Juicers",       L"\xE83E" },  // BatteryCharging
    { TabId::IoT,        L"IoT Control",   L"\xE83A" },  // Plug / Connected
    { TabId::Support,    L"Support",       L"\xE8BD" },  // Message
    { TabId::Settings,   L"Settings",      L"\xE713" },  // Settings (gear)
    { TabId::Logs,       L"Logs",          L"\xE9F9" },  // DocumentLines
};

inline constexpr int NavItemsCount = sizeof(NavItems) / sizeof(NavItems[0]);

// Control IDs for per-tab UI (search box, ListView, action buttons)
// Indexed by TabId. Used by app.cpp + admin_tabs.cpp.
constexpr int IDC_TAB_SEARCH_BASE   = 2000;
constexpr int IDC_TAB_LIST_BASE     = 2100;
constexpr int IDC_TAB_REFRESH_BASE  = 2200;
constexpr int IDC_TAB_ADD_BASE      = 2300;
constexpr int IDC_TAB_EXPORT_BASE   = 2400;

// IoT / Scooter command buttons
constexpr int IDC_CMD_LOCK_BASE     = 2500;
constexpr int IDC_CMD_UNLOCK_BASE   = 2501;
constexpr int IDC_CMD_ALARM_BASE    = 2502;
constexpr int IDC_CMD_REBOOT_BASE   = 2503;

inline int tabIdToInt(TabId t) { return static_cast<int>(t); }

} // namespace virent
