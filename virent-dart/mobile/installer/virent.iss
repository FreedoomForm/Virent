; virent.iss — Inno Setup script for Virent Windows installer.
;
; Produces a single VirentSetup.exe that bundles the entire Flutter
; Windows release (virent_mobile.exe + flutter_windows.dll + data/)
; plus Start Menu shortcuts, desktop shortcut, and an uninstaller.
;
; Compile with:
;   iscc /DReleaseDir="build\windows\x64\runner\Release" installer\virent.iss
;
; Output:
;   installer\Output\VirentSetup.exe

#ifndef ReleaseDir
  ; Relative to this script's location (installer/), so go up one level
  ; to the project root (mobile/), then into build/.
  #define ReleaseDir "..\build\windows\x64\runner\Release"
#endif

#define MyAppName "Virent"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Virent"
#define MyAppExeName "virent_mobile.exe"

[Setup]
AppId={{VIRENT-2024-E-SCOOTER-RENTAL}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=VirentSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Pull in every file from the Flutter release directory.
; DestDir="{app}" is REQUIRED by Inno Setup — it tells the installer
; where to copy the files (the installation directory, defined by
; DefaultDirName in [Setup]).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
