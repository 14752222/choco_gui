# Choco GUI 安装脚本
# 用法: 右键 -> 使用 PowerShell 运行，或在终端中: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$host.UI.RawUI.WindowTitle = "Choco GUI 安装程序"

# 颜色定义 - 使用用户偏好配色
$ColorDark = "#222831"
$ColorAccent = "#948979"

Write-Host @"
╔══════════════════════════════════════════╗
║        Choco GUI v1.0.0 安装程序         ║
║   Chocolatey 包管理器图形界面客户端       ║
╚══════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# 检测管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[警告] 建议以管理员身份运行以获得最佳体验" -ForegroundColor Yellow
    Write-Host "  右键 setup.ps1 -> 使用 PowerShell 运行 (管理员)" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "是否继续以普通用户安装？(y/n)"
    if ($continue -ne 'y') { exit }
}

# 安装目录
$defaultPath = "$env:LOCALAPPDATA\Programs\ChocoGUI"
Write-Host ""
Write-Host "安装位置 (回车使用默认): $defaultPath" -ForegroundColor Gray
$installPath = Read-Host "> "
if ([string]::IsNullOrWhiteSpace($installPath)) {
    $installPath = $defaultPath
}

# 创建安装目录
Write-Host "`n正在安装到: $installPath" -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# 复制文件
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "正在复制文件..."
Copy-Item -Path "$sourceDir\app\*" -Destination $installPath -Recurse -Force

# 创建开始菜单快捷方式
try {
    $startMenuPath = [Environment]::GetFolderPath("CommonPrograms")
    if (-not (Test-Path $startMenuPath)) {
        $startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    }
    $shortcutPath = "$startMenuPath\Choco GUI.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$installPath\choco_gui.exe"
    $shortcut.WorkingDirectory = $installPath
    $shortcut.Description = "Chocolatey 包管理器图形界面客户端"
    $shortcut.Save()
    Write-Host "已创建开始菜单快捷方式" -ForegroundColor Green
} catch {
    Write-Host "创建开始菜单快捷方式失败: $_" -ForegroundColor Yellow
}

# 创建桌面快捷方式
$createDesktop = Read-Host "`n是否创建桌面快捷方式？(Y/n)"
if ($createDesktop -ne 'n' -and $createDesktop -ne 'N') {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $desktopShortcutPath = "$desktopPath\Choco GUI.lnk"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $WScriptShell.CreateShortcut($desktopShortcutPath)
        $shortcut.TargetPath = "$installPath\choco_gui.exe"
        $shortcut.WorkingDirectory = $installPath
        $shortcut.Description = "Chocolatey 包管理器图形界面客户端"
        $shortcut.Save()
        Write-Host "已创建桌面快捷方式" -ForegroundColor Green
    } catch {
        # 尝试当前用户桌面
        try {
            $desktopPath = "$env:USERPROFILE\Desktop"
            $desktopShortcutPath = "$desktopPath\Choco GUI.lnk"
            $WScriptShell = New-Object -ComObject WScript.Shell
            $shortcut = $WScriptShell.CreateShortcut($desktopShortcutPath)
            $shortcut.TargetPath = "$installPath\choco_gui.exe"
            $shortcut.WorkingDirectory = $installPath
            $shortcut.Save()
            Write-Host "已创建桌面快捷方式" -ForegroundColor Green
        } catch {
            Write-Host "创建桌面快捷方式失败: $_" -ForegroundColor Yellow
        }
    }
}

# 创建卸载脚本
$uninstallScript = @"
@echo off
echo ========================================
echo   Choco GUI 卸载程序
echo ========================================
echo.
echo 即将从以下位置移除 Choco GUI:
echo   $installPath
echo.
set /p confirm=确认卸载？(y/n): 
if /i not "%confirm%"=="y" exit /b

taskkill /f /im choco_gui.exe 2>nul
rmdir /s /q "$installPath"
del /f /q "%startMenuPath%\Choco GUI.lnk" 2>nul
del /f /q "$env:USERPROFILE\Desktop\Choco GUI.lnk" 2>nul
del /f /q "$env:PUBLIC\Desktop\Choco GUI.lnk" 2>nul

echo.
echo Choco GUI 已卸载完成！
pause
"@
$uninstallScript | Out-File -FilePath "$installPath\uninstall.bat" -Encoding ASCII

Write-Host @"

╔══════════════════════════════════════════╗
║          安装完成！                      ║
║                                         ║
║  程序位置: $installPath
║  卸载方式: 运行 uninstall.bat            ║
╚══════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
