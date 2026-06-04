' Choco GUI 安装程序 VBS
' 双击运行即可安装
Option Explicit

Const APP_NAME = "Choco GUI"
Const APP_VERSION = "1.0.0"

Dim objShell, objFSO, objWshShell
Dim strAppDir, strInstallDir, strSourceDir
Dim strStartMenu, strDesktop
Dim objIE, objExec

Set objShell = CreateObject("Shell.Application")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWshShell = CreateObject("WScript.Shell")

' 获取脚本所在目录
strAppDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strSourceDir = strAppDir & "\app"

' 检查源文件是否存在
If Not objFSO.FolderExists(strSourceDir) Then
    MsgBox "安装文件不完整！请确保 app 文件夹与安装程序在同一目录。", vbCritical, APP_NAME
    WScript.Quit 1
End If

' 检查是否以管理员权限运行
Dim isAdmin
isAdmin = False
On Error Resume Next
isAdmin = objFSO.FolderExists("C:\Windows\System32\config")
On Error Goto 0

If Not isAdmin Then
    ' 请求管理员权限重新运行
    objShell.ShellExecute "wscript.exe", 
        """" & WScript.ScriptFullName & """", 
        "", "runas", 1
    WScript.Quit
End If

' 安装界面
Dim result
result = MsgBox("欢迎使用 " & APP_NAME & " v" & APP_VERSION & " 安装向导" & vbCrLf & vbCrLf & _
    "本程序将安装 " & APP_NAME & " - Chocolatey 包管理器图形界面客户端。" & vbCrLf & vbCrLf & _
    "是否继续安装？", vbYesNo + vbQuestion, APP_NAME & " 安装")

If result <> vbYes Then WScript.Quit

' 选择安装目录
strInstallDir = objWshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\" & APP_NAME

Dim customDir
customDir = InputBox("安装位置：" & vbCrLf & vbCrLf & _
    "（留空使用默认位置）", APP_NAME & " 安装位置", strInstallDir)

If Not IsEmpty(customDir) And Len(Trim(customDir)) > 0 Then
    strInstallDir = customDir
End If

' 检查 Choco 是否已安装
If objFSO.FolderExists(strInstallDir) Then
    result = MsgBox("目标文件夹已存在，是否覆盖安装？", vbYesNo + vbQuestion, APP_NAME)
    If result <> vbYes Then WScript.Quit
    objFSO.DeleteFolder strInstallDir, True
End If

' 创建安装目录
objFSO.CreateFolder strInstallDir

' 复制文件（带进度显示）
CreateObject("WScript.Shell").Popup "正在安装，请稍候...", 2, APP_NAME, 64

On Error Resume Next
objFSO.CopyFolder strSourceDir & "\*", strInstallDir, True
If Err.Number <> 0 Then
    MsgBox "文件复制失败！请检查权限或磁盘空间。", vbCritical, APP_NAME
    WScript.Quit 1
End If
On Error Goto 0

' 创建开始菜单快捷方式
strStartMenu = objWshShell.SpecialFolders("Programs") & "\" & APP_NAME
If Not objFSO.FolderExists(strStartMenu) Then
    objFSO.CreateFolder strStartMenu
End If

CreateShortcut strStartMenu & "\" & APP_NAME & ".lnk", _
    strInstallDir & "\choco_gui.exe", strInstallDir, _
    "Chocolatey 包管理器图形界面客户端"

' 创建卸载快捷方式
CreateUninstallScript strInstallDir

CreateShortcut strStartMenu & "\卸载 " & APP_NAME & ".lnk", _
    strInstallDir & "\uninstall.bat", strInstallDir, _
    "卸载 " & APP_NAME

' 询问是否创建桌面快捷方式
result = MsgBox("安装完成！" & vbCrLf & vbCrLf & _
    "是否创建桌面快捷方式？", vbYesNo + vbQuestion, APP_NAME)

If result = vbYes Then
    strDesktop = objWshShell.SpecialFolders("Desktop")
    CreateShortcut strDesktop & "\" & APP_NAME & ".lnk", _
        strInstallDir & "\choco_gui.exe", strInstallDir, _
        "Chocolatey 包管理器图形界面客户端"
End If

MsgBox APP_NAME & " 安装成功！" & vbCrLf & vbCrLf & _
    "安装位置：" & strInstallDir & vbCrLf & _
    "可以从开始菜单启动程序。", vbInformation, APP_NAME

WScript.Quit 0

' ===== 辅助函数 =====

Sub CreateShortcut(strPath, strTarget, strWorkDir, strDesc)
    On Error Resume Next
    Dim objShortcut
    Set objShortcut = objWshShell.CreateShortcut(strPath)
    objShortcut.TargetPath = strTarget
    objShortcut.WorkingDirectory = strWorkDir
    objShortcut.Description = strDesc
    objShortcut.WindowStyle = 1
    objShortcut.Save
    Set objShortcut = Nothing
    On Error Goto 0
End Sub

Sub CreateUninstallScript(strDir)
    On Error Resume Next
    Dim objFile, strContent
    strContent = "@echo off" & vbCrLf & _
        "title 卸载 Choco GUI" & vbCrLf & _
        "echo 正在卸载 Choco GUI..." & vbCrLf & _
        "taskkill /f /im choco_gui.exe 2>nul" & vbCrLf & _
        "rmdir /s /q """ & strDir & """" & vbCrLf & _
        "del /f /q """ & strStartMenu & "\Choco GUI.lnk"" 2>nul" & vbCrLf & _
        "del /f /q """ & strStartMenu & "\卸载 Choco GUI.lnk"" 2>nul" & vbCrLf & _
        "rmdir """ & strStartMenu & """ 2>nul" & vbCrLf & _
        "del /f /q """ & objWshShell.SpecialFolders("Desktop") & "\Choco GUI.lnk"" 2>nul" & vbCrLf & _
        "echo." & vbCrLf & _
        "echo Choco GUI 已卸载完成！" & vbCrLf & _
        "pause"
    
    Set objFile = objFSO.CreateTextFile(strDir & "\uninstall.bat", True)
    objFile.Write strContent
    objFile.Close
    Set objFile = Nothing
    On Error Goto 0
End Sub
