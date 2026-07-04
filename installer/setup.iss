; Smart Classroom Windows Installer
; Inno Setup Script for v1.20
; Generates a single-file setup.exe with auto-uninstall

#define MyAppName "灵动课堂 Smart Classroom"
#define MyAppVersion "1.20"
#define MyAppPublisher "松庭灼墨 (ZhuoMoStudio)"
#define MyAppURL "https://github.com/ZhuoMoStudio/Smart-classroom"
#define MyAppExeName "smart_classroom.exe"

[Setup]
AppId={{B8F4A3D2-1C5E-4A7B-9D6F-8E2C3A1B5D7F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\SmartClassroom
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
OutputDir=..\build\installer
OutputBaseFilename=SmartClassroom_v{#MyAppVersion}_Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=yes
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："; Flags: checkedonce

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: postinstall nowait skipifsilent shellexec

[UninstallRun]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--uninstall"; Flags: runhidden

[Registry]
; 关联 .scdata 文件（可选）
Root: HKCU; Subkey: "Software\Classes\.scdata"; ValueType: string; ValueName: ""; ValueData: "SmartClassroom.Data"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\SmartClassroom.Data"; ValueType: string; ValueName: ""; ValueData: "灵动课堂数据文件"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\SmartClassroom.Data\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\SmartClassroom.Data\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Flags: uninsdeletekey

[Code]
function InitializeSetup: Boolean;
begin
  Result := True;
end;