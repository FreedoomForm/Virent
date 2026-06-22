# ============================================================
# Virent Control Center — CMake build configuration
# ============================================================
# Build:
#   mkdir build && cd build
#   cmake .. -G "Visual Studio 17 2022" -A x64
#   cmake --build . --config Release
#
# Or with MinGW:
#   mkdir build && cd build
#   cmake .. -G "MinGW Makefiles"
#   cmake --build . --config Release
#
# Requirements:
#   - Windows 10/11 (WebView2 runtime ships with Win11 by default)
#   - Visual Studio 2022 with C++ workload
#   - CMake 3.20+
#   - Internet on first build (FetchContent downloads WebView2 SDK)
# ============================================================

cmake_minimum_required(VERSION 3.20)

project(VirentControlCenter VERSION 1.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# --- App info ---
set(APP_NAME "VirentControlCenter")
set(APP_VERSION "1.1.0")
set(APP_AUTHOR "Virent")
set(APP_DESCRIPTION "Virent Scooter Sharing - Server Control Center")

# --- Windows specifics ---
if(WIN32)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:WINDOWS")
    add_compile_definitions(
        WIN32_LEAN_AND_MEAN
        NOMINMAX
        _CRT_SECURE_NO_WARNINGS
        UNICODE
        _UNICODE
    )
endif()

# ============================================================
# WebView2 SDK via FetchContent
# ============================================================
# Downloads the official Microsoft.Web.WebView2 NuGet package at build time.
# This gives us:
#   - WebView2.h, WebView2EnvironmentOptions.h headers
#   - WebView2Loader.dll (must be shipped alongside the .exe)
#   - WebView2Loader.dll.lib (import library)
include(FetchContent)

# We use a fixed version of the WebView2 SDK for reproducibility.
set(WEBVIEW2_VERSION "1.0.2792.45")
set(WEBVIEW2_NUGET_URL "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/${WEBVIEW2_VERSION}")

# Allow WEBVIEW2_INCLUDE_DIR / WEBVIEW2_LIB_DIR / WEBVIEW2_LOADER_DLL to be
# passed via -D flags (used by GitHub Actions which downloads + extracts
# the .nupkg before running cmake).
if(WEBVIEW2_INCLUDE_DIR AND WEBVIEW2_LIB_DIR AND WEBVIEW2_LOADER_DLL)
    message(STATUS "Using pre-installed WebView2 SDK:")
    message(STATUS "  include: ${WEBVIEW2_INCLUDE_DIR}")
    message(STATUS "  lib:     ${WEBVIEW2_LIB_DIR}")
    message(STATUS "  dll:     ${WEBVIEW2_LOADER_DLL}")
else()
    # FetchContent downloads the .nupkg (which is a ZIP archive) as a 'package' file.
    # We then extract it manually using cmake -E tar.
    FetchContent_Declare(
        webview2
        URL ${WEBVIEW2_NUGET_URL}
        DOWNLOAD_NO_EXTRACT TRUE
    )

    FetchContent_GetProperties(webview2)
    if(NOT webview2_POPULATED)
        message(STATUS "Downloading WebView2 SDK v${WEBVIEW2_VERSION}...")
        FetchContent_Populate(webview2)

        # The downloaded file is at ${webview2_SOURCE_DIR}/package (no extension).
        # Rename to .nupkg.zip so cmake -E tar recognises it as a ZIP archive.
        set(NUGET_FILE "${webview2_SOURCE_DIR}/package")
        set(NUGET_ZIP  "${webview2_SOURCE_DIR}/webview2.nupkg.zip")

        if(EXISTS "${NUGET_FILE}")
            file(RENAME "${NUGET_FILE}" "${NUGET_ZIP}")
        endif()

        message(STATUS "Extracting WebView2 SDK from ${NUGET_ZIP}...")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf "${NUGET_ZIP}"
            WORKING_DIRECTORY "${webview2_SOURCE_DIR}"
            RESULT_VARIABLE EXTRACT_RESULT
        )
        if(NOT EXTRACT_RESULT EQUAL 0)
            message(WARNING "WebView2 SDK extraction failed (code ${EXTRACT_RESULT}). Trying with PowerShell Expand-Archive...")
            execute_process(
                COMMAND powershell -Command "Expand-Archive -Path '${NUGET_ZIP}' -DestinationPath '${webview2_SOURCE_DIR}' -Force"
                RESULT_VARIABLE PS_RESULT
            )
            if(NOT PS_RESULT EQUAL 0)
                message(FATAL_ERROR "Both cmake tar and PowerShell Expand-Archive failed to extract WebView2 SDK. Pass -DWEBVIEW2_INCLUDE_DIR, -DWEBVIEW2_LIB_DIR, -DWEBVIEW2_LOADER_DLL manually.")
            endif()
        endif()
    endif()

    set(WEBVIEW2_INCLUDE_DIR "${webview2_SOURCE_DIR}/build/native/include")
    set(WEBVIEW2_LIB_DIR "${webview2_SOURCE_DIR}/build/native/x64")
    set(WEBVIEW2_LOADER_DLL "${WEBVIEW2_LIB_DIR}/WebView2Loader.dll")
endif()

message(STATUS "WebView2 include: ${WEBVIEW2_INCLUDE_DIR}")
message(STATUS "WebView2 lib:     ${WEBVIEW2_LIB_DIR}")

# Find the WebView2Loader import library (could be .dll.lib or just .lib)
find_library(WEBVIEW2_LOADER_LIB NAMES WebView2Loader.dll WebView2Loader
    PATHS ${WEBVIEW2_LIB_DIR}
    NO_DEFAULT_PATH
    REQUIRED
)
message(STATUS "WebView2 loader lib found: ${WEBVIEW2_LOADER_LIB}")

# --- Source files ---
set(SOURCES
    src/main.cpp
    src/app.cpp
    src/admin_tabs.cpp
    src/ui/webview_host.cpp
    src/ui/window.cpp
    src/ui/installer.cpp
    src/ui/dashboard.cpp
    src/ui/scooters.cpp
    src/ui/server_tab.cpp
    src/ui/theme.cpp
    src/core/native_bridge.cpp
    src/core/installer_core.cpp
    src/core/docker.cpp
    src/core/api_client.cpp
    src/core/scooter_mgr.cpp
    src/core/config.cpp
    src/utils/process.cpp
    # logger.h is header-only (no .cpp needed)
)

set(HEADERS
    src/app.h
    src/ui/webview_host.h
    src/ui/window.h
    src/ui/installer.h
    src/ui/dashboard.h
    src/ui/scooters.h
    src/ui/server_tab.h
    src/ui/theme.h
    src/core/native_bridge.h
    src/core/installer_core.h
    src/core/docker.h
    src/core/api_client.h
    src/core/scooter_mgr.h
    src/core/config.h
    src/utils/process.h
    src/utils/logger.h
)

# --- Executable ---
add_executable(${APP_NAME} WIN32 ${SOURCES} ${HEADERS})

# --- Windows libraries ---
if(WIN32)
    target_link_libraries(${APP_NAME} PRIVATE
        comctl32      # Common controls
        comdlg32      # Common dialogs (file open/save)
        shell32       # Shell operations
        shlwapi       # Path utilities
        shfolder      # SHGetKnownFolderPath
        ws2_32        # Winsock (HTTP client)
        winhttp       # WinHTTP for API calls
        gdiplus       # GDI+ for graphics
        uxtheme       # Theme support
        dwmapi        # Window compositing
        psapi         # Process info
        iphlpapi      # Network info
        userenv       # User profile
        ole32         # COM (for WebView2)
        oleaut32      # COM automation
        urlmon        # URL moniker
        "${WEBVIEW2_LOADER_LIB}"
    )
endif()

# --- Include directories ---
target_include_directories(${APP_NAME} PRIVATE
    src
    src/utils
    src/ui
    src/core
    ${WEBVIEW2_INCLUDE_DIR}
)

# --- C++20 features ---
target_compile_features(${APP_NAME} PRIVATE cxx_std_20)

# --- Post-build: copy WebView2Loader.dll + web-ui/ to output ---
if(WIN32)
    set_target_properties(${APP_NAME} PROPERTIES
        OUTPUT_NAME "VirentControlCenter"
        VERSION ${APP_VERSION}
    )

    # Copy WebView2Loader.dll next to the .exe
    # Use get_filename_component to resolve to absolute path
    get_filename_component(WEBVIEW2_LOADER_DLL_ABS "${WEBVIEW2_LOADER_DLL}" ABSOLUTE BASE_DIR "${CMAKE_SOURCE_DIR}")
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WEBVIEW2_LOADER_DLL_ABS}"
            "$<TARGET_FILE_DIR:${APP_NAME}>/WebView2Loader.dll"
        COMMENT "Copying WebView2Loader.dll to output directory"
    )

    # Copy web-ui/ directory next to the .exe so the app can load it
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/web-ui"
            "$<TARGET_FILE_DIR:${APP_NAME}>/web-ui"
        COMMENT "Copying web-ui/ to output directory"
    )

    # Add manifest for DPI awareness + common controls v6
    configure_file(
        ${CMAKE_SOURCE_DIR}/resources/app.manifest.in
        ${CMAKE_BINARY_DIR}/app.manifest
        @ONLY
    )

    # Add resource file
    configure_file(
        ${CMAKE_SOURCE_DIR}/resources/resource.rc.in
        ${CMAKE_BINARY_DIR}/resource.rc
        @ONLY
    )
    # Copy icon.ico to build dir so resource.rc can find it
    configure_file(
        ${CMAKE_SOURCE_DIR}/resources/icon.ico
        ${CMAKE_BINARY_DIR}/resources/icon.ico
        COPYONLY
    )
    target_sources(${APP_NAME} PRIVATE ${CMAKE_BINARY_DIR}/resource.rc)
endif()

# --- Install ---
install(TARGETS ${APP_NAME} RUNTIME DESTINATION bin)
install(FILES "${WEBVIEW2_LOADER_DLL}" DESTINATION bin)
install(DIRECTORY "${CMAKE_SOURCE_DIR}/web-ui" DESTINATION bin)
