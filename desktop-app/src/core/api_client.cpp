/**
 * api_client.cpp — WinHTTP implementation of API client
 */

#include "api_client.h"
#include "logger.h"
#include <windows.h>
#include <winhttp.h>
#include <sstream>

#pragma comment(lib, "winhttp.lib")

namespace virent {

ApiClient::ApiClient(const std::string& baseUrl, const std::string& apiKey,
                     const std::string& email, const std::string& password)
    : baseUrl_(baseUrl), apiKey_(apiKey), email_(email), password_(password) {}

// Parse URL into host + path
struct UrlParts {
    std::wstring host;
    std::wstring path;
    int port = 80;
    bool https = false;
};

static UrlParts parseUrl(const std::string& url) {
    UrlParts parts;
    std::wstring wurl(url.begin(), url.end());

    if (wurl.find(L"https://") == 0) {
        parts.https = true;
        parts.port = 443;
        wurl = wurl.substr(8);
    } else if (wurl.find(L"http://") == 0) {
        parts.https = false;
        parts.port = 80;
        wurl = wurl.substr(7);
    }

    auto slashPos = wurl.find(L'/');
    if (slashPos != std::wstring::npos) {
        parts.host = wurl.substr(0, slashPos);
        parts.path = wurl.substr(slashPos);
    } else {
        parts.host = wurl;
        parts.path = L"/";
    }

    // Check for port in host
    auto colonPos = parts.host.find(L':');
    if (colonPos != std::wstring::npos) {
        parts.port = std::stoi(parts.host.substr(colonPos + 1));
        parts.host = parts.host.substr(0, colonPos);
    }

    return parts;
}

ApiResponse ApiClient::request(const std::string& method,
                                const std::string& path,
                                const std::string& body,
                                bool needsAuth) {
    ApiResponse response;
    std::string fullUrl = baseUrl_ + path;

    // Add api_key as query param
    std::string urlWithKey = fullUrl;
    if (urlWithKey.find('?') != std::string::npos)
        urlWithKey += "&api_key=" + apiKey_;
    else
        urlWithKey += "?api_key=" + apiKey_;

    auto parts = parseUrl(urlWithKey);

    HINTERNET hSession = WinHttpOpen(L"VirentControlCenter/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) { response.error = "WinHttpOpen failed"; return response; }

    HINTERNET hConnect = WinHttpConnect(hSession, parts.host.c_str(),
        parts.port, 0);
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        response.error = "WinHttpConnect failed";
        return response;
    }

    DWORD flags = parts.https ? WINHTTP_FLAG_SECURE : 0;
    std::wstring wmethod(method.begin(), method.end());

    HINTERNET hRequest = WinHttpOpenRequest(hConnect, wmethod.c_str(),
        parts.path.c_str(), nullptr, WINHTTP_NO_REFERER,
        WINHTTP_DEFAULT_ACCEPT_TYPES, flags);
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        response.error = "WinHttpOpenRequest failed";
        return response;
    }

    // Headers
    std::wstring headers = L"Content-Type: application/json\r\n";
    if (needsAuth && !token_.empty()) {
        headers += L"x-access-token: " + std::wstring(token_.begin(), token_.end()) + L"\r\n";
    }

    // Send
    DWORD bodyLen = body.empty() ? 0 : static_cast<DWORD>(body.length());
    BOOL bResult = WinHttpSendRequest(hRequest,
        headers.c_str(), static_cast<DWORD>(headers.length()),
        body.empty() ? WINHTTP_NO_REQUEST_DATA : const_cast<char*>(body.data()),
        bodyLen, bodyLen, 0);

    if (!bResult) {
        response.error = "WinHttpSendRequest failed: " + std::to_string(GetLastError());
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return response;
    }

    bResult = WinHttpReceiveResponse(hRequest, nullptr);
    if (!bResult) {
        response.error = "WinHttpReceiveResponse failed: " + std::to_string(GetLastError());
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return response;
    }

    // Status code
    DWORD statusCode = 0;
    DWORD statusCodeSize = sizeof(statusCode);
    WinHttpQueryHeaders(hRequest,
        WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
        WINHTTP_HEADER_NAME_BY_INDEX, &statusCode, &statusCodeSize, 0);
    response.statusCode = static_cast<int>(statusCode);

    // Read body
    DWORD bytesAvailable = 0;
    while (WinHttpQueryDataAvailable(hRequest, &bytesAvailable) && bytesAvailable > 0) {
        std::vector<char> buf(bytesAvailable + 1, 0);
        DWORD bytesRead = 0;
        if (WinHttpReadData(hRequest, buf.data(), bytesAvailable, &bytesRead)) {
            response.body.append(buf.data(), bytesRead);
        }
    }

    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    LOG_DEBUG("API " + method + " " + path + " -> " + std::to_string(response.statusCode));
    return response;
}

bool ApiClient::login() {
    std::string body = "{\"email\":\"" + email_ + "\",\"password\":\"" +
                       password_ + "\",\"api_key\":\"" + apiKey_ +
                       "\",\"apiKey\":\"" + apiKey_ + "\"}";

    auto resp = post("/auth/login/server/admin", body);
    if (!resp.success()) {
        LOG_ERROR("Login failed: " + resp.body);
        return false;
    }

    // Simple JSON token extraction (avoid full JSON parser)
    auto pos = resp.body.find("\"token\":\"");
    if (pos == std::string::npos) return false;
    pos += 9;
    auto end = resp.body.find("\"", pos);
    if (end == std::string::npos) return false;
    token_ = resp.body.substr(pos, end - pos);

    LOG_INFO("Admin login successful, token acquired");
    return true;
}

ApiResponse ApiClient::get(const std::string& path) {
    return request("GET", path, "", true);
}

ApiResponse ApiClient::post(const std::string& path, const std::string& body) {
    return request("POST", path, body, true);
}

ApiResponse ApiClient::put(const std::string& path, const std::string& body) {
    return request("PUT", path, body, true);
}

ApiResponse ApiClient::del(const std::string& path) {
    return request("DELETE", path, "", true);
}

ApiResponse ApiClient::getHealth() {
    // No auth needed for /health
    return request("GET", "/../health", "", false);
}

ApiResponse ApiClient::getDashboard(DashboardStats& outStats) {
    auto resp = get("/views/dashboard?sections=main,revenue,fleet");
    if (!resp.success()) return resp;

    // Simple string-based extraction (avoids JSON parser dependency)
    auto extractInt = [&](const std::string& key) -> int {
        auto pos = resp.body.find("\"" + key + "\":");
        if (pos == std::string::npos) return 0;
        pos += key.length() + 3;
        return atoi(resp.body.c_str() + pos);
    };

    outStats.totalScooters = extractInt("total");
    outStats.availableScooters = extractInt("available");
    outStats.inUseScooters = extractInt("in_use");
    outStats.chargingScooters = extractInt("charging");
    outStats.maintenanceScooters = extractInt("maintenance");
    outStats.totalUsers = extractInt("total");
    outStats.totalCities = extractInt("total");
    outStats.tripsToday = extractInt("today");

    return resp;
}

ApiResponse ApiClient::getScooters(std::vector<ScooterInfo>& outScooters) {
    auto resp = get("/scooters");
    if (!resp.success()) return resp;

    // Very simple parsing — split by scooter objects
    // In production, use a proper JSON parser (nlohmann/json)
    outScooters.clear();
    size_t pos = 0;
    while ((pos = resp.body.find("\"_id\":", pos)) != std::string::npos) {
        ScooterInfo s;

        // Extract _id
        auto vStart = resp.body.find("\"", pos + 6) + 1;
        auto vEnd = resp.body.find("\"", vStart);
        s.id = resp.body.substr(vStart, vEnd - vStart);

        // Extract name
        auto namePos = resp.body.find("\"name\":", vEnd);
        if (namePos != std::string::npos) {
            auto ns = resp.body.find("\"", namePos + 7) + 1;
            auto ne = resp.body.find("\"", ns);
            s.name = resp.body.substr(ns, ne - ns);
        }

        // Extract status
        auto statusPos = resp.body.find("\"status\":", vEnd);
        if (statusPos != std::string::npos) {
            auto ss = resp.body.find("\"", statusPos + 9) + 1;
            auto se = resp.body.find("\"", ss);
            s.status = resp.body.substr(ss, se - ss);
        }

        // Extract battery
        auto batPos = resp.body.find("\"battery\":", vEnd);
        if (batPos != std::string::npos) {
            s.battery = atof(resp.body.c_str() + batPos + 10);
        }

        // Extract mac_address
        auto macPos = resp.body.find("\"mac_address\":", vEnd);
        if (macPos != std::string::npos) {
            auto ms = resp.body.find("\"", macPos + 14) + 1;
            auto me = resp.body.find("\"", ms);
            if (me > ms && me - ms < 50)
                s.macAddress = resp.body.substr(ms, me - ms);
        }

        outScooters.push_back(s);
        pos = vEnd;
    }

    return resp;
}

ApiResponse ApiClient::registerScooter(const std::string& cityId,
                                        double lat, double lng,
                                        int battery, const std::string& status) {
    std::string body = "{\"owner\":\"" + cityId +
        "\",\"longitude\":\"" + std::to_string(lng) +
        "\",\"latitude\":\"" + std::to_string(lat) +
        "\",\"battery\":" + std::to_string(battery) +
        ",\"status\":\"" + status + "\"}";
    return post("/scooters", body);
}

ApiResponse ApiClient::updateScooterStatus(const std::string& scooterId,
                                            const std::string& status) {
    std::string body = "{\"scooter_id\":\"" + scooterId +
        "\",\"status\":\"" + status + "\"}";
    return put("/scooters/status", body);
}

ApiResponse ApiClient::sendScooterCommand(const std::string& macAddress,
                                           const std::string& command) {
    std::string body = "{\"scooter_mac\":\"" + macAddress +
        "\",\"command\":\"" + command + "\"}";
    return post("/iot/command/send", body);
}

ApiResponse ApiClient::getCities(std::string& outJson) {
    auto resp = get("/cities");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getUsers(std::string& outJson) {
    auto resp = get("/users");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getTrips(std::string& outJson) {
    auto resp = get("/trips");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getSystemInfo(std::string& outJson) {
    auto resp = get("/system/info");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getMetrics(std::string& outMetrics) {
    // No auth needed for /metrics
    return request("GET", "/../metrics", "", false);
}

// ===== New admin endpoint wrappers =====

ApiResponse ApiClient::getCitiesOverview(std::string& outJson) {
    auto resp = get("/cities/overview");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getZones(std::string& outJson) {
    // Zones are part of cities — get all cities then aggregate zones
    auto resp = get("/cities");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getUsersOverview(std::string& outJson) {
    auto resp = get("/users/overview");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getUserHistory(const std::string& userId, std::string& outJson) {
    auto resp = get("/users/history?user_id=" + userId);
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getActiveTrips(std::string& outJson) {
    auto resp = get("/trips/active");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getTripHistory(std::string& outJson) {
    auto resp = get("/trips/history");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getScootersJson(std::string& outJson) {
    auto resp = get("/scooters");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getPrepaids(std::string& outJson) {
    auto resp = get("/prepaids");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::createPrepaid(const std::string& body, std::string& outJson) {
    auto resp = post("/prepaids", body);
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::updatePrepaid(const std::string& body, std::string& outJson) {
    auto resp = put("/prepaids", body);
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::deletePrepaid(const std::string& prepaidId) {
    return del("/prepaids?prepaid_id=" + prepaidId);
}

ApiResponse ApiClient::getJuicers(std::string& outJson) {
    auto resp = get("/juicers");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getJuicerTasks(std::string& outJson) {
    auto resp = get("/juicers/tasks/available");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getSupportTickets(std::string& outJson) {
    auto resp = get("/support/admin/list");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::replySupportTicket(const std::string& ticketId, const std::string& message) {
    std::string body = "{\"message\":\"" + message + "\"}";
    return post("/support/admin/" + ticketId + "/reply", body);
}

ApiResponse ApiClient::getAuditLog(std::string& outJson) {
    auto resp = get("/audit-log?limit=100");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getStats(std::string& outJson) {
    auto resp = get("/stats");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::sendIoTCommand(const std::string& scooterId, const std::string& command) {
    std::string body = "{\"scooter_id\":\"" + scooterId +
        "\",\"command\":\"" + command + "\"}";
    return post("/iot/command/send", body);
}

// ===== Extended admin features (admin_ext.js) =====

ApiResponse ApiClient::blockUser(const std::string& userId, const std::string& reason) {
    std::string body = "{\"reason\":\"" + reason + "\"}";
    return post("/admin/users/" + userId + "/block", body);
}

ApiResponse ApiClient::unblockUser(const std::string& userId) {
    return post("/admin/users/" + userId + "/unblock", "{}");
}

ApiResponse ApiClient::adjustUserBalance(const std::string& userId, double delta, const std::string& reason) {
    std::string body = "{\"delta\":" + std::to_string(delta) +
        ",\"reason\":\"" + reason + "\"}";
    return post("/admin/users/" + userId + "/adjust-balance", body);
}

ApiResponse ApiClient::refundTrip(const std::string& tripId, double amount, const std::string& reason) {
    std::string body = "{\"amount\":" + std::to_string(amount) +
        ",\"reason\":\"" + reason + "\"}";
    return post("/admin/trips/" + tripId + "/refund", body);
}

ApiResponse ApiClient::bulkGeneratePrepaids(int count, double amount, const std::string& prefix, int expiresInDays, std::string& outJson) {
    std::string body = "{\"count\":" + std::to_string(count) +
        ",\"amount\":" + std::to_string(amount) +
        ",\"prefix\":\"" + prefix + "\"" +
        ",\"expires_in_days\":" + std::to_string(expiresInDays) + "}";
    auto resp = post("/admin/prepaids/bulk", body);
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::sendNotification(const std::string& title, const std::string& body, const std::string& segment) {
    std::string payload = "{\"title\":\"" + title +
        "\",\"body\":\"" + body +
        "\",\"segment\":\"" + segment + "\"}";
    return post("/admin/notifications/send", payload);
}

ApiResponse ApiClient::getNotificationStats(std::string& outJson) {
    auto resp = get("/admin/notifications/stats");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::retireScooter(const std::string& scooterId, const std::string& reason) {
    std::string body = "{\"reason\":\"" + reason + "\"}";
    return post("/admin/scooters/" + scooterId + "/retire", body);
}

ApiResponse ApiClient::getScooterTelemetry(const std::string& scooterId, std::string& outJson) {
    auto resp = get("/admin/scooters/" + scooterId + "/telemetry?limit=100");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::getScooterCommands(const std::string& scooterId, std::string& outJson) {
    auto resp = get("/admin/scooters/" + scooterId + "/commands?limit=50");
    if (resp.success()) outJson = resp.body;
    return resp;
}

ApiResponse ApiClient::closeSupportTicket(const std::string& ticketId, const std::string& resolution) {
    std::string body = "{\"resolution\":\"" + resolution + "\"}";
    return post("/admin/support/" + ticketId + "/close", body);
}

ApiResponse ApiClient::reopenSupportTicket(const std::string& ticketId) {
    return post("/admin/support/" + ticketId + "/reopen", "{}");
}

ApiResponse ApiClient::assignSupportTicket(const std::string& ticketId, const std::string& assignee) {
    std::string body = "{\"assignee\":\"" + assignee + "\"}";
    return post("/admin/support/" + ticketId + "/assign", body);
}

ApiResponse ApiClient::getAuditLogFiltered(const std::string& actor, const std::string& action,
                                           const std::string& entity, const std::string& from,
                                           const std::string& to, std::string& outJson) {
    std::string q;
    auto add = [&](const std::string& k, const std::string& v) {
        if (!v.empty()) q += (q.empty() ? "?" : "&") + k + "=" + v;
    };
    add("actor", actor);
    add("action", action);
    add("entity", entity);
    add("from", from);
    add("to", to);
    add("limit", "100");
    auto resp = get("/admin/audit-log" + q);
    if (resp.success()) outJson = resp.body;
    return resp;
}

// ===== JSON parser implementation =====

JsonValue JsonValue::null_;

static const char* skipWhitespace(const char* p) {
    while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
    return p;
}

static const char* parseValue(const char* p, JsonValue& out);

static const char* parseString(const char* p, std::string& out) {
    // p points at opening quote
    if (*p != '"') return nullptr;
    p++;
    out.clear();
    while (*p && *p != '"') {
        if (*p == '\\' && *(p + 1)) {
            p++;
            switch (*p) {
                case 'n':  out += '\n'; break;
                case 't':  out += '\t'; break;
                case 'r':  out += '\r'; break;
                case '"':  out += '"';  break;
                case '\\': out += '\\'; break;
                case '/':  out += '/';  break;
                case 'b':  out += '\b'; break;
                case 'f':  out += '\f'; break;
                case 'u': {
                    // Skip 4 hex chars (basic BMP support)
                    p++;
                    int code = 0;
                    for (int i = 0; i < 4 && *p; i++, p++) {
                        char c = *p;
                        code <<= 4;
                        if (c >= '0' && c <= '9') code |= c - '0';
                        else if (c >= 'a' && c <= 'f') code |= c - 'a' + 10;
                        else if (c >= 'A' && c <= 'F') code |= c - 'A' + 10;
                    }
                    p--; // back up, loop will advance
                    if (code < 0x80) out += static_cast<char>(code);
                    else if (code < 0x800) {
                        out += static_cast<char>(0xC0 | (code >> 6));
                        out += static_cast<char>(0x80 | (code & 0x3F));
                    } else {
                        out += static_cast<char>(0xE0 | (code >> 12));
                        out += static_cast<char>(0x80 | ((code >> 6) & 0x3F));
                        out += static_cast<char>(0x80 | (code & 0x3F));
                    }
                    break;
                }
                default: out += *p; break;
            }
            p++;
        } else {
            out += *p++;
        }
    }
    if (*p == '"') p++;
    return p;
}

static const char* parseObject(const char* p, JsonValue& out) {
    out.type_ = JsonValue::Type::Object;
    out.objVal_.clear();
    p = skipWhitespace(p);
    if (*p != '{') return nullptr;
    p = skipWhitespace(p + 1);
    if (*p == '}') return p + 1;

    while (*p) {
        p = skipWhitespace(p);
        std::string key;
        p = parseString(p, key);
        if (!p) return nullptr;
        p = skipWhitespace(p);
        if (*p != ':') return nullptr;
        p = skipWhitespace(p + 1);
        JsonValue val;
        p = parseValue(p, val);
        if (!p) return nullptr;
        out.objVal_[key] = std::move(val);
        p = skipWhitespace(p);
        if (*p == ',') { p++; continue; }
        if (*p == '}') return p + 1;
        return nullptr;
    }
    return nullptr;
}

static const char* parseArray(const char* p, JsonValue& out) {
    out.type_ = JsonValue::Type::Array;
    out.arrVal_.clear();
    p = skipWhitespace(p);
    if (*p != '[') return nullptr;
    p = skipWhitespace(p + 1);
    if (*p == ']') return p + 1;

    while (*p) {
        p = skipWhitespace(p);
        JsonValue val;
        p = parseValue(p, val);
        if (!p) return nullptr;
        out.arrVal_.push_back(std::move(val));
        p = skipWhitespace(p);
        if (*p == ',') { p++; continue; }
        if (*p == ']') return p + 1;
        return nullptr;
    }
    return nullptr;
}

static const char* parseNumber(const char* p, JsonValue& out) {
    out.type_ = JsonValue::Type::Number;
    char* end = nullptr;
    out.numVal_ = strtod(p, &end);
    return end;
}

static const char* parseValue(const char* p, JsonValue& out) {
    p = skipWhitespace(p);
    if (!*p) return nullptr;
    if (*p == '{') return parseObject(p, out);
    if (*p == '[') return parseArray(p, out);
    if (*p == '"') {
        out.type_ = JsonValue::Type::String;
        return parseString(p, out.strVal_);
    }
    if (strncmp(p, "true", 4) == 0) {
        out.type_ = JsonValue::Type::Bool;
        out.boolVal_ = true;
        return p + 4;
    }
    if (strncmp(p, "false", 5) == 0) {
        out.type_ = JsonValue::Type::Bool;
        out.boolVal_ = false;
        return p + 5;
    }
    if (strncmp(p, "null", 4) == 0) {
        out.type_ = JsonValue::Type::Null;
        return p + 4;
    }
    if (*p == '-' || (*p >= '0' && *p <= '9')) return parseNumber(p, out);
    return nullptr;
}

bool JsonValue::parse(const std::string& src) {
    const char* p = src.c_str();
    p = parseValue(p, *this);
    return p != nullptr;
}

std::wstring JsonValue::asWString() const {
    std::wstring ws;
    ws.reserve(strVal_.size());
    for (size_t i = 0; i < strVal_.size(); ) {
        unsigned char c = static_cast<unsigned char>(strVal_[i]);
        if (c < 0x80) { ws += static_cast<wchar_t>(c); i++; }
        else if ((c & 0xE0) == 0xC0 && i + 1 < strVal_.size()) {
            wchar_t ch = ((c & 0x1F) << 6) | (static_cast<unsigned char>(strVal_[i + 1]) & 0x3F);
            ws += ch; i += 2;
        } else if ((c & 0xF0) == 0xE0 && i + 2 < strVal_.size()) {
            wchar_t ch = ((c & 0x0F) << 12) |
                         ((static_cast<unsigned char>(strVal_[i + 1]) & 0x3F) << 6) |
                         (static_cast<unsigned char>(strVal_[i + 2]) & 0x3F);
            ws += ch; i += 3;
        } else { ws += L'?'; i++; }
    }
    return ws;
}

const JsonValue& JsonValue::operator[](const std::string& key) const {
    if (type_ != Type::Object) return null_;
    auto it = objVal_.find(key);
    if (it == objVal_.end()) return null_;
    return it->second;
}

const JsonValue& JsonValue::operator[](size_t idx) const {
    if (type_ != Type::Array || idx >= arrVal_.size()) return null_;
    return arrVal_[idx];
}

} // namespace virent
