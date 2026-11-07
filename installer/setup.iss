; Smart Classroom Windows Installer
; Generates a single-file setup.exe with auto-uninstall
;
; 注意：此文件在 CI 中被复制到仓库根目录后编译（Copy-Item installer/setup.iss setup.iss）
; 所有路径均相对于仓库根目录
;
; 版本号由 CI 通过 /DMyAppVersion=<pubspec 版本> 传入。
; 以前这里写死 1.25.0，于是安装包文件名是新的、控制面板里显示的版本却永远是 1.25.0。
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#define MyAppName "灵动课堂 Smart Classroom"
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
AppVerName={#MyAppName} {#MyAppVersion}
DefaultDirName={autopf}\SmartClassroom
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
OutputDir=build\installer
OutputBaseFilename=SmartClassroom_v{#MyAppVersion}_Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=windows\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："; Flags: checkedonce

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: postinstall nowait skipifsilent shellexec



[Code]
function InitializeSetup: Boolean;
begin
  Result := True;
end;
