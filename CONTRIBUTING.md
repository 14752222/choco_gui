# Contributing to Choco GUI

Thank you for your interest in contributing! 🎉  
Here's everything you need to get started.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

Be respectful. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

---

## How to Contribute

1. **Fork** the repository
2. Create a feature branch: `git checkout -b feat/my-awesome-feature`
3. Make your changes and commit (see [Commit Convention](#commit-message-convention))
4. Push: `git push origin feat/my-awesome-feature`
5. Open a **Pull Request** against the `main` branch

---

## Development Setup

### Requirements

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.10 |
| Dart SDK | ≥ 3.0 (bundled with Flutter) |
| Windows | 10 / 11 x64 |
| Chocolatey | (optional, for manual testing) |

### First-time setup

```powershell
git clone https://github.com/14752222/choco_gui.git
cd choco_gui
flutter pub get
flutter run -d windows
```

### Useful commands

```powershell
# Run with hot-reload
flutter run -d windows

# Analyse code
flutter analyze

# Run tests
flutter test

# Format code
dart format lib/

# Build release
flutter build windows --release
```

---

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

**Types:**

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code refactoring |
| `test` | Adding / fixing tests |
| `chore` | Build process, dependencies |

**Examples:**

```
feat(search): add exact search toggle
fix(service): handle PowerShell encoding for non-ASCII paths
docs: update CONTRIBUTING with setup steps
```

---

## Pull Request Guidelines

- Keep PRs **focused** — one feature / fix per PR
- Add / update **tests** if applicable
- Ensure `flutter analyze` passes with no errors
- Fill in the PR template completely
- Screenshots / GIFs are welcome for UI changes

---

## Reporting Bugs

Please use the [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md) issue template.  
Include:
- OS version and architecture
- Chocolatey version (`choco --version`)
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behaviour
- Relevant logs (from the in-app log console or terminal)

---

## Suggesting Features

Use the [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md) template.  
Describe the problem you're trying to solve, not just the solution.

---

Thank you for making Choco GUI better! 🍫
