/**
 * admin_tabs.cpp — All admin tab implementations for Virent Control Center
 *
 * Design goals:
 *   - Each admin tab is a 1:1 port of the former admin website page
 *   - One ListView per tab, populated from cached JSON
 *   - Reusable helpers for: column setup, row insertion, search filter,
 *     footer status line
 *   - Data freshness: 30 s TTL, manual Refresh forces a re-fetch
 *
 * The bulk of the per-tab code is a TabSpec table (columns + cell extractor).
 * Adding a new admin tab is a 10-line change to the table.
 */

#include "app.h"
#include "logger.h"
#include <commctrl.h>
#include <algorithm>
#include <chrono>
#include <functional>
#include <sstream>
#include <string>

#pragma comment(lib, "comctl32.lib")

namespace virent {

// ===================== Helpers =====================

std::wstring App::utf8ToW(const std::string& s) {
    std::wstring ws; ws.reserve(s.size());
    for (size_t i = 0; i < s.size(); ) {
        unsigned char c = static_cast<unsigned char>(s[i]);
        if (c < 0x80)                { ws += static_cast<wchar_t>(c); i++; }
        else if ((c & 0xE0) == 0xC0 && i + 1 < s.size()) {
            ws += static_cast<wchar_t>(((c & 0x1F) << 6) |
                  (static_cast<unsigned char>(s[i + 1]) & 0x3F));
            i += 2;
        } else if ((c & 0xF0) == 0xE0 && i + 2 < s.size()) {
            ws += static_cast<wchar_t>(((c & 0x0F) << 12) |
                  ((static_cast<unsigned char>(s[i + 1]) & 0x3F) << 6) |
                  (static_cast<unsigned char>(s[i + 2]) & 0x3F));
            i += 3;
        } else { ws += L'?'; i++; }
    }
    return ws;
}

std::string App::wToUtf8(const std::wstring& ws) {
    std::string s; s.reserve(ws.size() * 2);
    for (wchar_t wc : ws) {
        if (wc < 0x80) s += static_cast<char>(wc);
        else if (wc < 0x800) {
            s += static_cast<char>(0xC0 | (wc >> 6));
            s += static_cast<char>(0x80 | (wc & 0x3F));
        } else {
            s += static_cast<char>(0xE0 | (wc >> 12));
            s += static_cast<char>(0x80 | ((wc >> 6) & 0x3F));
            s += static_cast<char>(0x80 | (wc & 0x3F));
        }
    }
    return s;
}

bool TabCache::isStale(int64_t t, int maxAgeMs) const {
    if (t == 0) return true;
    auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    return (now - t) > maxAgeMs;
}

// ===================== ListView helpers =====================

static void addListColumn(HWND hList, int idx, const wchar_t* text, int width) {
    LVCOLUMNW col = {};
    col.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_FMT;
    col.fmt = LVCFMT_LEFT;
    col.cx = width;
    col.pszText = const_cast<LPWSTR>(text);
    ListView_InsertColumn(hList, idx, &col);
}

static int addListRow(HWND hList, int row, const std::vector<std::wstring>& cells) {
    LVITEMW item = {};
    item.mask = LVIF_TEXT;
    item.iItem = row;
    item.iSubItem = 0;
    item.pszText = const_cast<LPWSTR>(cells.empty() ? L"" : cells[0].c_str());
    int inserted = ListView_InsertItem(hList, &item);
    for (size_t i = 1; i < cells.size(); i++) {
        ListView_SetItemText(hList, inserted, static_cast<int>(i),
            const_cast<LPWSTR>(cells[i].c_str()));
    }
    return inserted;
}

static std::wstring getSearchText(HWND hSearch) {
    int len = GetWindowTextLengthW(hSearch);
    std::wstring s(len + 1, 0);
    GetWindowTextW(hSearch, s.data(), len + 1);
    s.resize(len);
    return s;
}

static bool containsCI(const std::wstring& haystack, const std::wstring& needle) {
    if (needle.empty()) return true;
    if (haystack.size() < needle.size()) return false;
    return std::search(haystack.begin(), haystack.end(),
        needle.begin(), needle.end(),
        [](wchar_t a, wchar_t b) { return towlower(a) == towlower(b); })
        != haystack.end();
}

static std::wstring numStr(const JsonValue& v) {
    wchar_t buf[32]; swprintf_s(buf, L"%.0f", v.asNumber()); return buf;
}

static std::wstring floatStr(const JsonValue& v, const wchar_t* fmt = L"%.0f") {
    wchar_t buf[32]; swprintf_s(buf, fmt, v.asNumber()); return buf;
}

// ===================== Tab lifecycle =====================

void App::hideAllTabUI() {
    for (int i = 0; i < NavItemsCount; i++) {
        auto& ui = tabUI_[i];
        if (!ui.created) continue;
        ShowWindow(ui.hList,        SW_HIDE);
        ShowWindow(ui.hSearch,      SW_HIDE);
        ShowWindow(ui.hSearchLabel, SW_HIDE);
        ShowWindow(ui.hRefresh,     SW_HIDE);
        ShowWindow(ui.hAdd,         SW_HIDE);
        ShowWindow(ui.hExport,      SW_HIDE);
    }
}

void App::ensureTabUI(TabId tab) {
    int idx = tabIdToInt(tab);
    if (idx < 0 || idx >= NavItemsCount) return;
    auto& ui = tabUI_[idx];

    if (ui.created) {
        ShowWindow(ui.hList,        SW_SHOW);
        ShowWindow(ui.hSearch,      SW_SHOW);
        ShowWindow(ui.hSearchLabel, SW_SHOW);
        ShowWindow(ui.hRefresh,     SW_SHOW);
        ShowWindow(ui.hAdd,         SW_SHOW);
        ShowWindow(ui.hExport,      SW_SHOW);
        return;
    }

    RECT cr; GetClientRect(hWnd_, &cr);
    const int contentLeft = Layout::SidebarW + Layout::Padding;
    const int topY = Layout::HeaderH + Layout::Padding;
    const int searchY = topY + 90;
    const int listY = searchY + Layout::InputH + 10;
    const int listH = cr.bottom - listY - Layout::Padding - 30;
    const int contentW = cr.right - contentLeft - Layout::Padding;

    ui.hSearchLabel = CreateWindowW(L"STATIC", L"Search:",
        WS_CHILD | WS_VISIBLE | SS_LEFT,
        contentLeft, searchY + 6, 60, 20, hWnd_, nullptr, hInstance_, nullptr);
    SendMessageW(ui.hSearchLabel, WM_SETFONT, (WPARAM)hFontMain_, TRUE);

    ui.hSearch = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
        WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
        contentLeft + 65, searchY, Layout::SearchW, Layout::InputH,
        hWnd_, (HMENU)(INT_PTR)(IDC_TAB_SEARCH_BASE + idx), hInstance_, nullptr);
    SendMessageW(ui.hSearch, WM_SETFONT, (WPARAM)hFontMain_, TRUE);

    auto makeBtn = [&](int id, const wchar_t* text, int x) {
        HWND h = CreateWindowW(L"BUTTON", text,
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            x, searchY, 100, Layout::ButtonH,
            hWnd_, (HMENU)(INT_PTR)id, hInstance_, nullptr);
        SendMessageW(h, WM_SETFONT, (WPARAM)hFontMain_, TRUE);
        return h;
    };
    int bx = contentLeft + 65 + Layout::SearchW + 10;
    ui.hRefresh = makeBtn(IDC_TAB_REFRESH_BASE + idx, L"Refresh", bx);
    ui.hAdd     = makeBtn(IDC_TAB_ADD_BASE    + idx, L"Add New",  bx + 110);
    ui.hExport  = makeBtn(IDC_TAB_EXPORT_BASE + idx, L"Export CSV", bx + 220);

    ui.hList = CreateWindowExW(0, WC_LISTVIEWW, L"",
        WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_SHOWSELALWAYS |
        LVS_SINGLESEL | WS_BORDER | WS_VSCROLL | WS_HSCROLL,
        contentLeft, listY, contentW, listH,
        hWnd_, (HMENU)(INT_PTR)(IDC_TAB_LIST_BASE + idx), hInstance_, nullptr);
    SendMessageW(ui.hList, WM_SETFONT, (WPARAM)hFontMain_, TRUE);
    ListView_SetExtendedListViewStyleEx(ui.hList,
        LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER | LVS_EX_GRIDLINES,
        LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER | LVS_EX_GRIDLINES);

    ui.created = true;
    refreshTabData(tab);
    populateListView(tab);
}

void App::buildStandardTabHeader(TabId tab, HDC hdc, RECT& rect, const wchar_t* title) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);
    HFONT oldFont = (HFONT)SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, title, static_cast<int>(wcslen(title)));
    SelectObject(hdc, hFontMain_);

    y += 36;
    SetTextColor(hdc, Color::TextMuted);
    SelectObject(hdc, hFontSmall_);
    const wchar_t* desc = L"";
    switch (tab) {
        case TabId::Scooters:  desc = L"Fleet inventory - scan, register, command, update firmware."; break;
        case TabId::Trips:     desc = L"Trip history with filters and trip detail drawer."; break;
        case TabId::Customers: desc = L"Customer accounts, balance, status, ride history."; break;
        case TabId::Cities:    desc = L"Cities with rates, tax zones and geofencing."; break;
        case TabId::Zones:     desc = L"Parking / no-ride / slow zones per city."; break;
        case TabId::AuditLog:  desc = L"Append-only audit trail of admin actions."; break;
        case TabId::Prepaid:   desc = L"Prepaid card inventory and usage tracking."; break;
        case TabId::Juicers:   desc = L"Charging team - juicer accounts and tasks."; break;
        case TabId::Support:   desc = L"Customer support tickets - reply and resolve."; break;
        case TabId::IoT:       desc = L"Send remote commands to scooters (lock / unlock / alarm / reboot)."; break;
        default: break;
    }
    if (*desc) TextOutW(hdc, x, y, desc, static_cast<int>(wcslen(desc)));
    SelectObject(hdc, hFontMain_);
    SelectObject(hdc, oldFont);
}

// ===================== Refresh =====================

void App::refreshCurrentTab() {
    refreshTabData(currentTab_);
    populateListView(currentTab_);
    InvalidateRect(hWnd_, nullptr, FALSE);
}

void App::refreshTabData(TabId tab) {
    if (!api_ || !api_->isLoggedIn()) return;
    auto now = [] {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    };
    switch (tab) {
        case TabId::Scooters:
            if (cache_.isStale(cache_.scootersLoadedAt)) {
                api_->getScooters(cache_.scooters);
                cache_.scootersLoadedAt = now();
            }
            break;
        case TabId::Trips:
            if (cache_.isStale(cache_.tripsLoadedAt)) {
                api_->getTrips(cache_.tripsJson);
                cache_.tripsLoadedAt = now();
            }
            break;
        case TabId::Customers:
            if (cache_.isStale(cache_.usersLoadedAt)) {
                api_->getUsers(cache_.usersJson);
                cache_.usersLoadedAt = now();
            }
            break;
        case TabId::Cities:
        case TabId::Zones:
            if (cache_.isStale(cache_.citiesLoadedAt)) {
                api_->getCities(cache_.citiesJson);
                cache_.citiesLoadedAt = now();
            }
            break;
        case TabId::AuditLog:
            if (cache_.isStale(cache_.auditLogLoadedAt)) {
                api_->getAuditLog(cache_.auditLogJson);
                cache_.auditLogLoadedAt = now();
            }
            break;
        case TabId::Prepaid:
            if (cache_.isStale(cache_.prepaidsLoadedAt)) {
                api_->getPrepaids(cache_.prepaidsJson);
                cache_.prepaidsLoadedAt = now();
            }
            break;
        case TabId::Juicers:
            if (cache_.isStale(cache_.juicersLoadedAt)) {
                api_->getJuicers(cache_.juicersJson);
                cache_.juicersLoadedAt = now();
            }
            break;
        case TabId::Support:
            if (cache_.isStale(cache_.supportLoadedAt)) {
                api_->getSupportTickets(cache_.supportJson);
                cache_.supportLoadedAt = now();
            }
            break;
        case TabId::Analytics:
            if (cache_.isStale(cache_.statsLoadedAt)) {
                api_->getStats(cache_.statsJson);
                api_->getMetrics(cache_.metricsJson);
                cache_.statsLoadedAt = now();
            }
            break;
        default: break;
    }
}

// ===================== populateListView =====================
//
// Per-tab spec: a list of {header, width, cell-extractor} triples.
// Cell extractor reads from a JsonValue item (one row of the data array).
// Search filter is applied against the joined cell text, case-insensitive.
//
// Adding a new admin tab:
//   1. Add it to theme.h NavItems[]
//   2. Add a `case TabId::Foo:` block here that defines columns + extractors
//   3. Add the cache fields + refresh block in refreshTabData()
//
using CellFn = std::function<std::wstring(const JsonValue&)>;
struct Col { const wchar_t* header; int width; CellFn cell; };

void App::populateListView(TabId tab) {
    int idx = tabIdToInt(tab);
    if (idx < 0 || idx >= NavItemsCount) return;
    if (!tabUI_[idx].created) return;
    HWND hList = tabUI_[idx].hList;
    const std::wstring q = tabUI_[idx].hSearch ? getSearchText(tabUI_[idx].hSearch) : L"";
    ListView_DeleteAllItems(hList);

    auto setupCols = [&](std::vector<Col>& cols) {
        if (ListView_GetColumnWidth(hList, 0) == 0) {
            for (size_t i = 0; i < cols.size(); i++) {
                addListColumn(hList, static_cast<int>(i), cols[i].header, cols[i].width);
            }
        }
    };
    auto fillRows = [&](const JsonValue& data, const std::vector<Col>& cols) {
        if (!data.isArray()) return;
        int row = 0;
        for (const auto& item : data.array()) {
            std::vector<std::wstring> cells;
            std::wstring joined;
            for (const auto& c : cols) {
                std::wstring v = c.cell(item);
                joined += L" " + v;
                cells.push_back(v);
            }
            if (!q.empty() && !containsCI(joined, q)) continue;
            addListRow(hList, row++, cells);
        }
    };

    switch (tab) {
        case TabId::Scooters: {
            // Scooters use the parsed ScooterInfo cache (not raw JSON)
            int row = 0;
            for (const auto& s : cache_.scooters) {
                std::wstring name = utf8ToW(s.name);
                if (!q.empty() && !containsCI(name, q)) continue;
                wchar_t bat[16]; swprintf_s(bat, L"%.0f%%", s.battery);
                addListRow(hList, row++, {
                    name, utf8ToW(s.model), utf8ToW(s.status),
                    bat, utf8ToW(s.macAddress), utf8ToW(s.lastSeen)
                });
            }
            break;
        }
        case TabId::Trips: {
            std::vector<Col> cols = {
                { L"Trip ID",  200, [](const JsonValue& t){ return t["_id"].asWString(); } },
                { L"User",     180, [](const JsonValue& t){ return t["user_id"].asWString(); } },
                { L"Scooter",  160, [](const JsonValue& t){ return t["scooter_id"].asWString(); } },
                { L"Start",    160, [](const JsonValue& t){ return t["start_time"].asWString(); } },
                { L"End",      160, [](const JsonValue& t){ return t["end_time"].asWString(); } },
                { L"Distance",  90, [](const JsonValue& t){ wchar_t b[32]; swprintf_s(b, L"%.1f km", t["distance_km"].asNumber()); return b; } },
                { L"Cost",      80, [](const JsonValue& t){ return floatStr(t["cost"]); } },
                { L"Status",    90, [](const JsonValue& t){ return t["status"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.tripsJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Customers: {
            std::vector<Col> cols = {
                { L"Name",    160, [](const JsonValue& u){ return u["name"].asWString(); } },
                { L"Email",   220, [](const JsonValue& u){ return u["email"].asWString(); } },
                { L"Phone",   140, [](const JsonValue& u){ return u["phone"].asWString(); } },
                { L"Balance", 100, [](const JsonValue& u){ return floatStr(u["balance"]); } },
                { L"Status",  100, [](const JsonValue& u){ return u["status"].asWString(); } },
                { L"Trips",    70, [](const JsonValue& u){ return numStr(u["trips_count"]); } },
                { L"Joined",  160, [](const JsonValue& u){ return u["created_at"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.usersJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Cities: {
            std::vector<Col> cols = {
                { L"City",         180, [](const JsonValue& c){ return c["name"].asWString(); } },
                { L"Scooters",      90, [](const JsonValue& c){ return numStr(c["scooters_count"]); } },
                { L"Active",        80, [](const JsonValue& c){ return numStr(c["active_count"]); } },
                { L"Rate (start)", 100, [](const JsonValue& c){ return floatStr(c["start_rate"]); } },
                { L"Rate (min)",   100, [](const JsonValue& c){ return floatStr(c["minute_rate"]); } },
                { L"Tax %",         70, [](const JsonValue& c){ wchar_t b[16]; swprintf_s(b, L"%.0f%%", c["tax_percent"].asNumber()); return b; } },
                { L"Zones",         70, [](const JsonValue& c){
                    int n = c["zones"].isArray() ? static_cast<int>(c["zones"].array().size()) : 0;
                    wchar_t b[16]; swprintf_s(b, L"%d", n); return b;
                } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.citiesJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Zones: {
            std::vector<Col> cols = {
                { L"City",        160, [](const JsonValue& z){ return z["city_name"].asWString(); } },
                { L"Zone name",   200, [](const JsonValue& z){ return z["name"].asWString(); } },
                { L"Type",        100, [](const JsonValue& z){ return z["type"].asWString(); } },
                { L"Speed limit", 100, [](const JsonValue& z){ wchar_t b[16]; swprintf_s(b, L"%d km/h", z["speed_limit"].asInt()); return b; } },
                { L"Points",       80, [](const JsonValue& z){
                    int n = z["polygon"].isArray() ? static_cast<int>(z["polygon"].array().size()) : 0;
                    wchar_t b[16]; swprintf_s(b, L"%d", n); return b;
                } },
            };
            setupCols(cols);
            JsonValue root;
            if (root.parse(cache_.citiesJson) && root["data"].isArray()) {
                int row = 0;
                for (const auto& c : root["data"].array()) {
                    std::wstring cityName = c["name"].asWString();
                    const auto& zones = c["zones"];
                    if (!zones.isArray()) continue;
                    for (const auto& z : zones.array()) {
                        std::wstring zname = z["name"].asWString();
                        if (!q.empty() && !containsCI(zname, q) && !containsCI(cityName, q)) continue;
                        std::vector<std::wstring> cells = {
                            cityName, zname, z["type"].asWString(),
                            cols[3].cell(z), cols[4].cell(z)
                        };
                        addListRow(hList, row++, cells);
                    }
                }
            }
            break;
        }
        case TabId::AuditLog: {
            std::vector<Col> cols = {
                { L"Timestamp", 180, [](const JsonValue& e){ return e["timestamp"].asWString(); } },
                { L"Actor",     180, [](const JsonValue& e){ return e["actor"].asWString(); } },
                { L"Action",    160, [](const JsonValue& e){ return e["action"].asWString(); } },
                { L"Entity",    140, [](const JsonValue& e){ return e["entity"].asWString(); } },
                { L"Entity ID", 200, [](const JsonValue& e){ return e["entity_id"].asWString(); } },
                { L"IP",        140, [](const JsonValue& e){ return e["ip"].asWString(); } },
                { L"Details",   300, [](const JsonValue& e){ return e["details"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.auditLogJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Prepaid: {
            std::vector<Col> cols = {
                { L"Code",      180, [](const JsonValue& p){ return p["code"].asWString(); } },
                { L"Amount",    100, [](const JsonValue& p){ return floatStr(p["amount"]); } },
                { L"Currency",   90, [](const JsonValue& p){ return p["currency"].asWString(); } },
                { L"Status",    100, [](const JsonValue& p){ return p["status"].asWString(); } },
                { L"Used by",   180, [](const JsonValue& p){ return p["used_by"].asWString(); } },
                { L"Used at",   180, [](const JsonValue& p){ return p["used_at"].asWString(); } },
                { L"Expires",   180, [](const JsonValue& p){ return p["expires_at"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.prepaidsJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Juicers: {
            std::vector<Col> cols = {
                { L"Name",       180, [](const JsonValue& j){ return j["name"].asWString(); } },
                { L"Phone",      140, [](const JsonValue& j){ return j["phone"].asWString(); } },
                { L"Status",     100, [](const JsonValue& j){ return j["status"].asWString(); } },
                { L"Earnings",   100, [](const JsonValue& j){ return floatStr(j["total_earnings"]); } },
                { L"Tasks done", 100, [](const JsonValue& j){ return numStr(j["tasks_completed"]); } },
                { L"Rating",      80, [](const JsonValue& j){ wchar_t b[16]; swprintf_s(b, L"%.1f", j["rating"].asNumber()); return b; } },
                { L"Joined",     160, [](const JsonValue& j){ return j["created_at"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.juicersJson)) fillRows(root["data"], cols);
            break;
        }
        case TabId::Support: {
            std::vector<Col> cols = {
                { L"Ticket",     180, [](const JsonValue& t){ return t["_id"].asWString(); } },
                { L"Subject",    260, [](const JsonValue& t){ return t["subject"].asWString(); } },
                { L"User",       180, [](const JsonValue& t){ return t["user_name"].asWString(); } },
                { L"Status",     100, [](const JsonValue& t){ return t["status"].asWString(); } },
                { L"Priority",    90, [](const JsonValue& t){ return t["priority"].asWString(); } },
                { L"Created",    160, [](const JsonValue& t){ return t["created_at"].asWString(); } },
                { L"Last reply", 160, [](const JsonValue& t){ return t["last_reply_at"].asWString(); } },
            };
            setupCols(cols);
            JsonValue root; if (root.parse(cache_.supportJson)) fillRows(root["data"], cols);
            break;
        }
        default: break;
    }
}

// ===================== Tab draw functions =====================
//
// Most admin tabs share an identical layout:
//   buildStandardTabHeader + footer status line
// The ListView is created by ensureTabUI and repositioned by WM_SIZE.

static void drawFooterCount(HDC hdc, RECT& rect, HFONT hFont, const std::wstring& line) {
    int y = rect.bottom - Layout::Padding - 24;
    SetTextColor(hdc, Color::TextMuted);
    SelectObject(hdc, hFont);
    TextOutW(hdc, rect.left + Layout::Padding, y, line.c_str(),
             static_cast<int>(line.length()));
}

static int jsonArrLen(const std::string& json, const char* key = "data") {
    JsonValue root;
    if (!root.parse(json)) return 0;
    const auto& v = root[key];
    return v.isArray() ? static_cast<int>(v.array().size()) : 0;
}

void App::drawTripsTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Trips, hdc, rect, L"Trips");
    if (!api_ || !api_->isLoggedIn()) return;
    int total = jsonArrLen(cache_.tripsJson);
    wchar_t line[128]; swprintf_s(line, L"Total: %d trips", total);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawCustomersTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Customers, hdc, rect, L"Customers");
    if (!api_ || !api_->isLoggedIn()) return;
    int total = jsonArrLen(cache_.usersJson);
    wchar_t line[128]; swprintf_s(line, L"Total: %d customers", total);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawCitiesTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Cities, hdc, rect, L"Cities");
    if (!api_ || !api_->isLoggedIn()) return;
    int total = jsonArrLen(cache_.citiesJson);
    wchar_t line[128]; swprintf_s(line, L"Total: %d cities", total);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawZonesTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Zones, hdc, rect, L"Zones");
    if (!api_ || !api_->isLoggedIn()) return;
    int zoneCount = 0;
    JsonValue root;
    if (root.parse(cache_.citiesJson) && root["data"].isArray()) {
        for (const auto& c : root["data"].array()) {
            if (c["zones"].isArray()) zoneCount += static_cast<int>(c["zones"].array().size());
        }
    }
    wchar_t line[128]; swprintf_s(line, L"Total: %d zones across all cities", zoneCount);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawAuditLogTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::AuditLog, hdc, rect, L"Audit Log");
    if (!api_ || !api_->isLoggedIn()) return;
    int total = jsonArrLen(cache_.auditLogJson);
    wchar_t line[128]; swprintf_s(line, L"Showing last %d entries (append-only)", total);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawPrepaidTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Prepaid, hdc, rect, L"Prepaid Cards");
    if (!api_ || !api_->isLoggedIn()) return;
    JsonValue root;
    int total = 0, used = 0;
    if (root.parse(cache_.prepaidsJson) && root["data"].isArray()) {
        for (const auto& p : root["data"].array()) {
            total++;
            if (p["status"].asString() == "used") used++;
        }
    }
    wchar_t line[128];
    swprintf_s(line, L"Total: %d cards   |   Used: %d   |   Available: %d",
               total, used, total - used);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawJuicersTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Juicers, hdc, rect, L"Juicers (Charging Team)");
    if (!api_ || !api_->isLoggedIn()) return;
    int total = jsonArrLen(cache_.juicersJson);
    wchar_t line[128]; swprintf_s(line, L"Total: %d juicers", total);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

void App::drawSupportTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::Support, hdc, rect, L"Support Tickets");
    if (!api_ || !api_->isLoggedIn()) return;
    JsonValue root;
    int total = 0, open = 0;
    if (root.parse(cache_.supportJson) && root["data"].isArray()) {
        for (const auto& t : root["data"].array()) {
            total++;
            std::wstring s = t["status"].asWString();
            if (s == L"open" || s == L"pending") open++;
        }
    }
    wchar_t line[128]; swprintf_s(line, L"Total: %d tickets   |   Open: %d", total, open);
    drawFooterCount(hdc, rect, hFontSmall_, line);
}

// ===================== Custom (non-ListView) tabs =====================

void App::drawMapTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);
    HFONT oldFont = (HFONT)SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, L"Map Overview", 13);
    SelectObject(hdc, hFontMain_);
    y += 36;

    SetTextColor(hdc, Color::TextMuted);
    SelectObject(hdc, hFontSmall_);
    const wchar_t* desc =
        L"Real-time map of all scooters across all cities.\n"
        L"Each dot represents a scooter - color-coded by status:\n"
        L"  - Green  = available\n"
        L"  - Blue   = in use\n"
        L"  - Yellow = charging\n"
        L"  - Red    = maintenance / offline";
    TextOutW(hdc, x, y, desc, static_cast<int>(wcslen(desc)));
    y += 120;

    RECT mapRect = {x, y, rect.right - Layout::Padding, rect.bottom - Layout::Padding};
    HBRUSH brush = CreateSolidBrush(Color::Surface);
    FillRect(hdc, &mapRect, brush);
    DeleteObject(brush);

    HPEN pen = CreatePen(PS_SOLID, 1, Color::Border);
    HPEN oldPen = (HPEN)SelectObject(hdc, pen);
    SelectObject(hdc, GetStockObject(HOLLOW_BRUSH));
    Rectangle(hdc, mapRect.left, mapRect.top, mapRect.right, mapRect.bottom);
    SelectObject(hdc, oldPen);
    DeleteObject(pen);

    SetTextColor(hdc, Color::TextMuted);
    SelectObject(hdc, hFontMain_);
    const wchar_t* msg = L"[ Native map render - integrate Mapbox GL or Bing Maps here ]";
    TextOutW(hdc, (mapRect.left + mapRect.right) / 2 - 200,
                  (mapRect.top + mapRect.bottom) / 2, msg, static_cast<int>(wcslen(msg)));
    SelectObject(hdc, oldFont);
}

void App::drawAnalyticsTab(HDC hdc, RECT& rect) {
    int x = rect.left + Layout::Padding;
    int y = rect.top + Layout::Padding;
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);
    HFONT oldFont = (HFONT)SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, L"Analytics", 9);
    SelectObject(hdc, hFontMain_);
    y += 50;

    if (!api_ || !api_->isLoggedIn()) {
        SetTextColor(hdc, Color::TextMuted);
        TextOutW(hdc, x, y, L"Not connected to API. Check server status.", 43);
        SelectObject(hdc, oldFont);
        return;
    }

    JsonValue stats;
    bool haveStats = stats.parse(cache_.statsJson);

    auto getStr = [&](const wchar_t* path) -> std::wstring {
        if (!haveStats) return L"-";
        std::wstring wpath = path ? path : L"";
        std::string p(wpath.begin(), wpath.end());
        const JsonValue& v = stats["data"][p];
        if (v.isNumber()) return floatStr(v);
        if (v.isString()) return v.asWString();
        return L"-";
    };

    int cardW = 220, cardH = 90;
    auto drawKpi = [&](const wchar_t* label, const std::wstring& value, COLORREF accent) {
        RECT r = {x, y, x + cardW, y + cardH};
        HBRUSH b = CreateSolidBrush(Color::Surface);
        FillRect(hdc, &r, b); DeleteObject(b);
        RECT bar = {x, y, x + cardW, y + 4};
        b = CreateSolidBrush(accent);
        FillRect(hdc, &bar, b); DeleteObject(b);
        SetTextColor(hdc, Color::TextMuted);
        SelectObject(hdc, hFontSmall_);
        TextOutW(hdc, x + 12, y + 14, label, static_cast<int>(wcslen(label)));
        SetTextColor(hdc, Color::TextPrimary);
        SelectObject(hdc, hFontTitle_);
        TextOutW(hdc, x + 12, y + 36, value.c_str(), static_cast<int>(value.length()));
        SelectObject(hdc, hFontMain_);
        x += cardW + Layout::CardSpacing;
    };

    drawKpi(L"Total Revenue",    getStr(L"total_revenue"),   Color::Success);
    drawKpi(L"Trips (all-time)", getStr(L"total_trips"),      Color::Info);
    drawKpi(L"Active Users",     getStr(L"active_users"),     Color::Primary);
    drawKpi(L"Avg trip cost",    getStr(L"avg_trip_cost"),    Color::Warning);

    y += cardH + Layout::Padding;
    x = rect.left + Layout::Padding;

    drawKpi(L"Scooters (fleet)", getStr(L"total_scooters"),   Color::Primary);
    drawKpi(L"Utilization %",    getStr(L"utilization"),      Color::Info);
    drawKpi(L"Total cities",     getStr(L"total_cities"),     Color::Success);
    drawKpi(L"Open tickets",     getStr(L"open_tickets"),     Color::Danger);

    y += cardH + Layout::PaddingLg;
    x = rect.left + Layout::Padding;
    SetTextColor(hdc, Color::TextPrimary);
    SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, L"Raw metrics (Prometheus)", 27);
    SelectObject(hdc, hFontMain_);
    y += 30;

    SetTextColor(hdc, Color::TextSecondary);
    SelectObject(hdc, hFontSmall_);
    if (!cache_.metricsJson.empty()) {
        std::wstring m = utf8ToW(cache_.metricsJson);
        if (m.length() > 1500) m = m.substr(0, 1500) + L"\r\n... (truncated)";
        size_t pos = 0; int maxLines = 25;
        while (pos < m.length() && maxLines-- > 0) {
            size_t nl = m.find(L'\n', pos);
            std::wstring line = m.substr(pos, nl == std::wstring::npos ? std::wstring::npos : nl - pos);
            TextOutW(hdc, x, y, line.c_str(), static_cast<int>(line.length()));
            y += 16;
            if (nl == std::wstring::npos) break;
            pos = nl + 1;
        }
    } else {
        TextOutW(hdc, x, y, L"(no metrics yet - refresh in a few seconds)", 45);
    }
    SelectObject(hdc, oldFont);
}

void App::drawIoTTab(HDC hdc, RECT& rect) {
    buildStandardTabHeader(TabId::IoT, hdc, rect, L"IoT Command Center");
    int x = rect.left + Layout::Padding;
    int y = Layout::HeaderH + 80;

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, Color::TextPrimary);
    SelectObject(hdc, hFontTitle_);
    TextOutW(hdc, x, y, L"Quick Commands", 15);
    SelectObject(hdc, hFontMain_);
    y += 36;

    SetTextColor(hdc, Color::TextSecondary);
    const wchar_t* help =
        L"Select a scooter in the list, then click a command button below.\n"
        L"Commands are queued in MQTT and acknowledged when the scooter is online.";
    TextOutW(hdc, x, y, help, static_cast<int>(wcslen(help)));
    y += 40;

    const struct { int id; const wchar_t* label; } cmds[] = {
        {IDC_CMD_LOCK_BASE,   L"Lock"    },
        {IDC_CMD_UNLOCK_BASE, L"Unlock"  },
        {IDC_CMD_ALARM_BASE,  L"Alarm"   },
        {IDC_CMD_REBOOT_BASE, L"Reboot"  },
    };
    int bx = x;
    for (const auto& c : cmds) {
        HWND hBtn = GetDlgItem(hWnd_, c.id);
        if (!hBtn) {
            hBtn = CreateWindowW(L"BUTTON", c.label,
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                bx, y, 130, Layout::ButtonH, hWnd_,
                (HMENU)(INT_PTR)c.id, hInstance_, nullptr);
            SendMessageW(hBtn, WM_SETFONT, (WPARAM)hFontMain_, TRUE);
        }
        bx += 140;
    }
}

} // namespace virent
