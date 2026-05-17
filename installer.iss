#define MyAppName "Sijinak"
#define MyAppVersion "1.0.0.1"
#define MyAppPublisher "MAN 2 Yogyakarta"
#define MyAppExeName "sijinak_win.exe"
#define MyDriverExe "AiYinEx_Printer_Driver_3.3.6.575_sign.exe"

[Setup]
AppId={{52D5AE95-4EF7-4D46-A9D7-7F85A9D0F7E1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=sijinak-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"
Name: "install_driver"; Description: "Install AiYinEx printer driver (recommended)"; GroupDescription: "Prerequisites:"; Flags: checkedonce

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "{#MyDriverExe}"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "{tmp}\{#MyDriverExe}"; Description: "Install printer driver"; Tasks: install_driver; Flags: waituntilterminated
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Icons]
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
