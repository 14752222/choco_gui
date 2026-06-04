# Choco GUI 四项功能增强 — 完成报告

## 完成时间
2026-05-31

## 修改的文件

| 文件 | 改动内容 |
|------|----------|
| `lib/models/package_model.dart` | 新增 `ChocoSource` 数据模型 |
| `lib/services/choco_service.dart` | 新增版本查询、Choco 路径获取、源管理、精确搜索 |
| `lib/providers/app_provider.dart` | 新增源管理状态、Choco 路径状态、精确搜索参数 |
| `lib/screens/search_screen.dart` | 搜索模式切换、版本选择、安装路径预填 |
| `lib/screens/settings_screen.dart` | 软件源管理区域、安装路径预填 |
| `lib/screens/recommended_screen.dart` | 安装确认对话框：版本选择 + 路径预填 |
| `lib/screens/package_detail_screen.dart` | 安装确认对话框：版本选择 + 路径预填 |

---

## 新功能详解

### 1. 安装软件可选择版本
- 安装确认对话框顶部新增「安装版本」下拉框
- 自动调用 `choco search <pkg> --exact --all-versions` 获取所有可用版本
- 默认选择「最新版本（默认）」，也可下拉选择历史版本
- 安装命令自动附上 `--version='x.x.x'`

### 2. 设置页面添加换源功能
- 「软件源管理」区域：显示所有已配置的 Chocolatey 源
- 支持操作：
  - 🟢 **启用** / ⏸ **禁用** 源
  - 🗑️ **删除** 自定义源（内置源不可删除）
  - ➕ **添加** 新源（名称 + 地址 + 优先级）
- 添加对话框内附「常用国内镜像源」提示（中科大、清华）

### 3. 安装位置输入框自动预填 Choco 安装路径
- 设置页「安装位置」上方新增提示卡片，显示 Chocolatey 实际安装路径（来自 `$env:ChocolateyInstall`）
- 安装确认对话框的默认路径优先使用用户设置值，否则自动填入 Choco 默认路径
- 设置页输入框 placeholder 也预填了 Choco 路径

### 4. 搜索功能结果更精确
- 搜索栏下方新增「模糊搜索 / 精确搜索」切换按钮
- 精确搜索时调用 `choco search <kw> --exact`
- 用户可随时切换，无需重新输入关键词

---

## 如何运行

```bash
cd F:/desktop/choco_gui
flutter pub get
flutter run -d windows
```
