# Changelog

All notable changes to **Choco GUI** are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Planned
- Scheduled upgrade-all (Task Scheduler integration)
- Package detail page with full changelog/release notes
- Multi-language UI (i18n)

---

## [1.0.0] — 2026-05-31

### Added
- **Version selection** — choose any historical version when installing a package  
  (`choco search <pkg> --exact --all-versions`)
- **Source management** — list, add, enable, disable, and remove Chocolatey sources  
  (Settings page; includes Chinese mirror hints: USTC, Tsinghua)
- **Install path auto-fill** — reads `$env:ChocolateyInstall` and pre-fills install directory
- **Exact search toggle** — switch between fuzzy and exact search (`--exact` flag)
- **Recommended packages** screen with curated popular software list
- **Auto Chocolatey detection & installation** — one-click install with real-time log
- **Cleanup cache** button on install-failure dialog
- **Light / dark theme** with Material 3 and warm taupe colour palette  
  (`#222831` / `#393E46` / `#948979` / `#DFD0B8`)
- **NavigationRail** sidebar: Recommended · Installed · Search · Settings
- Pagination for large package lists
- Real-time progress dialog for install / uninstall / upgrade

### Technical
- State management via custom `AppProvider` + `InheritedWidget`
- All Chocolatey operations via `powershell.exe` subprocess (no third-party CLI wrappers)
- `shared_preferences` for persisting install directory setting
- `url_launcher` for opening package URLs
- `file_picker` for browsing install directory

---

[Unreleased]: https://github.com/14752222/choco_gui/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/14752222/choco_gui/releases/tag/v1.0.0
