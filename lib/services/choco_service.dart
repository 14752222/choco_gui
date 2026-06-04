import 'dart:convert';
import 'dart:io';
import '../models/package_model.dart';
import '../screens/package_detail_screen.dart';

/// Service that encapsulates all Chocolatey CLI operations.
class ChocoService {
  static const String _powershell = 'powershell.exe';

  Future<bool> isChocoInstalled() async {
    return await getChocoVersion() != null;
  }

  Future<String?> getChocoVersion() async {
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', 'choco --version'],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> installChocolatey({
    void Function(String line)? onOutput,
  }) async {
    const psScript =
        r"Set-ExecutionPolicy Bypass -Scope Process -Force; "
        r"[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; "
        r"& ([scriptblock]::Create((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')))";
    try {
      final process = await Process.start(
        _powershell,
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript],
        runInShell: false,
      );
      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((line) => onOutput?.call(line));
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((line) => onOutput?.call('[ERR] $line'));
      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (e) {
      onOutput?.call('Error: $e');
      return false;
    }
  }

  /// 清理 Chocolatey 安装失败遗留的缓存/临时文件。
  ///
  /// 清理路径：
  ///   - %TEMP%\chocolatey
  ///   - %TEMP%\choco*
  ///   - %ChocolateyInstall%\lib-bad  (损坏包残留)
  ///   - %ChocolateyInstall%\temp     (下载缓存)
  ///
  /// 返回清理报告字符串列表（每条是一行日志）。
  Future<List<String>> cleanupFailedInstall() async {
    const psScript = r'''
$log = @()
$tempDirs = @(
  (Join-Path $env:TEMP "chocolatey"),
  (Join-Path $env:TEMP "choco")
)
# 匹配 %TEMP%\choco* 通配
$wildCards = Get-ChildItem -Path $env:TEMP -Filter "choco*" -ErrorAction SilentlyContinue
foreach ($item in $wildCards) { $tempDirs += $item.FullName }

foreach ($d in ($tempDirs | Select-Object -Unique)) {
  if (Test-Path $d) {
    try {
      Remove-Item $d -Recurse -Force -ErrorAction Stop
      $log += "已删除: $d"
    } catch {
      $log += "删除失败: $d — $($_.Exception.Message)"
    }
  }
}

# Choco 安装目录下的 lib-bad 和 temp
if ($env:ChocolateyInstall) {
  $chocoCleanDirs = @(
    (Join-Path $env:ChocolateyInstall "lib-bad"),
    (Join-Path $env:ChocolateyInstall "temp")
  )
  foreach ($d in $chocoCleanDirs) {
    if (Test-Path $d) {
      try {
        Remove-Item $d -Recurse -Force -ErrorAction Stop
        $log += "已删除: $d"
      } catch {
        $log += "删除失败: $d — $($_.Exception.Message)"
      }
    }
  }
}

if ($log.Count -eq 0) { $log += "没有发现需要清理的缓存文件。" }
$log | ForEach-Object { Write-Output $_ }
''';
    final lines = <String>[];
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', psScript],
        runInShell: false,
      );
      for (final raw in (result.stdout as String).split('\n')) {
        final l = raw.trim();
        if (l.isNotEmpty) lines.add(l);
      }
      if ((result.stderr as String).trim().isNotEmpty) {
        lines.add('[ERR] ${(result.stderr as String).trim()}');
      }
    } catch (e) {
      lines.add('Error: $e');
    }
    return lines.isEmpty ? ['没有发现需要清理的缓存文件。'] : lines;
  }

  Future<List<PackageModel>> listInstalled() async {
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', 'choco list --limit-output'],
        runInShell: false,
      );
      if (result.exitCode != 0) return [];
      return _parseListOutput(result.stdout as String, isInstalled: true);
    } catch (_) {
      return [];
    }
  }

  Future<List<PackageModel>> search(String keyword, {bool exact = false}) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final escaped = keyword.replaceAll("'", "''");
      final exactFlag = exact ? ' --exact' : '';
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', "choco search '$escaped'$exactFlag --limit-output"],
        runInShell: false,
      );
      if (result.exitCode != 0) return [];
      return _parseListOutput(result.stdout as String, isInstalled: false);
    } catch (_) {
      return [];
    }
  }

  /// 获取指定包的所有可用版本列表
  Future<List<String>> getPackageVersions(String packageName) async {
    final versions = <String>[];
    try {
      final escaped = packageName.replaceAll("'", "''");
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', "choco search '$escaped' --exact --all-versions --limit-output"],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        for (final raw in (result.stdout as String).split('\n')) {
          final line = raw.trim();
          if (line.isEmpty) continue;
          if (RegExp(r'^\d+ package').hasMatch(line)) continue;
          final parts = line.split('|');
          if (parts.length >= 2) {
            final v = parts[1].trim();
            if (v.isNotEmpty && !versions.contains(v)) {
              versions.add(v);
            }
          }
        }
      }
    } catch (_) {}
    return versions;
  }

  /// 获取 Chocolatey 安装路径 (环境变量 ChocolateyInstall)
  Future<String> getChocoInstallPath() async {
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', r'Write-Output $env:ChocolateyInstall'],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return '';
  }

  /// 获取已安装包的安装路径。
  /// 通过解析 choco list --limit-output 并查找对应目录实现。
  Future<String?> getPackageInstallPath(String packageName) async {
    // 尝试通过 choco info 获取安装信息
    try {
      final escaped = packageName.replaceAll("'", "''");
      final result = await Process.run(
        _powershell,
        [
          '-NoProfile',
          '-Command',
          "choco info '$escaped' --local-only",
        ],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        // 尝试从输出中解析 Install Location
        final lines = output.split('\n');
        for (final line in lines) {
          final lower = line.toLowerCase();
          if (lower.contains('install location') || lower.contains('installlocation')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              return parts.sublist(1).join(':').trim();
            }
          }
        }
      }
    } catch (_) {}

    // 回退：尝试在默认 chocolatey 目录中查找
    try {
      final result = await Process.run(
        _powershell,
        [
          '-NoProfile',
          '-Command',
          r"$env:ChocolateyInstall + '\lib\' + '" + packageName + r"'",
        ],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty && await Directory(path).exists()) {
          return path;
        }
      }
    } catch (_) {}

    return null;
  }

  /// 批量获取已安装包路径（利用 PowerShell 一次性查询）
  Future<Map<String, String>> getInstalledPackagePaths() async {
    final paths = <String, String>{};
    try {
      final result = await Process.run(
        _powershell,
        [
          '-NoProfile',
          '-Command',
          r'''
$chocoLib = "$env:ChocolateyInstall\lib"
if (Test-Path $chocoLib) {
  Get-ChildItem $chocoLib -Directory | ForEach-Object {
    Write-Output "$($_.Name)|$($_.FullName)"
  }
}
''',
        ],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        for (final line in (result.stdout as String).split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split('|');
          if (parts.length == 2) {
            paths[parts[0].trim().toLowerCase()] = parts[1].trim();
          }
        }
      }
    } catch (_) {}
    return paths;
  }

  /// Installs [packageName]. Optionally specify [installDir] to override the
  /// install location (passed as `--install-directory` to choco).
  Future<bool> installPackage(
    String packageName, {
    void Function(String)? onOutput,
    String? installDir,
    String? version,
  }) async {
    String cmd = "choco install '${packageName.replaceAll("'", "''")}' -y --no-progress";
    if (installDir != null && installDir.trim().isNotEmpty) {
      final escaped = installDir.trim().replaceAll("'", "''");
      cmd += " --install-directory '$escaped'";
    }
    if (version != null && version.trim().isNotEmpty) {
      cmd += " --version='${version.trim()}'";
    }
    return _runStreaming(cmd, onOutput: onOutput);
  }

  Future<bool> uninstallPackage(String packageName,
      {void Function(String)? onOutput}) async {
    return _runStreaming(
        "choco uninstall '${packageName.replaceAll("'", "''")}' -y --no-progress",
        onOutput: onOutput);
  }

  Future<bool> upgradePackage(String packageName,
      {void Function(String)? onOutput}) async {
    return _runStreaming(
        "choco upgrade '${packageName.replaceAll("'", "''")}' -y --no-progress",
        onOutput: onOutput);
  }

  Future<bool> _runStreaming(String command,
      {void Function(String)? onOutput}) async {
    try {
      final process = await Process.start(
        _powershell,
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
        runInShell: false,
      );
      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((line) => onOutput?.call(line));
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((line) => onOutput?.call('[ERR] $line'));
      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (e) {
      onOutput?.call('Error: $e');
      return false;
    }
  }

  /// Fetches detailed package info via `choco info <name>` (community feed).
  Future<PackageInfo> getPackageInfo(String packageName) async {
    final escaped = packageName.replaceAll("'", "''");
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', "choco info '$escaped'"],
        runInShell: false,
      );
      final output = result.stdout as String;
      return _parseChocoInfo(packageName, output);
    } catch (e) {
      return PackageInfo(
        name: packageName,
        title: packageName,
        version: '',
        author: '',
        summary: '',
        description: '',
        packageUrl: 'https://community.chocolatey.org/packages/$packageName',
        projectUrl: '',
        licenseUrl: '',
        downloadCount: '',
        tags: '',
        dependencies: '',
      );
    }
  }

  PackageInfo _parseChocoInfo(String name, String output) {
    String title = name, version = '', author = '', summary = '';
    String projectUrl = '', licenseUrl = '', downloadCount = '', tags = '';
    String dependencies = '';

    for (final raw in output.split('\n')) {
      final line = raw.trim();
      String val(String prefix) {
        if (line.toLowerCase().startsWith(prefix.toLowerCase())) {
          return line.substring(prefix.length).trim();
        }
        return '';
      }

      final t = val('Title:');
      if (t.isNotEmpty) title = t;
      final v = val('Published:');
      // version is on "Package Name:" or "X.Y.Z" after the name line
      // Try dedicated "Version X.Y.Z" pattern
      final vMatch = RegExp(r'^\s*(\d+[\d.]+)\s*$').firstMatch(line);
      if (vMatch != null && version.isEmpty) version = vMatch.group(1) ?? '';
      final vv = val('Software Version:');
      if (vv.isNotEmpty) version = vv;
      final a = val('Package Maintainer(s):');
      if (a.isNotEmpty) author = a;
      final a2 = val('Package Submitter:');
      if (a2.isNotEmpty && author.isEmpty) author = a2;
      final s = val('Summary:');
      if (s.isNotEmpty) summary = s;
      final d = val('Description:');
      if (d.isNotEmpty && summary.isEmpty) summary = d;
      final pu = val('Project Url:');
      if (pu.isNotEmpty) projectUrl = pu;
      final lu = val('License Url:');
      if (lu.isNotEmpty) licenseUrl = lu;
      final dc = val('Downloads:');
      if (dc.isNotEmpty) downloadCount = dc;
      final tg = val('Tags:');
      if (tg.isNotEmpty) tags = tg;
      final dep = val('Dependencies:');
      if (dep.isNotEmpty) dependencies = dep;
      if (v.isNotEmpty && version.isEmpty) version = v;
    }

    // Attempt to extract version from "name version" line
    if (version.isEmpty) {
      final lines = output.split('\n');
      for (final raw in lines) {
        final line = raw.trim();
        if (line.toLowerCase().startsWith(name.toLowerCase())) {
          final parts = line.split(' ');
          if (parts.length >= 2) {
            final candidate = parts.last.trim();
            if (RegExp(r'^\d').hasMatch(candidate)) {
              version = candidate;
              break;
            }
          }
        }
      }
    }

    return PackageInfo(
      name: name,
      title: title.isEmpty ? name : title,
      version: version,
      author: author,
      summary: summary,
      description: summary,
      packageUrl: 'https://community.chocolatey.org/packages/$name',
      projectUrl: projectUrl,
      licenseUrl: licenseUrl,
      downloadCount: downloadCount,
      tags: tags,
      dependencies: dependencies,
    );
  }

  List<PackageModel> _parseListOutput(String output,
      {required bool isInstalled}) {
    final packages = <PackageModel>[];
    for (final raw in output.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\d+ package').hasMatch(line)) continue;
      final parts = line.split('|');
      if (parts.length >= 2) {
        packages.add(PackageModel(
          name: parts[0].trim(),
          version: parts[1].trim(),
          description: parts.length >= 3 ? parts[2].trim() : '',
          isInstalled: isInstalled,
        ));
      }
    }
    return packages;
  }

  // ---- Source management ----

  /// 列出所有 Chocolatey 源
  Future<List<ChocoSource>> listSources() async {
    final sources = <ChocoSource>[];
    try {
      final result = await Process.run(
        _powershell,
        ['-NoProfile', '-Command', 'choco source list --limit-output'],
        runInShell: false,
      );
      if (result.exitCode != 0) return sources;
      for (final raw in (result.stdout as String).split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        // 格式: Name|Url|Disabled|Username|Password|Priority
        final parts = line.split('|');
        if (parts.length >= 2) {
          sources.add(ChocoSource(
            name: parts[0].trim(),
            url: parts[1].trim(),
            disabled: parts.length >= 3 && parts[2].trim() == 'True',
            username: parts.length >= 4 && parts[3].trim().isNotEmpty ? parts[3].trim() : null,
            priority: parts.length >= 7 && parts[6].trim().isNotEmpty ? int.tryParse(parts[6].trim()) : null,
          ));
        }
      }
    } catch (_) {}
    return sources;
  }

  /// 添加 Chocolatey 源
  Future<bool> addSource({
    required String name,
    required String url,
    int? priority,
    String? username,
    String? password,
  }) async {
    String cmd = "choco source add --name='${name.replaceAll("'", "''")}' --source='${url.replaceAll("'", "''")}'";
    if (priority != null) cmd += ' --priority=$priority';
    if (username != null && username.isNotEmpty) {
      cmd += " --user='${username.replaceAll("'", "''")}'";
      if (password != null && password.isNotEmpty) {
        cmd += " --password='${password.replaceAll("'", "''")}'";
      }
    }
    return _runStreaming(cmd);
  }

  /// 移除 Chocolatey 源
  Future<bool> removeSource(String name) async {
    return _runStreaming("choco source remove --name='${name.replaceAll("'", "''")}'");
  }

  /// 启用源
  Future<bool> enableSource(String name) async {
    return _runStreaming("choco source enable --name='${name.replaceAll("'", "''")}'");
  }

  /// 禁用源
  Future<bool> disableSource(String name) async {
    return _runStreaming("choco source disable --name='${name.replaceAll("'", "''")}'");
  }
}
