/**
 * docker.cpp — Docker management implementation
 */

#include "docker.h"
#include "process.h"
#include "logger.h"
#include <filesystem>
#include <sstream>

namespace virent {

bool Docker::isAvailable() {
    return Process::isDockerRunning();
}

std::string Docker::getComposeFile() {
    return std::string(config_.installPath.begin(), config_.installPath.end()) +
           "\\docker-compose.pc.yml";
}

std::string Docker::getComposeCmd() {
    return "docker-compose -f \"" + getComposeFile() + "\"";
}

bool Docker::startAll(std::function<void(const std::string&)> progress) {
    if (progress) progress("Starting Docker containers...");

    auto result = Process::run(
        getComposeCmd() + " up -d",
        std::string(config_.installPath.begin(), config_.installPath.end())
    );

    if (!result.success()) {
        LOG_ERROR("Docker start failed: " + result.err);
        if (progress) progress("ERROR: " + result.err);
        return false;
    }

    if (progress) {
        progress("Waiting for containers to be healthy...");
        Sleep(5000); // Give containers time to start
        progress("All containers started successfully!");
    }
    return true;
}

bool Docker::stopAll() {
    auto result = Process::run(
        getComposeCmd() + " down",
        std::string(config_.installPath.begin(), config_.installPath.end())
    );
    return result.success();
}

bool Docker::restartAll() {
    stopAll();
    Sleep(2000);
    return startAll();
}

bool Docker::rebuildAll(std::function<void(const std::string&)> progress) {
    if (progress) progress("Rebuilding Docker images...");

    auto result = Process::run(
        getComposeCmd() + " up -d --build",
        std::string(config_.installPath.begin(), config_.installPath.end()),
        600000 // 10 min timeout for rebuild
    );

    if (!result.success()) {
        LOG_ERROR("Docker rebuild failed: " + result.err);
        if (progress) progress("ERROR: " + result.err);
        return false;
    }
    if (progress) progress("Rebuild complete!");
    return true;
}

std::vector<ContainerStatus> Docker::getStatus() {
    std::vector<ContainerStatus> containers;

    auto result = Process::run(
        "docker ps -a --filter name=virent --format \"{{.Names}}|{{.Status}}|{{.Image}}|{{.Ports}}\""
    );

    if (!result.success()) return containers;

    std::string line;
    std::istringstream stream(result.out);
    while (std::getline(stream, line)) {
        while (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;

        ContainerStatus cs;
        auto pos1 = line.find('|');
        auto pos2 = line.find('|', pos1 + 1);
        auto pos3 = line.find('|', pos2 + 1);

        if (pos1 != std::string::npos) {
            cs.name = line.substr(0, pos1);
            cs.status = line.substr(pos1 + 1, pos2 - pos1 - 1);
            cs.isRunning = cs.status.find("running") != std::string::npos ||
                          cs.status.find("Up") != std::string::npos;
            if (pos2 != std::string::npos) {
                cs.image = line.substr(pos2 + 1, pos3 - pos2 - 1);
                if (pos3 != std::string::npos) {
                    cs.ports = line.substr(pos3 + 1);
                }
            }
        }
        containers.push_back(cs);
    }
    return containers;
}

std::string Docker::getLogs(const std::string& containerName, int lines) {
    auto result = Process::run(
        "docker logs --tail " + std::to_string(lines) + " " + containerName
    );
    return result.out + result.err;
}

bool Docker::seedDatabase() {
    auto result = Process::run(
        "docker exec virent-api node -e \""
        "const {MongoClient} = require('mongodb');"
        "(async () => {"
        "  const c = new MongoClient('mongodb://virent:virent_secret_2024@mongodb:27017');"
        "  await c.connect();"
        "  const db = c.db('spark-rentals');"
        "  await db.collection('admins').insertOne({"
        "    firstName:'Super',lastName:'Admin',email:'admin@sparkrentals.local',"
        "    password:require('bcryptjs').hashSync('Admin123!',10)"
        "  });"
        "  console.log('Seeded!');"
        "  await c.close();"
        "})();\""
    );
    return result.success();
}

bool Docker::backupDatabase(const std::string& backupPath) {
    auto result = Process::run(
        "docker exec virent-mongodb mongodump "
        "--uri \"mongodb://virent:virent_secret_2024@localhost:27017/spark-rentals?authSource=admin\" "
        "--out /data/backup"
    );
    if (!result.success()) return false;

    // Copy from container
    Process::run("docker cp virent-mongodb:/data/backup \"" + backupPath + "\"");
    return true;
}

bool Docker::restoreDatabase(const std::string& backupFile) {
    auto result = Process::run(
        "docker exec virent-mongodb mongorestore "
        "--uri \"mongodb://virent:virent_secret_2024@localhost:27017/spark-rentals?authSource=admin\" "
        "--drop /data/backup"
    );
    return result.success();
}

std::string Docker::getDbStats() {
    auto result = Process::run(
        "docker exec virent-mongodb mongosh --quiet --eval "
        "\"db.getSiblingDB('spark-rentals').runCommand({dbStats:1})\""
    );
    return result.success() ? result.out : "Failed to get stats";
}

std::string Docker::execInContainer(const std::string& container,
                                     const std::string& command) {
    auto result = Process::run(
        "docker exec " + container + " " + command
    );
    return result.out + result.err;
}

} // namespace virent
