/**
 * installer_core.cpp — Installation logic implementation
 */

#include "installer_core.h"
#include "process.h"
#include "logger.h"
#include <filesystem>
#include <fstream>
#include <random>

namespace virent {

InstallerCore::Prerequisites InstallerCore::checkPrerequisites() {
    Prerequisites pre;
    pre.gitInstalled = Process::commandExists("git");
    pre.dockerInstalled = Process::commandExists("docker");
    if (pre.dockerInstalled) {
        pre.dockerRunning = Process::isDockerRunning();
    }
    return pre;
}

bool InstallerCore::install(const std::wstring& targetDrive, AppConfig& config,
                             ProgressCallback progress) {
    using S = Stage;
    auto report = [&](S stage, int pct, const std::string& msg) {
        if (progress) progress(stage, pct, msg);
        LOG_INFO("Install: [" + std::to_string(pct) + "%] " + msg);
    };

    // Setup install path
    config.installPath = targetDrive + L"\\Virent";
    std::string installPathStr(config.installPath.begin(), config.installPath.end());

    // 1. Check prerequisites
    report(S::CheckingPrerequisites, 5, "Checking prerequisites...");
    auto pre = checkPrerequisites();
    if (!pre.gitInstalled) {
        report(S::Error, 0, "Git is not installed. Please install Git from https://git-scm.com");
        return false;
    }

    // 2. Install Docker if needed
    if (!pre.dockerInstalled) {
        report(S::InstallingDocker, 10, "Docker not found. Installing...");
        if (!installDocker(progress)) {
            report(S::Error, 0, "Failed to install Docker. Please install manually from https://docker.com");
            return false;
        }
    } else {
        report(S::InstallingDocker, 15, "Docker already installed - OK");
    }

    // Wait for Docker to start
    if (!pre.dockerRunning) {
        report(S::InstallingDocker, 20, "Starting Docker Desktop...");
        Process::runAsync("C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe");
        report(S::InstallingDocker, 25, "Waiting for Docker to be ready...");
        for (int i = 0; i < 60; i++) {
            if (Process::isDockerRunning()) break;
            Sleep(3000);
            report(S::InstallingDocker, 25 + i / 6, "Waiting for Docker... (" + std::to_string(i * 3) + "s)");
        }
        if (!Process::isDockerRunning()) {
            report(S::Error, 0, "Docker did not start. Please start Docker Desktop manually.");
            return false;
        }
    }
    report(S::InstallingDocker, 30, "Docker is running - OK");

    // 3. Clone repository
    report(S::CloningRepository, 35, "Cloning Virent repository...");
    if (!std::filesystem::exists(config.installPath)) {
        std::filesystem::create_directories(config.installPath);
    }
    if (!std::filesystem::exists(config.installPath + L"\\.git")) {
        auto cloneResult = Process::run(
            "git clone https://github.com/FreedoomForm/Virent.git \"" + installPathStr + "\""
        );
        if (!cloneResult.success()) {
            report(S::Error, 0, "Failed to clone repository: " + cloneResult.err);
            return false;
        }
    }
    report(S::CloningRepository, 45, "Repository cloned - OK");

    // 4. Create .env file
    report(S::CreatingEnvFile, 50, "Creating configuration...");
    if (!createEnvFile(config.installPath, config)) {
        report(S::Error, 0, "Failed to create .env file");
        return false;
    }
    report(S::CreatingEnvFile, 55, "Configuration created - OK");

    // 5. Build Docker containers
    report(S::BuildingContainers, 60, "Building Docker images (this takes several minutes)...");
    if (!buildContainers(config.installPath, progress)) {
        report(S::Error, 0, "Failed to build containers");
        return false;
    }
    report(S::BuildingContainers, 80, "Docker images built - OK");

    // 6. Start containers
    report(S::StartingContainers, 82, "Starting containers...");
    if (!startContainers(config.installPath, progress)) {
        report(S::Error, 0, "Failed to start containers");
        return false;
    }
    Sleep(5000); // Wait for health checks
    report(S::StartingContainers, 88, "Containers started - OK");

    // 7. Seed database
    report(S::SeedingDatabase, 90, "Seeding database with initial data...");
    if (!seedDatabase(config.installPath, progress)) {
        report(S::SeedingDatabase, 92, "Database seed skipped (may already exist)");
    } else {
        report(S::SeedingDatabase, 95, "Database seeded - OK");
    }

    // 8. Configure firewall
    report(S::ConfiguringFirewall, 96, "Configuring Windows Firewall...");
    configureFirewall(progress);
    report(S::ConfiguringFirewall, 98, "Firewall configured - OK");

    // Done!
    config.isFirstRun = false;
    config.save();

    report(S::Complete, 100, "Installation complete.");
    return true;
}

bool InstallerCore::installDocker(ProgressCallback progress) {
    // Download Docker Desktop installer
    auto result = Process::run(
        "powershell -Command \""
        "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' "
        "-OutFile '%TEMP%\\DockerDesktopInstaller.exe'"
        "\""
    );
    if (!result.success()) return false;

    // Install silently
    result = Process::run(
        "powershell -Command \"Start-Process -FilePath '%TEMP%\\DockerDesktopInstaller.exe' "
        "-ArgumentList 'install','--quiet' -Wait\""
    );
    return result.success();
}

bool InstallerCore::cloneRepository(const std::wstring& path, ProgressCallback progress) {
    return true; // handled in install()
}

bool InstallerCore::createEnvFile(const std::wstring& path, AppConfig& config) {
    std::wstring envPath = path + L"\\.env";

    // Generate random secrets
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 15);

    auto genHex = [&](int len) {
        std::string s;
        for (int i = 0; i < len; i++) s += "0123456789abcdef"[dis(gen)];
        return s;
    };

    std::string jwtSecret = genHex(64);
    std::string jwtRefresh = genHex(64);
    std::string cookieKey = genHex(64);

    std::ofstream f(envPath);
    if (!f.is_open()) return false;

    f << "MONGO_USER=virent\n";
    f << "MONGO_PASS=virent_secret_2024\n";
    f << "JWT_SECRET=" << jwtSecret << "\n";
    f << "JWT_REFRESH_SECRET=" << jwtRefresh << "\n";
    f << "COOKIE_KEY=" << cookieKey << "\n";
    f << "API_URL=http://localhost:8393/v1\n";
    f << "PUBLIC_BASE_URL=http://localhost:8393\n";
    f << "SMS_PROVIDER=console\n";
    f.close();

    LOG_INFO(".env file created with random secrets");
    return true;
}

bool InstallerCore::buildContainers(const std::wstring& path, ProgressCallback progress) {
    std::string pathStr(path.begin(), path.end());
    auto result = Process::run(
        "docker-compose -f docker-compose.pc.yml build",
        pathStr, 600000 // 10 min timeout
    );
    return result.success();
}

bool InstallerCore::startContainers(const std::wstring& path, ProgressCallback progress) {
    std::string pathStr(path.begin(), path.end());
    auto result = Process::run(
        "docker-compose -f docker-compose.pc.yml up -d",
        pathStr
    );
    return result.success();
}

bool InstallerCore::seedDatabase(const std::wstring& path, ProgressCallback progress) {
    std::string pathStr(path.begin(), path.end());
    auto result = Process::run(
        "docker exec virent-api node -e \""
        "const bcrypt=require('bcryptjs');"
        "const {MongoClient}=require('mongodb');"
        "(async()=>{"
        "const c=new MongoClient('mongodb://virent:virent_secret_2024@mongodb:27017');"
        "await c.connect();"
        "const db=c.db('spark-rentals');"
        "await db.collection('admins').deleteMany({});"
        "await db.collection('admins').insertOne({"
        "firstName:'Super',lastName:'Admin',"
        "email:'admin@sparkrentals.local',"
        "password:bcrypt.hashSync('Admin123!',10),"
        "created_at:new Date()});"
        "await db.collection('cities').insertOne({"
        "name:'Tashkent',fixedRate:100,timeRate:8,"
        "parkingZoneRate:20,bonusParkingZoneRate:30,"
        "noParkingZoneRate:50,noParkingToValidParking:100,"
        "chargingZoneRate:0,zones:[],created_at:new Date()});"
        "console.log('Seeded!');"
        "await c.close();"
        "})();\""
    );
    return result.success();
}

bool InstallerCore::configureFirewall(ProgressCallback progress) {
    // Allow ports 8393 (API), 3000 (Web), 1337 (Admin), 1883 (MQTT)
    Process::run("netsh advfirewall firewall add rule name=\"Virent API\" "
        "dir=in action=allow protocol=TCP localport=8393");
    Process::run("netsh advfirewall firewall add rule name=\"Virent Web\" "
        "dir=in action=allow protocol=TCP localport=3000");
    Process::run("netsh advfirewall firewall add rule name=\"Virent Admin\" "
        "dir=in action=allow protocol=TCP localport=1337");
    Process::run("netsh advfirewall firewall add rule name=\"Virent MQTT\" "
        "dir=in action=allow protocol=TCP localport=1883");
    return true;
}

} // namespace virent
