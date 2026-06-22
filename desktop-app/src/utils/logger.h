/**
 * logger.h — Simple logger for Virent Control Center
 */

#pragma once
#include <string>
#include <fstream>
#include <ctime>
#include <iomanip>
#include <filesystem>
#include <windows.h>  // for OutputDebugStringW

namespace virent {

class Logger {
public:
    enum class Level { Debug, Info, Warn, Error };

    static Logger& instance() {
        static Logger logger;
        return logger;
    }

    void init(const std::wstring& logDir) {
        std::filesystem::create_directories(logDir);
        auto t = std::time(nullptr);
        struct tm tm;
        localtime_s(&tm, &t);
        wchar_t buf[64];
        wcsftime(buf, 64, L"%Y%m%d", &tm);
        filepath_ = logDir + L"\\virent_" + buf + L".log";
    }

    void log(Level level, const std::string& msg) {
        if (!filepath_.empty()) {
            std::wofstream f(filepath_, std::ios::app);
            if (f.is_open()) {
                auto t = std::time(nullptr);
                struct tm tm;
                localtime_s(&tm, &t);
                wchar_t timebuf[32];
                wcsftime(timebuf, 32, L"%H:%M:%S", &tm);

                const wchar_t* levelStr[] = { L"DEBUG", L"INFO", L"WARN", L"ERROR" };
                f << timebuf << L" [" << levelStr[static_cast<int>(level)] << L"] "
                  << std::wstring(msg.begin(), msg.end()) << L"\n";
                f.close();
            }
        }
        // Also print to debug output
        OutputDebugStringW(std::wstring(msg.begin(), msg.end()).c_str());
        OutputDebugStringW(L"\n");
    }

    void info(const std::string& msg)  { log(Level::Info, msg); }
    void warn(const std::string& msg)  { log(Level::Warn, msg); }
    void error(const std::string& msg) { log(Level::Error, msg); }
    void debug(const std::string& msg) { log(Level::Debug, msg); }

private:
    Logger() = default;
    std::wstring filepath_;
};

#define LOG_INFO(msg)  virent::Logger::instance().info(msg)
#define LOG_WARN(msg)  virent::Logger::instance().warn(msg)
#define LOG_ERROR(msg) virent::Logger::instance().error(msg)
#define LOG_DEBUG(msg) virent::Logger::instance().debug(msg)

} // namespace virent
