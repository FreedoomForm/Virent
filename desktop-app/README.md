# Virent Control Center — Windows Desktop App

> C++20 + Win32 + WebView2. Native backend (Docker, IoT, file system, shell) with HTML/CSS/JS frontend.

## Architecture

The app combines the best of two worlds:

```text
+-----------------------------------+        +-----------------------------------+
|       C++ (Win32 native)          |        |       HTML/CSS/JS (WebView2)     |
|-----------------------------------|        |-----------------------------------|
|  - Docker CLI orchestration       | <----> |  - BarqScoot-style UI            |
|  - MQTT broker management         | JSON   |  - 14 sidebar tabs               |
|  - File system (backups, logs)    | RPC    |  - Interactive Zone Editor       |
|  - Shell exec (whitelisted)       |        |  - Modals (block, refund, bulk)  |
|  - Serial / Bluetooth (future)    |        |  - Charts (Canvas / SVG)         |
|  - Process management             |        |  - fetch() to REST API           |
+-----------------------------------+        +-----------------------------------+
                                                        |
                                                        v
                                              REST API at localhost:8393
                                              (Node.js + MongoDB + MQTT)
```

**Why this design:**
- C++ keeps full control over: Docker CLI, MQTT broker, serial ports, Bluetooth, file system, Windows services
- HTML/CSS/JS renders the entire UI — matches the BarqScoot mockups pixel-perfect
- The two halves talk via a typed JSON-RPC bridge over `postMessage`

## Project structure

```text
desktop-app/
├── CMakeLists.txt                # Build config + WebView2 SDK via FetchContent
├── README.md
├── src/
│   ├── main.cpp                  # Entry point
│   ├── app.h / app.cpp           # App class — window, WebView2 init, fallback to GDI
│   ├── admin_tabs.cpp            # Legacy GDI admin tabs (fallback when no WebView2)
│   ├── ui/
│   │   ├── webview_host.h/cpp    # WebView2 COM wrapper (the new UI renderer)
│   │   ├── theme.h               # BarqScoot color palette + Material Icons
│   │   └── ...                   # Legacy GDI stubs
│   ├── core/
│   │   ├── native_bridge.h/cpp   # JS -> C++ JSON-RPC bridge (Docker, IoT, FS, shell)
│   │   ├── api_client.h/cpp      # WinHTTP REST client + built-in JsonValue parser
│   │   ├── docker.h/cpp          # Docker container management
│   │   ├── installer_core.h/cpp  # First-run installer (Docker, clone, build, seed)
│   │   ├── scooter_mgr.h/cpp     # Universal scooter management (BLE, MQTT, REST)
│   │   └── config.h/cpp          # Settings persistence (JSON)
│   └── utils/
│       ├── process.h/cpp         # CreateProcess wrapper
│       └── logger.h              # Structured logger
├── web-ui/                       # The HTML/CSS/JS admin interface (rendered by WebView2)
│   ├── index.html                # 14 sidebar tabs + 4 working modals
│   ├── styles.css                # BarqScoot light theme (Plus Jakarta Sans, 16px radius)
│   └── app.js                    # Vanilla JS, REST API client, Zone Editor, native bridge
└── resources/
    ├── app.manifest.in           # DPI awareness + common controls
    └── resource.rc.in            # Version info + manifest
```

## Native bridge — JS to C++ protocol

JavaScript calls C++ via `window.chrome.webview.postMessage(method|id|payload)` and receives responses via the `message` event.

**Supported methods:**

```text
docker.status              — list containers (returns JSON array)
docker.start               — start all containers
docker.stop                — stop all containers
docker.restart             — restart all containers
docker.rebuild             — rebuild all images
docker.logs                — get container logs (payload = container name)
docker.backup              — backup MongoDB

iot.sendCommand            — send command to scooter (payload = "mac|command")
iot.scanBluetooth          — scan for BLE scooters (stub)

shell.openUrl              — open URL in default browser (payload = url)
shell.openFile             — open file dialog, return path
shell.exec                 — run whitelisted shell command

fs.readFile                — read a text file (payload = path)
fs.writeFile               — write a text file (payload = "path|content")
fs.listBackups             — list MongoDB backup files

app.getVersion             — get app version
app.getConfigDir           — get config directory path
app.getInstallPath         — get install path
```

## Build

Prerequisites: Windows 10/11, Visual Studio 2022 (MSVC v143, C++ workload), CMake 3.20+, Windows SDK 10. Internet on first build (downloads WebView2 SDK).

```batch
:: Visual Studio
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release

:: Ninja
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

Output: `build/Release/VirentControlCenter.exe` + `WebView2Loader.dll` + `web-ui/` folder.

## Runtime requirements

The WebView2 Evergreen Runtime ships with Windows 11 by default. On Windows 10, install it from:
https://developer.microsoft.com/microsoft-edge/webview2/

If the runtime is missing, the app falls back to the legacy Win32 GDI mode (still functional, just less pretty).

## Tech stack

```text
Language         C++20
GUI              Win32 API + WebView2 (Edge/Chromium render)
HTTP             WinHTTP
JSON             Built-in JsonValue parser (no third-party deps)
Icons            Segoe MDL2 Assets (Windows 10+ built-in) + Material Icons (web)
WebView2 SDK     Microsoft.Web.WebView2 v1.0.2792.45 (via CMake FetchContent)
Build            CMake 3.20+
UI style         BarqScoot-inspired light theme (Plus Jakarta Sans, 16px radius)
```

## Fallback behavior

If WebView2 runtime is not installed, the app automatically falls back to the legacy Win32 GDI mode (`useWebView_ = false`). The GDI mode uses the same data layer (`api_client`, `docker`, `scooter_mgr`) but renders UI with native Win32 controls (ListView, buttons, owner-drawn sidebar). It's less pretty but fully functional.

To force GDI mode for debugging, set `useWebView_ = false` in `app.h` before building.
