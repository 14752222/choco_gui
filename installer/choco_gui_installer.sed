[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%

[Strings]
InstallPrompt=欢迎使用 Choco GUI 安装向导&#010;&#010;本程序将安装 Choco GUI - Chocolatey 包管理器图形界面客户端。&#010;&#010;是否继续？
DisplayLicense=
FinishMessage=Choco GUI 安装完成！&#010;&#010;您可以从开始菜单或桌面快捷方式启动程序。
TargetName=F:\desktop\choco_gui\installer\ChocoGUI_Setup.exe
FriendlyName=Choco GUI
AppLaunched=setup.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup.ps1"
FILE1="app\choco_gui.exe"
FILE2="app\flutter_windows.dll"
FILE3="app\url_launcher_windows_plugin.dll"
FILE4="app\data\app.so"
FILE5="app\data\icudtl.dat"
FILE6="app\data\flutter_assets\AssetManifest.bin"
FILE7="app\data\flutter_assets\FontManifest.json"
FILE8="app\data\flutter_assets\NativeAssetsManifest.json"
FILE9="app\data\flutter_assets\NOTICES.Z"
FILE10="app\data\flutter_assets\shaders\ink_sparkle.frag"
FILE11="app\data\flutter_assets\shaders\stretch_effect.frag"
FILE12="app\data\flutter_assets\assets\images\logo.png"
FILE13="app\data\flutter_assets\fonts\MaterialIcons-Regular.otf"
FILE14="app\data\flutter_assets\packages\cupertino_icons\assets\CupertinoIcons.ttf"

[SourceFiles]
SourceFiles0=F:\desktop\choco_gui\installer\
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
%FILE3%=
%FILE4%=
%FILE5%=
%FILE6%=
%FILE7%=
%FILE8%=
%FILE9%=
%FILE10%=
%FILE11%=
%FILE12%=
%FILE13%=
%FILE14%=
