@echo off
chcp 65001 >nul
title Choco GUI 安装向导

echo.
echo ╔══════════════════════════════════════════╗
echo ║      Choco GUI v1.0.0 安装向导           ║
echo ║  Chocolatey 包管理器图形界面客户端        ║
echo ╚══════════════════════════════════════════╝
echo.

:: 请求管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [提示] 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs -WindowStyle Normal"
    exit /b
)

:: 管理员权限已获取
echo [OK] 已获取管理员权限
echo.

:: 安装目录
set "INSTALL_DIR=%LOCALAPPDATA%\Programs\ChocoGUI"
echo 安装位置: %INSTALL_DIR%
echo.

:: 复制文件
echo 正在安装 Choco GUI...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%" 2>nul

xcopy /E /Y /Q "%~dp0app\*" "%INSTALL_DIR%\" >nul

:: 创建开始菜单快捷方式
powershell -Command ^
"$ws = New-Object -ComObject WScript.Shell; ^
$sc = $ws.CreateShortcut([Environment]::GetFolderPath('CommonPrograms') + '\Choco GUI.lnk'); ^
$sc.TargetPath = '%INSTALL_DIR%\choco_gui.exe'; ^
$sc.WorkingDirectory = '%INSTALL_DIR%'; ^
$sc.Description = 'Chocolatey 包管理器图形界面客户端'; ^
$sc.Save()" 2>nul

:: 备选开始菜单路径
powershell -Command ^
"$ws = New-Object -ComObject WScript.Shell; ^
$sc = $ws.CreateShortcut($env:APPDATA + '\Microsoft\Windows\Start Menu\Programs\Choco GUI.lnk'); ^
$sc.TargetPath = '%INSTALL_DIR%\choco_gui.exe'; ^
$sc.WorkingDirectory = '%INSTALL_DIR%'; ^
$sc.Save()" 2>nul

:: 创建桌面快捷方式
set /p CREATE_DESKTOP="是否创建桌面快捷方式？(Y/n): "
if /i "%CREATE_DESKTOP%"=="n" goto skip_desktop
powershell -Command ^
"$ws = New-Object -ComObject WScript.Shell; ^
$sc = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Choco GUI.lnk'); ^
$sc.TargetPath = '%INSTALL_DIR%\choco_gui.exe'; ^
$sc.WorkingDirectory = '%INSTALL_DIR%'; ^
$sc.Save()" 2>nul
powershell -Command ^
"$ws = New-Object -ComObject WScript.Shell; ^
$sc = $ws.CreateShortcut($env:USERPROFILE + '\Desktop\Choco GUI.lnk'); ^
$sc.TargetPath = '%INSTALL_DIR%\choco_gui.exe'; ^
$sc.WorkingDirectory = '%INSTALL_DIR%'; ^
$sc.Save()" 2>nul

:skip_desktop
:: 创建卸载程序
echo @echo off > "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo title 卸载 Choco GUI >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo echo 正在卸载 Choco GUI... >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo taskkill /f /im choco_gui.exe 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo rmdir /s /q "%INSTALL_DIR%" 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo del /f /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Choco GUI.lnk" 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Choco GUI.lnk" 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo del /f /q "%USERPROFILE%\Desktop\Choco GUI.lnk" 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo del /f /q "%PUBLIC%\Desktop\Choco GUI.lnk" 2^>nul >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo echo. >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo echo Choco GUI 已卸载完成！ >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo echo 开始菜单中的快捷方式需要手动删除 >> "%INSTALL_DIR%\卸载ChocoGUI.bat"
echo pause >> "%INSTALL_DIR%\卸载ChocoGUI.bat"

echo.
echo ╔══════════════════════════════════════════╗
echo ║         安装完成！                       ║
echo ║                                         ║
echo ║  位置: %INSTALL_DIR%                    ║
echo ║  卸载: 开始菜单 -^> 卸载ChocoGUI         ║
echo ╚══════════════════════════════════════════╝
echo.
echo 按任意键退出...
pause >nul
