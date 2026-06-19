; Sijinak Windows installer.
;
; Build order:
;   1. flutter build windows --release
;   2. ISCC.exe installer\sijinak.iss
;        → installer\Output\sijinak-setup.exe
;
; The installer:
;   a. Copies the Flutter Release/ tree into Program Files\Sijinak
;   b. Launches AiYinEx printer driver installer (interactive) before finish
;   c. Creates Start Menu + optional desktop shortcut
;   d. Offers to launch the app at end

#define AppName        "Sijinak"
#define AppVersion     "1.0.2"
#define AppPublisher   "MAN 2 Simandaya"
#define AppExeName     "sijinak_win.exe"
#define ReleaseDir     "..\build\windows\x64\runner\Release"
#define DriverExe      "AiYinEx_Printer_Driver_3.3.6.575_sign.exe"
#define DriverDir      ".."

[Setup]
AppId={{B2F1A6E7-2C71-4F3A-9E12-7F8C9D6B5E40}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=Output
OutputBaseFilename=sijinak-setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#AppExeName}
DisableProgramGroupPage=yes
; SetupIconFile=icon.ico   ; drop your .ico here and uncomment

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Buat shortcut di Desktop"; GroupDescription: "Shortcut tambahan:"

[Files]
; Whole Flutter release tree → Program Files\Sijinak
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Printer driver — extracted to temp, removed after install
Source: "{#DriverDir}\{#DriverExe}"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Step 1: printer driver — interactive so admin sees what's happening.
;         StatusMsg shown in the install progress bar.
Filename: "{tmp}\{#DriverExe}"; \
  StatusMsg: "Memasang driver printer AiYinEx..."; \
  Flags: waituntilterminated

; Step 2: optional launch after install
Filename: "{app}\{#AppExeName}"; \
  Description: "Jalankan {#AppName} sekarang"; \
  Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Local Drift DB lives in %AppData%\..\Roaming\com.example.sijinak_win\
; Leave it intact on uninstall — admin can wipe manually if needed.
Type: filesandordirs; Name: "{app}"
