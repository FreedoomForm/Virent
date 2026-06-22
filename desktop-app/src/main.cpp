/**
 * main.cpp — Entry point for Virent Control Center
 *
 * Virent Control Center — Universal server management app for scooter sharing.
 * Written in C++20 with Win32 API.
 *
 * Features:
 *   - One-click installation (Docker + containers + DB seed)
 *   - Server management (start/stop/restart/rebuild containers)
 *   - Database management (backup, restore, stats)
 *   - Scooter management (provision, command, firmware update)
 *   - Universal scooter support (Ninebot, Xiaomi, ESP32, Generic)
 *   - Real-time dashboard with auto-refresh
 *   - System logs viewer
 *
 * Build:
 *   mkdir build && cd build
 *   cmake .. -G "Visual Studio 17 2022" -A x64
 *   cmake --build . --config Release
 *
 * Or with CMake + Ninja:
 *   cmake -B build -G Ninja
 *   cmake --build build
 */

#include <windows.h>
#include <commctrl.h>
#include "app.h"
#include "logger.h"

#pragma comment(lib, "comctl32.lib")
#pragma comment(linker, "\"/manifestdependency:type='win32' \
name='Microsoft.Windows.Common-Controls' version='6.0.0.0' \
processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR, int nCmdShow) {
    // Enable DPI awareness
    SetProcessDPIAware();

    // Initialize common controls
    INITCOMMONCONTROLSEX icc = {};
    icc.dwSize = sizeof(icc);
    icc.dwICC = ICC_PROGRESS_CLASS | ICC_BAR_CLASSES | ICC_STANDARD_CLASSES;
    InitCommonControlsEx(&icc);

    // Initialize GDI+
    ULONG_PTR gdiplusToken = 0;
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, nullptr);

    // Run app
    virent::App app(hInstance);
    int result = app.run();

    // Cleanup
    Gdiplus::GdiplusShutdown(gdiplusToken);

    return result;
}
