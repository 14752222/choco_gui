<div align="center">

<img src="assets/images/logo.png" width="96" alt="Choco GUI Logo" />

# Choco GUI

**A modern, elegant Chocolatey package manager GUI built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Release](https://img.shields.io/github/v/release/14752222/choco_gui?label=Latest)](https://github.com/14752222/choco_gui/releases)

[English](#english) · [中文](#中文)

</div>

---

## English

### ✨ Features

| Feature | Description |
|---|---|
| 🔍 **Smart Search** | Fuzzy / exact search powered by `choco search`, with real-time results |
| 📦 **Package Management** | Install, uninstall, and upgrade packages with a real-time log console |
| 🔢 **Version Selection** | Choose any historical version when installing a package |
| ⭐ **Recommended Packages** | Curated list of popular packages for quick one-click install |
| 🗂️ **Source Management** | Add / remove / enable / disable Chocolatey sources (supports Chinese mirrors) |
| 📁 **Install Path** | Auto-detect `$env:ChocolateyInstall` and pre-fill the install directory |
| 🌗 **Light / Dark Theme** | Full Material 3 theming with a warm taupe colour palette |
| 🚨 **Auto Chocolatey Setup** | Detect and install Chocolatey automatically if not present |

### 🖼️ Screenshots

> _Add screenshots here after first release_

### 🚀 Quick Start

#### Prerequisites

- Windows 10 / 11 (x64)
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) ≥ 3.10

#### Run from source

```powershell
git clone https://github.com/14752222/choco_gui.git
cd choco_gui
flutter pub get
flutter run -d windows
```

#### Download a release

Go to [Releases](https://github.com/14752222/choco_gui/releases) and download the latest `.zip`.  
Extract and run `choco_gui.exe` — **no installer needed**.

> ⚠️ Some operations (installing / uninstalling packages, managing sources) require **Administrator** privileges.  
> Right-click the exe → *Run as administrator*, or the app will prompt you automatically.

### 🏗️ Project Structure

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # Root widget & theme definitions
├── models/
│   └── package_model.dart     # PackageModel & ChocoSource data classes
├── providers/
│   └── app_provider.dart      # State management (InheritedWidget)
├── services/
│   └── choco_service.dart     # All Chocolatey CLI calls via PowerShell
├── screens/
│   ├── home_screen.dart       # Main scaffold with NavigationRail
│   ├── recommended_screen.dart
│   ├── installed_screen.dart
│   ├── search_screen.dart
│   ├── settings_screen.dart
│   └── package_detail_screen.dart
└── widgets/
    ├── package_card.dart
    ├── pagination_bar.dart
    └── progress_dialog.dart
```

### 🛠️ Build

```powershell
# Debug build (runs in-place)
flutter run -d windows

# Release build
flutter build windows --release
# Output: build\windows\x64\runner\Release\
```

### 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 中文

### ✨ 功能特性

| 功能 | 说明 |
|---|---|
| 🔍 **智能搜索** | 支持模糊搜索和精确搜索，基于 `choco search` 实时返回结果 |
| 📦 **包管理** | 安装、卸载、升级软件包，实时显示操作日志 |
| 🔢 **版本选择** | 安装时可选择任意历史版本 |
| ⭐ **推荐软件** | 精选常用软件列表，一键快速安装 |
| 🗂️ **软件源管理** | 添加 / 删除 / 启用 / 禁用 Chocolatey 软件源，内置国内镜像提示 |
| 📁 **安装路径** | 自动读取 `$env:ChocolateyInstall`，预填安装目录 |
| 🌗 **明暗主题** | 完整 Material 3 主题，采用暖棕配色方案 |
| 🚨 **自动安装 Choco** | 检测到未安装 Chocolatey 时，可一键完成安装 |

### 🚀 快速开始

#### 环境要求

- Windows 10 / 11（x64）
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) ≥ 3.10

#### 从源码运行

```powershell
git clone https://github.com/14752222/choco_gui.git
cd choco_gui
flutter pub get
flutter run -d windows
```

#### 直接下载

前往 [Releases](https://github.com/14752222/choco_gui/releases) 下载最新 `.zip`，解压后双击 `choco_gui.exe` 即可运行，**无需安装**。

> ⚠️ 安装/卸载软件包、管理软件源等操作需要**管理员权限**。  
> 建议右键 → 以管理员身份运行，或在应用提示时确认授权。

### 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
