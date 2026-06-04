import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/package_model.dart';
import '../services/choco_service.dart';
import 'package_detail_screen.dart';

/// Curated list of recommended / popular packages.
class RecommendedScreen extends StatelessWidget {
  const RecommendedScreen({super.key});

  /// Curated list of popular Chocolatey packages.
  static const List<_RecommendedPkg> _recommended = [
    _RecommendedPkg('googlechrome',  '1.0',  '🌐', '浏览器',     'Google Chrome 浏览器'),
    _RecommendedPkg('firefox',       '1.0',  '🦊', '浏览器',     'Mozilla Firefox 浏览器'),
    _RecommendedPkg('vscode',        '1.0',  '🖊️', '开发工具',   'Visual Studio Code 代码编辑器'),
    _RecommendedPkg('git',           '1.0',  '🔀', '开发工具',   'Git 版本控制工具'),
    _RecommendedPkg('nodejs',        '1.0',  '🟩', '开发工具',   'Node.js JavaScript 运行环境'),
    _RecommendedPkg('python',        '1.0',  '🐍', '开发工具',   'Python 编程语言'),
    _RecommendedPkg('7zip',          '1.0',  '📦', '工具',       '7-Zip 压缩/解压工具'),
    _RecommendedPkg('vlc',           '1.0',  '🎬', '媒体',       'VLC 媒体播放器'),
    _RecommendedPkg('winrar',        '1.0',  '📁', '工具',       'WinRAR 压缩工具'),
    _RecommendedPkg('putty',         '1.0',  '🖥️', '工具',       'PuTTY SSH/Telnet 客户端'),
    _RecommendedPkg('everything',    '1.0',  '🔍', '工具',       'Everything 极速文件搜索'),
    _RecommendedPkg('obs-studio',    '1.0',  '🎙️', '媒体',       'OBS Studio 直播/录屏工具'),
    _RecommendedPkg('postman',       '1.0',  '📡', '开发工具',   'Postman API 测试工具'),
    _RecommendedPkg('docker-desktop','1.0',  '🐳', '开发工具',   'Docker Desktop 容器平台'),
    _RecommendedPkg('powershell-core','1.0', '💻', '开发工具',   'PowerShell Core 跨平台命令行'),
    _RecommendedPkg('windirstat',    '1.0',  '💾', '工具',       'WinDirStat 磁盘空间分析'),
    _RecommendedPkg('cpu-z',         '1.0',  '🔧', '工具',       'CPU-Z 系统信息查看'),
    _RecommendedPkg('ffmpeg',        '1.0',  '🎞️', '媒体',       'FFmpeg 音视频处理工具'),
    _RecommendedPkg('winscp',        '1.0',  '📂', '工具',       'WinSCP SFTP/FTP 文件传输'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final installedNames = provider.installedPackages
        .map((p) => p.name.toLowerCase())
        .toSet();

    // Group by category
    final Map<String, List<_RecommendedPkg>> grouped = {};
    for (final p in _recommended) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) => _buildCategory(
              context,
              provider,
              entry.key,
              entry.value,
              installedNames,
            )),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('精选推荐软件',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('一键安装常用 Windows 软件，省时省力',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSecondaryContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    AppProvider provider,
    String category,
    List<_RecommendedPkg> pkgs,
    Set<String> installedNames,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            category,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...pkgs.map((p) {
          final isInstalled = installedNames.contains(p.id.toLowerCase());
          final pkg = PackageModel(
            name: p.id,
            version: '',
            description: p.description,
            isInstalled: isInstalled,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _RecommendedCard(
              pkg: p,
              model: pkg,
              isInstalled: isInstalled,
              onInstall: isInstalled
                  ? null
                  : () => _confirmAndInstall(context, provider, p.id),
              onTap: () => _openDetail(context, p.id, p.description, isInstalled),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  void _openDetail(
      BuildContext context, String name, String description, bool isInstalled) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PackageDetailScreen(
        packageName: name,
        initialDescription: description,
        isInstalled: isInstalled,
      ),
    ));
  }

  Future<void> _confirmAndInstall(
    BuildContext context,
    AppProvider provider,
    String packageName,
  ) async {
    if (!provider.chocoInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先安装 Chocolatey！')),
      );
      return;
    }

    // Show dialog with directory selection; returns chosen dir or null (cancelled)
    final result = await showDialog<_InstallConfirmResult>(
      context: context,
      builder: (ctx) => _InstallConfirmDialog(
        packageName: packageName,
        defaultDir: provider.installDir,
        chocoInstallPath: provider.chocoInstallPath,
      ),
    );

    if (result == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecommendedInstallDialog(
        packageName: packageName,
        provider: provider,
        installDir: result.installDir,
        version: result.version,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RecommendedPkg {
  final String id;
  final String version;
  final String emoji;
  final String category;
  final String description;
  const _RecommendedPkg(
      this.id, this.version, this.emoji, this.category, this.description);
}

// ---------------------------------------------------------------------------

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.pkg,
    required this.model,
    required this.isInstalled,
    required this.onTap,
    this.onInstall,
  });

  final _RecommendedPkg pkg;
  final PackageModel model;
  final bool isInstalled;
  final VoidCallback? onInstall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Emoji icon
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pkg.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pkg.id,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (isInstalled) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: const Text('已安装'),
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            backgroundColor: Colors.green.withAlpha(30),
                            labelStyle: const TextStyle(
                                color: Colors.green, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      pkg.description,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Install / installed button
              if (!isInstalled)
                FilledButton.icon(
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('安装'),
                  onPressed: onInstall,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Install confirm result
// ---------------------------------------------------------------------------

class _InstallConfirmResult {
  final String? installDir;
  final String? version;
  const _InstallConfirmResult({this.installDir, this.version});
}

// ---------------------------------------------------------------------------
// Install confirm dialog — with optional directory selection
// ---------------------------------------------------------------------------

class _InstallConfirmDialog extends StatefulWidget {
  const _InstallConfirmDialog({
    required this.packageName,
    required this.defaultDir,
    required this.chocoInstallPath,
  });
  final String packageName;
  final String defaultDir;
  final String chocoInstallPath;

  @override
  State<_InstallConfirmDialog> createState() => _InstallConfirmDialogState();
}

class _InstallConfirmDialogState extends State<_InstallConfirmDialog> {
  late TextEditingController _dirCtrl;
  String? _selectedVersion;
  List<String> _versions = [];
  bool _loadingVersions = false;
  final ChocoService _service = ChocoService();

  String get _effectiveDefaultDir =>
      widget.defaultDir.isNotEmpty ? widget.defaultDir : widget.chocoInstallPath;

  @override
  void initState() {
    super.initState();
    _dirCtrl = TextEditingController(text: _effectiveDefaultDir);
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _loadingVersions = true);
    final versions = await _service.getPackageVersions(widget.packageName);
    if (mounted) {
      setState(() {
        _versions = versions;
        _loadingVersions = false;
      });
    }
  }

  @override
  void dispose() {
    _dirCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择安装目录',
    );
    if (result != null && mounted) {
      setState(() => _dirCtrl.text = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('安装 ${widget.packageName}')),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要安装 "${widget.packageName}" 吗？'),
            const SizedBox(height: 16),

            // Version selector
            Text(
              '安装版本',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _loadingVersions
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('加载版本中...'),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String?>(
                          initialValue: _selectedVersion,
                          decoration: InputDecoration(
                            hintText: '最新版本',
                            prefixIcon: const Icon(Icons.tag, size: 18),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('最新版本 (默认)'),
                            ),
                            ..._versions.map((v) => DropdownMenuItem<String?>(
                                  value: v,
                                  child: Text(v, style: const TextStyle(fontSize: 13)),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedVersion = v),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '刷新版本列表',
                  onPressed: _loadingVersions ? null : _loadVersions,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Install directory
            Text(
              '安装目录（可选）',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dirCtrl,
                    decoration: InputDecoration(
                      hintText: '留空使用 Chocolatey 默认目录',
                      prefixIcon: const Icon(Icons.folder_open, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: _effectiveDefaultDir.isNotEmpty
                          ? 'Choco 默认: $_effectiveDefaultDir'
                          : '默认目录: Chocolatey 自动决定',
                      suffixIcon: _dirCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              tooltip: '清除',
                              onPressed: () =>
                                  setState(() => _dirCtrl.clear()),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder, size: 16),
                  label: const Text('浏览'),
                  onPressed: _pickDirectory,
                ),
              ],
            ),
            if (_dirCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '将安装到: ${_dirCtrl.text.trim()}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                _effectiveDefaultDir.isNotEmpty
                    ? '将使用 Choco 默认目录: $_effectiveDefaultDir'
                    : '将使用 Chocolatey 默认安装目录',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download, size: 16),
          label: const Text('安装'),
          onPressed: () => Navigator.of(context).pop(
            _InstallConfirmResult(
              installDir: _dirCtrl.text.trim().isEmpty
                  ? null
                  : _dirCtrl.text.trim(),
              version: _selectedVersion,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Install progress dialog (reused from search screen pattern)
// ---------------------------------------------------------------------------

class _RecommendedInstallDialog extends StatefulWidget {
  const _RecommendedInstallDialog({
    required this.packageName,
    required this.provider,
    this.installDir,
    this.version,
  });
  final String packageName;
  final AppProvider provider;
  final String? installDir;
  final String? version;

  @override
  State<_RecommendedInstallDialog> createState() =>
      _RecommendedInstallDialogState();
}

class _RecommendedInstallDialogState
    extends State<_RecommendedInstallDialog> {
  bool _done = false;
  bool _success = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    widget.provider.clearOperationLog();
    final result = await widget.provider.installPackage(
      widget.packageName,
      installDir: widget.installDir,
      version: widget.version,
    );
    if (mounted) {
      setState(() {
        _done = true;
        _success = result;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('安装 ${widget.packageName}'),
          if (widget.version != null && widget.version!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.tag, size: 13, color: cs.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '版本: ${widget.version}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          if (widget.installDir != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 13, color: cs.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.installDir!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 320,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Scrollbar(
                  controller: _scroll,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: SelectableText(
                      provider.operationLog.isEmpty
                          ? '正在启动…'
                          : provider.operationLog,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_done)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (_done)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(_success ? Icons.check_circle : Icons.error,
                        color: _success ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(_success ? '安装成功！' : '安装失败，请查看上方日志。'),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (_done)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
      ],
    );
  }
}
