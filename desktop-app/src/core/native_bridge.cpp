/**
 * native_bridge.cpp — Implementation of the JS-to-C++ bridge.
 *
 * Each method handler returns a JSON string that JavaScript parses to get
 * the result. Errors are returned as {"error": "..."} objects.
 *
 * The bridge is intentionally minimal — it only exposes operations that
 * JavaScript cannot do directly (file system, shell, Docker, Bluetooth).
 * REST API calls are still done by JavaScript via fetch() — but if CORS
 * becomes an issue, the api.get/api.post methods provide a C++ proxy.
 */

#include "native_bridge.h"
#include "docker.h"
#include "api_client.h"
#include "config.h"
#include "logger.h"
#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>
#include <commdlg.h>
#include <winhttp.h>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>
#include <algorithm>

#pragma comment(lib, "winhttp.lib")

namespace virent {

NativeBridge::NativeBridge(Docker* docker, ApiClient* api, AppConfig* config)
    : docker_(docker), api_(api), config_(config) {}

std::string NativeBridge::handle(const std::string& method, const std::string& payload) {
    // Parse "category.action" — e.g. "docker.start"
    auto dot = method.find('.');
    if (dot == std::string::npos) {
        return R"({"error":"invalid method format, expected 'category.action'"})";
    }
    std::string category = method.substr(0, dot);
    std::string action = method.substr(dot + 1);

    if (category == "docker")  return handleDocker(action, payload);
    if (category == "iot")     return handleIot(action, payload);
    if (category == "shell")   return handleShell(action, payload);
    if (category == "fs")      return handleFs(action, payload);
    if (category == "api")     return handleApi(action, payload);
    if (category == "app")     return handleApp(action, payload);
    if (category == "apk")     return handleApk(action, payload);

    return R"({"error":"unknown category: )" + category + R"("})";
}

// ===================== Docker =====================

std::string NativeBridge::handleDocker(const std::string& action, const std::string& payload) {
    if (!docker_) return R"({"error":"docker not initialized"})";

    if (action == "status") {
        auto containers = docker_->getStatus();
        std::ostringstream ss;
        ss << "{\"data\":[";
        for (size_t i = 0; i < containers.size(); i++) {
            const auto& c = containers[i];
            if (i > 0) ss << ",";
            ss << "{\"name\":\"" << jsonEscape(c.name) << "\","
               << "\"image\":\"" << jsonEscape(c.image) << "\","
               << "\"status\":\"" << jsonEscape(c.status) << "\","
               << "\"isRunning\":" << (c.isRunning ? "true" : "false") << "}";
        }
        ss << "]}";
        return ss.str();
    }
    if (action == "start") {
        docker_->startAll([](const std::string&) {});
        return R"({"data":{"status":"starting"}})";
    }
    if (action == "stop") {
        docker_->stopAll();
        return R"({"data":{"status":"stopped"}})";
    }
    if (action == "restart") {
        docker_->restartAll();
        return R"({"data":{"status":"restarting"}})";
    }
    if (action == "rebuild") {
        docker_->rebuildAll([](const std::string&) {});
        return R"({"data":{"status":"rebuilding"}})";
    }
    if (action == "logs") {
        // payload = container name
        std::string logs = docker_->getLogs(payload, 100);
        return "{\"data\":{\"logs\":\"" + jsonEscape(logs) + "\"}}";
    }
    if (action == "backup") {
        std::string backupPath = std::string(config_->installPath.begin(), config_->installPath.end()) + "\\backups\\mongodb";
        docker_->backupDatabase(backupPath);
        return R"({"data":{"status":"backup_started","path":")" + backupPath + R"("}})";
    }
    return R"({"error":"unknown docker action: )" + action + R"("})";
}

// ===================== IoT =====================

std::string NativeBridge::handleIot(const std::string& action, const std::string& payload) {
    if (!api_) return R"({"error":"api client not initialized"})";

    if (action == "sendCommand") {
        // payload = "macAddress|command"
        auto sep = payload.find('|');
        if (sep == std::string::npos) return R"({"error":"expected 'mac|command'"})";
        std::string mac = payload.substr(0, sep);
        std::string cmd = payload.substr(sep + 1);
        auto resp = api_->sendScooterCommand(mac, cmd);
        if (resp.success()) {
            return "{\"data\":{\"success\":true,\"body\":\"" + jsonEscape(resp.body) + "\"}}";
        }
        return "{\"error\":\"" + jsonEscape(resp.error.empty() ? resp.body : resp.error) + "\"}";
    }
    if (action == "scanBluetooth") {
        // Stub — would use Windows.Devices.Bluetooth API
        return R"({"data":{"devices":[]}})";
    }
    return R"({"error":"unknown iot action: )" + action + R"("})";
}

// ===================== Shell =====================

std::string NativeBridge::handleShell(const std::string& action, const std::string& payload) {
    if (action == "openUrl") {
        ShellExecuteA(nullptr, "open", payload.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
        return R"({"data":{"success":true}})";
    }
    if (action == "openFile") {
        // Open file dialog for backups
        char buf[MAX_PATH] = {};
        OPENFILENAMEA ofn = {};
        ofn.lStructSize = sizeof(ofn);
        ofn.lpstrFile = buf;
        ofn.nMaxFile = MAX_PATH;
        ofn.lpstrFilter = "All files\0*.*\0MongoDB backups\0*.bson\0";
        ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
        if (GetOpenFileNameA(&ofn)) {
            return "{\"data\":{\"path\":\"" + jsonEscape(buf) + "\"}}";
        }
        return R"({"data":{"path":""}})";
    }
    if (action == "exec") {
        // Sandbox: only allow whitelisted commands
        if (payload == "docker ps" || payload == "docker stats --no-stream") {
            // Would call CreateProcess and capture stdout
            return "{\"data\":{\"output\":\"(shell output captured here)\"}}";
        }
        return R"({"error":"command not whitelisted"})";
    }
    return R"({"error":"unknown shell action: )" + action + R"("})";
}

// ===================== File system =====================

std::string NativeBridge::handleFs(const std::string& action, const std::string& payload) {
    if (action == "readFile") {
        std::ifstream f(payload, std::ios::binary);
        if (!f) return R"({"error":"cannot open file"})";
        std::ostringstream ss;
        ss << f.rdbuf();
        return "{\"data\":{\"content\":\"" + jsonEscape(ss.str()) + "\"}}";
    }
    if (action == "writeFile") {
        // payload = "path|content"
        auto sep = payload.find('|');
        if (sep == std::string::npos) return R"({"error":"expected 'path|content'"})";
        std::string path = payload.substr(0, sep);
        std::string content = payload.substr(sep + 1);
        std::ofstream f(path, std::ios::binary);
        if (!f) return R"({"error":"cannot write file"})";
        f << content;
        return R"({"data":{"success":true}})";
    }
    if (action == "listBackups") {
        // List files in backups/mongodb directory
        std::string backupDir = std::string(config_->installPath.begin(), config_->installPath.end()) + "\\backups\\mongodb";
        std::ostringstream ss;
        ss << "{\"data\":[";
        WIN32_FIND_DATAA fd;
        std::string pattern = backupDir + "\\*";
        HANDLE h = FindFirstFileA(pattern.c_str(), &fd);
        if (h != INVALID_HANDLE_VALUE) {
            bool first = true;
            do {
                if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
                if (!first) ss << ",";
                first = false;
                ss << "{\"name\":\"" << jsonEscape(fd.cFileName) << "\","
                   << "\"size\":" << (static_cast<unsigned long long>(fd.nFileSizeHigh) << 32 | fd.nFileSizeLow) << "}";
            } while (FindNextFileA(h, &fd));
            FindClose(h);
        }
        ss << "]}";
        return ss.str();
    }
    return R"({"error":"unknown fs action: )" + action + R"("})";
}

// ===================== API proxy (for CORS-free REST calls) =====================

std::string NativeBridge::handleApi(const std::string& action, const std::string& payload) {
    if (!api_) return R"({"error":"api client not initialized"})";

    if (action == "get" || action == "post" || action == "put" || action == "delete") {
        // payload = "path|body"
        std::string path, body;
        auto sep = payload.find('|');
        if (sep == std::string::npos) {
            path = payload;
        } else {
            path = payload.substr(0, sep);
            body = payload.substr(sep + 1);
        }
        ApiResponse resp;
        if (action == "get")    resp = api_->get(path);
        if (action == "post")   resp = api_->post(path, body);
        if (action == "put")    resp = api_->put(path, body);
        if (action == "delete") resp = api_->del(path);
        return "{\"status\":" + std::to_string(resp.statusCode) +
               ",\"body\":\"" + jsonEscape(resp.body) + "\"}";
    }
    return R"({"error":"unknown api action: )" + action + R"("})";
}

// ===================== App =====================

std::string NativeBridge::handleApp(const std::string& action, const std::string& payload) {
    if (action == "getVersion") {
        return R"({"data":{"version":"1.1.0","build":"2026.06.18"}})";
    }
    if (action == "getConfigDir") {
        PWSTR path = nullptr;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &path))) {
            std::wstring wpath(path);
            CoTaskMemFree(path);
            std::string s(wpath.begin(), wpath.end());
            return "{\"data\":{\"path\":\"" + s + "\\\\Virent\"}}";
        }
        return R"({"error":"cannot get app data dir"})";
    }
    if (action == "getInstallPath") {
        std::string s(config_->installPath.begin(), config_->installPath.end());
        return "{\"data\":{\"path\":\"" + s + "\"}}";
    }
    return R"({"error":"unknown app action: )" + action + R"("})";
}

// ===================== APK download =====================
//
// Downloads an APK file from a URL (typically a GitHub Releases URL) to the
// user's Downloads folder. Reports progress back to JavaScript via the
// progress callback so the UI can update a progress bar in real time.
//
// Message format from JS:
//   "download|<requestId>|<url>|<filename>"
//
// Messages sent back to JS (via progressCb_):
//   {"_id":"<requestId>","type":"progress","pct":42,"received":1234567,"total":3000000}
//   {"_id":"<requestId>","type":"done","path":"C:\\Users\\...\\Downloads\\virent-android.apk","size":3000000}
//   {"_id":"<requestId>","type":"error","error":"..."}
//
// Returns empty string (the response is sent asynchronously via progressCb_).

std::string NativeBridge::handleApk(const std::string& action, const std::string& payload) {
    if (action != "download") {
        return R"({"error":"unknown apk action: )" + action + R"("})";
    }

    // payload format: "requestId|url|filename"
    auto sep1 = payload.find('|');
    if (sep1 == std::string::npos) return R"({"error":"expected 'id|url|filename'"})";
    auto sep2 = payload.find('|', sep1 + 1);
    if (sep2 == std::string::npos) return R"({"error":"expected 'id|url|filename'"})";

    std::string requestId = payload.substr(0, sep1);
    std::string url = payload.substr(sep1 + 1, sep2 - sep1 - 1);
    std::string filename = payload.substr(sep2 + 1);

    LOG_INFO("APK download request: " + url + " -> " + filename);

    // Get the user's Downloads folder
    PWSTR downloadsPath = nullptr;
    if (FAILED(SHGetKnownFolderPath(FOLDERID_Downloads, 0, nullptr, &downloadsPath))) {
        std::string err = R"({"_id":")" + requestId + R"(","type":"error","error":"cannot find Downloads folder"})";
        if (progressCb_) progressCb_(err);
        return "";
    }
    std::wstring wDownloads(downloadsPath);
    CoTaskMemFree(downloadsPath);

    // Convert filename to wstring and build full path
    std::wstring wFilename(filename.begin(), filename.end());
    std::wstring wFullPath = wDownloads + L"\\" + wFilename;

    // Convert URL to wstring for WinHTTP
    std::wstring wUrl(url.begin(), url.end());

    // Parse URL into host + path
    std::wstring host = wUrl, path = L"/";
    if (wUrl.find(L"https://") == 0) host = wUrl.substr(8);
    else if (wUrl.find(L"http://") == 0) host = wUrl.substr(7);
    auto slashPos = host.find(L'/');
    if (slashPos != std::wstring::npos) {
        path = host.substr(slashPos);
        host = host.substr(0, slashPos);
    }

    // Open WinHTTP session
    HINTERNET hSession = WinHttpOpen(L"VirentControlCenter/1.1",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) {
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"WinHttpOpen failed"})");
        return "";
    }

    HINTERNET hConnect = WinHttpConnect(hSession, host.c_str(),
        wUrl.find(L"https://") == 0 ? INTERNET_DEFAULT_HTTPS_PORT : INTERNET_DEFAULT_HTTP_PORT, 0);
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"WinHttpConnect failed"})");
        return "";
    }

    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", path.c_str(),
        nullptr, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
        wUrl.find(L"https://") == 0 ? WINHTTP_FLAG_SECURE : 0);
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"WinHttpOpenRequest failed"})");
        return "";
    }

    // Send the request
    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
        WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"WinHttpSendRequest failed"})");
        return "";
    }

    if (!WinHttpReceiveResponse(hRequest, nullptr)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"WinHttpReceiveResponse failed"})");
        return "";
    }

    // Get status code
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(statusCode);
    WinHttpQueryHeaders(hRequest,
        WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
        WINHTTP_HEADER_NAME_BY_INDEX, &statusCode, &statusCodeSize, 0);

    if (statusCode < 200 || statusCode >= 300) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        std::string err = R"({"_id":")" + requestId + R"(","type":"error","error":"HTTP )" +
                          std::to_string(statusCode) + R"("})";
        if (progressCb_) progressCb_(err);
        return "";
    }

    // Get Content-Length for progress calculation
    DWORD totalSize = 0;
    DWORD totalSizeSize = sizeof(totalSize);
    WinHttpQueryHeaders(hRequest,
        WINHTTP_QUERY_CONTENT_LENGTH | WINHTTP_QUERY_FLAG_NUMBER,
        WINHTTP_HEADER_NAME_BY_INDEX, &totalSize, &totalSizeSize, 0);

    // Open the output file
    HANDLE hFile = CreateFileW(wFullPath.c_str(), GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile == INVALID_HANDLE_VALUE) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"cannot create output file"})");
        return "";
    }

    // Download loop: read chunks, write to file, post progress
    DWORD received = 0;
    DWORD lastPct = 0;
    bool error = false;

    while (true) {
        DWORD bytesAvailable = 0;
        if (!WinHttpQueryDataAvailable(hRequest, &bytesAvailable)) break;
        if (bytesAvailable == 0) break;

        // Cap chunk size at 64 KB
        DWORD chunkSize = std::min<DWORD>(bytesAvailable, 65536);
        std::vector<char> buf(chunkSize);
        DWORD bytesRead = 0;
        if (!WinHttpReadData(hRequest, buf.data(), chunkSize, &bytesRead)) {
            error = true;
            break;
        }
        if (bytesRead == 0) break;

        DWORD bytesWritten = 0;
        if (!WriteFile(hFile, buf.data(), bytesRead, &bytesWritten, nullptr) || bytesWritten != bytesRead) {
            error = true;
            break;
        }

        received += bytesRead;

        // Post progress update (throttle to 1% increments)
        DWORD pct = totalSize > 0 ? (received * 100 / totalSize) : 0;
        if (pct != lastPct || received == totalSize) {
            lastPct = pct;
            if (progressCb_) {
                std::ostringstream ss;
                ss << R"({"_id":")" << requestId << R"(","type":"progress",)"
                   << R"("pct":)" << pct << ","
                   << R"("received":)" << received << ","
                   << R"("total":)" << totalSize << "}";
                progressCb_(ss.str());
            }
        }
    }

    CloseHandle(hFile);
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    if (error) {
        DeleteFileW(wFullPath.c_str());
        if (progressCb_) progressCb_(R"({"_id":")" + requestId + R"(","type":"error","error":"download failed"})");
        return "";
    }

    // Convert path back to UTF-8 for the response
    std::string pathUtf8(wFullPath.begin(), wFullPath.end());
    std::ostringstream ss;
    ss << R"({"_id":")" << requestId << R"(","type":"done",)"
       << R"("path":")" << jsonEscape(pathUtf8) << R"(",)"
       << R"("size":)" << received << "}";
    if (progressCb_) progressCb_(ss.str());

    LOG_INFO("APK downloaded to: " + pathUtf8 + " (" + std::to_string(received) + " bytes)");
    return "";
}

// ===================== Helpers =====================

std::string NativeBridge::jsonEscape(const std::string& s) {
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += c;
                }
        }
    }
    return out;
}

std::string NativeBridge::splitField(const std::string& payload, size_t index) {
    size_t start = 0;
    for (size_t i = 0; i < index; i++) {
        auto sep = payload.find('|', start);
        if (sep == std::string::npos) return "";
        start = sep + 1;
    }
    auto end = payload.find('|', start);
    return payload.substr(start, end == std::string::npos ? std::string::npos : end - start);
}

} // namespace virent
