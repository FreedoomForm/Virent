/**
 * installer_core.h — First-run installation logic
 *
 * Downloads/installs Docker, clones repo, builds containers,
 * seeds database — all in one click.
 */

#pragma once
#include <string>
#include <functional>
#include "config.h"

namespace virent {

class InstallerCore {
public:
    enum class Stage {
        CheckingPrerequisites,
        InstallingDocker,
        CloningRepository,
        CreatingEnvFile,
        BuildingContainers,
        StartingContainers,
        SeedingDatabase,
        ConfiguringFirewall,
        Complete,
        Error
    };

    using ProgressCallback = std::function<void(Stage stage, int percent, const std::string& message)>;

    bool install(const std::wstring& targetDrive, AppConfig& config, ProgressCallback progress);

    // Check what's already installed
    struct Prerequisites {
        bool dockerInstalled = false;
        bool dockerRunning = false;
        bool gitInstalled = false;
        bool repoCloned = false;
        bool containersRunning = false;
    };

    Prerequisites checkPrerequisites();

private:
    bool installDocker(ProgressCallback progress);
    bool cloneRepository(const std::wstring& path, ProgressCallback progress);
    bool createEnvFile(const std::wstring& path, AppConfig& config);
    bool buildContainers(const std::wstring& path, ProgressCallback progress);
    bool startContainers(const std::wstring& path, ProgressCallback progress);
    bool seedDatabase(const std::wstring& path, ProgressCallback progress);
    bool configureFirewall(ProgressCallback progress);
};

} // namespace virent
