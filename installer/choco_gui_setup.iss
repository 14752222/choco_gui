; ============================================================
;  Choco GUI - Inno Setup 安装脚本
;  版本: 1.0.0
;  所有路径均使用相对路径，兼容本地和 CI 环境
; ============================================================

#define AppName "Choco GUI"
#define AppVersion "1.0.0"
#define AppPublisher "Choco GUI"
#define AppURL "https://github.com/14752222/choco_gui"
#define AppExeName "choco_gui.exe"

; 基于脚本所在目录，自动推导项目根目录
#define ScriptDir SourcePath
#define ProjectRoot SourcePath + ".."
#define AppDir       ScriptDir + "app"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
; 输出到 installer/output 目录
OutputDir={#ScriptDir}output
OutputBaseFilename=ChocoGUI_Setup_v{#AppVersion}
; 压缩
Compression=lzma2/ultra64
SolidCompression=yes
; 窗口样式
WizardStyle=modern
; 强制显示语言选择对话框
ShowLanguageDialog=yes
; 图标（安装程序自身图标）
SetupIconFile={#ProjectRoot}\assets\images\logo.ico
; 需要管理员权限（Chocolatey 操作需要）
PrivilegesRequired=admin
; 架构
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 最低 Windows 版本: Windows 10
MinVersion=10.0.17763

[Languages]
Name: "chinesesimplified"; MessagesFile: "{#ScriptDir}ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式(&D)"; GroupDescription: "附加任务:"; Flags: unchecked
Name: "startmenuicon"; Description: "在开始菜单中创建快捷方式(&S)"; GroupDescription: "附加任务:"; Flags: checkedonce

[Files]
; 主程序及所有依赖（从 installer/app/ 目录读取，CI 构建时自动填充）
Source: "{#AppDir}\choco_gui.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
; data 目录（整个目录递归）
Source: "{#AppDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; 程序图标
Source: "{#ProjectRoot}\assets\images\logo.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; 开始菜单
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\logo.ico"; Tasks: startmenuicon
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"; Tasks: startmenuicon
; 桌面
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\logo.ico"; Tasks: desktopicon

[Run]
; 安装完成后可选择立即启动
Filename: "{app}\{#AppExeName}"; Description: "立即启动 {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 卸载时清理用户数据（可选，根据需要取消注释）
; Type: filesandordirs; Name: "{localappdata}\{#AppName}"
