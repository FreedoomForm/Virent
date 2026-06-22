/**
 * process.h — Process execution utilities
 *
 * Runs external commands (docker, git, etc.) and captures output.
 */

#pragma once
#include <string>
#include <vector>
#include <optional>

namespace virent {

struct ProcessResult {
    int exitCode = -1;
    std::string out;  // renamed from 'stdout' (macro conflict on MSVC)
    std::string err;  // renamed from 'stderr' (macro conflict on MSVC)
    bool success() const { return exitCode == 0; }
};

class Process {
public:
    /**
     * Run a command and capture output
     * @param command Full command line (e.g. "docker ps")
     * @param workingDir Working directory (optional)
     * @param timeoutMs Timeout in milliseconds (0 = no timeout)
     * @return ProcessResult with stdout, stderr, exit code
     */
    static ProcessResult run(const std::string& command,
                             const std::string& workingDir = "",
                             int timeoutMs = 60000);

    /**
     * Run a command asynchronously (returns immediately)
     */
    static bool runAsync(const std::string& command,
                         const std::string& workingDir = "");

    /**
     * Check if a command/program exists
     */
    static bool commandExists(const std::string& command);

    /**
     * Get installed program path
     */
    static std::optional<std::string> which(const std::string& command);

    /**
     * Kill a process by name
     */
    static bool killByName(const std::string& name);

    /**
     * Check if Docker is running
     */
    static bool isDockerRunning();

    /**
     * Get list of running Docker containers
     */
    static std::vector<std::string> getDockerContainers();
};

} // namespace virent
