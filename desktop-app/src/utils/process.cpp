/**
 * process.cpp — Windows process execution
 */

#include "process.h"
#include "logger.h"
#include <windows.h>
#include <tlhelp32.h>
#include <algorithm>

namespace virent {

ProcessResult Process::run(const std::string& command,
                           const std::string& workingDir,
                           int timeoutMs) {
    ProcessResult result;

    SECURITY_ATTRIBUTES sa = {};
    sa.nLength = sizeof(sa);
    sa.bInheritHandle = TRUE;

    HANDLE hStdoutRead = nullptr, hStdoutWrite = nullptr;
    HANDLE hStderrRead = nullptr, hStderrWrite = nullptr;

    CreatePipe(&hStdoutRead, &hStdoutWrite, &sa, 0);
    CreatePipe(&hStderrRead, &hStderrWrite, &sa, 0);
    SetHandleInformation(hStdoutRead, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(hStderrRead, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOA si = {};
    si.cb = sizeof(si);
    si.hStdOutput = hStdoutWrite;
    si.hStdError = hStderrWrite;
    si.dwFlags |= STARTF_USESTDHANDLES;

    PROCESS_INFORMATION pi = {};

    // Build command with cmd /c
    std::string fullCmd = "cmd /c " + command;
    char* cwd = workingDir.empty() ? nullptr :
        const_cast<char*>(workingDir.c_str());

    BOOL ok = CreateProcessA(
        nullptr,
        const_cast<LPSTR>(fullCmd.c_str()),
        nullptr, nullptr, TRUE,
        CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT,
        nullptr, cwd, &si, &pi
    );

    CloseHandle(hStdoutWrite);
    CloseHandle(hStderrWrite);

    if (!ok) {
        result.exitCode = -1;
        result.err = "CreateProcess failed: " + std::to_string(GetLastError());
        CloseHandle(hStdoutRead);
        CloseHandle(hStderrRead);
        return result;
    }

    // Read stdout
    DWORD bytesRead;
    char buf[4096];
    while (ReadFile(hStdoutRead, buf, sizeof(buf), &bytesRead, nullptr) && bytesRead > 0) {
        result.out.append(buf, bytesRead);
    }
    while (ReadFile(hStderrRead, buf, sizeof(buf), &bytesRead, nullptr) && bytesRead > 0) {
        result.err.append(buf, bytesRead);
    }

    WaitForSingleObject(pi.hProcess, timeoutMs);
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    result.exitCode = static_cast<int>(exitCode);

    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    CloseHandle(hStdoutRead);
    CloseHandle(hStderrRead);

    LOG_DEBUG("Process: " + command + " -> exit " + std::to_string(result.exitCode));
    return result;
}

bool Process::runAsync(const std::string& command, const std::string& workingDir) {
    STARTUPINFOA si = {};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    PROCESS_INFORMATION pi = {};
    std::string fullCmd = "cmd /c start /b " + command;
    char* cwd = workingDir.empty() ? nullptr :
        const_cast<char*>(workingDir.c_str());

    BOOL ok = CreateProcessA(nullptr, const_cast<LPSTR>(fullCmd.c_str()),
        nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, cwd, &si, &pi);

    if (ok) {
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }
    return ok;
}

bool Process::commandExists(const std::string& command) {
    auto result = run("where " + command);
    return result.success();
}

std::optional<std::string> Process::which(const std::string& command) {
    auto result = run("where " + command);
    if (!result.success()) return std::nullopt;
    // Take first line
    auto pos = result.out.find('\n');
    std::string path = (pos == std::string::npos) ? result.out : result.out.substr(0, pos);
    // Trim whitespace
    while (!path.empty() && (path.back() == '\r' || path.back() == '\n' || path.back() == ' '))
        path.pop_back();
    return path;
}

bool Process::killByName(const std::string& name) {
    auto result = run("taskkill /f /im " + name);
    return result.success();
}

bool Process::isDockerRunning() {
    auto result = run("docker info");
    return result.success();
}

std::vector<std::string> Process::getDockerContainers() {
    std::vector<std::string> containers;
    auto result = run("docker ps --format {{.Names}}");
    if (!result.success()) return containers;

    std::string line;
    std::istringstream stream(result.out);
    while (std::getline(stream, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == '\n'))
            line.pop_back();
        if (!line.empty()) containers.push_back(line);
    }
    return containers;
}

} // namespace virent
