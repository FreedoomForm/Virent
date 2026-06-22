/**
 * docker.h — Docker management for Virent Control Center
 *
 * Manages Docker containers: start, stop, restart, logs, status
 */

#pragma once
#include <string>
#include <vector>
#include <functional>
#include "config.h"

namespace virent {

struct ContainerStatus {
    std::string name;
    std::string status;      // "running", "exited", "restarting"
    std::string image;
    std::string ports;
    bool isRunning = false;
};

class Docker {
public:
    explicit Docker(AppConfig& config) : config_(config) {}

    // Check if Docker Desktop is running
    bool isAvailable();

    // Start all Virent containers
    bool startAll(std::function<void(const std::string&)> progress = nullptr);

    // Stop all Virent containers
    bool stopAll();

    // Restart all containers
    bool restartAll();

    // Rebuild containers (after code update)
    bool rebuildAll(std::function<void(const std::string&)> progress = nullptr);

    // Get status of all containers
    std::vector<ContainerStatus> getStatus();

    // Get logs for a specific container
    std::string getLogs(const std::string& containerName, int lines = 100);

    // Seed database with test data
    bool seedDatabase();

    // Backup database
    bool backupDatabase(const std::string& backupPath);

    // Restore database from backup
    bool restoreDatabase(const std::string& backupFile);

    // Get database stats
    std::string getDbStats();

    // Execute command in container
    std::string execInContainer(const std::string& container,
                                const std::string& command);

private:
    AppConfig& config_;

    std::string getComposeCmd();
    std::string getComposeFile();
};

} // namespace virent
