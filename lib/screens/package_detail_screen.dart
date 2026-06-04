import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/choco_service.dart';

/// Full-page detail view for a single Chocolatey package.
class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({
    super.key,
    required this.packageName,
    this.initialDescription = '',
    this.isInstalled = false,
  });

  final String packageName;
  final String initialDescription;
  final bool isInstalled;

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final ChocoService _service = ChocoService();

  bool _loading = true;
  String? _error;
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _service.getPackageInfo(widget.packageName);
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final isInstalled = provider.installedPackages
        .any((p) => p.name.toLowerCase() == widget.packageName.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.packageName),
        actions: [
          if (!isInstalled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('安装'),
                onPressed: () => _install(context, provider),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('卸载'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () => _uninstall(context, provider),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _buildContent(context, isInstalled),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('获取包信息失败'),
          const SizedBox(height: 8),
          Text(_error ?? '', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            onPressed: _fetchInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isInstalled) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final info = _info;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.packageName.isNotEmpty
                        ? widget.packageName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info?.title ?? widget.packageName,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (info?.version != null && info!.version.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text('v${info.version}'),
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            if (isInstalled) ...[
                              const SizedBox(width: 8),
                              Chip(
                                avatar: const Icon(Icons.check_circle,
                                    size: 14, color: Colors.green),
                                label: const Text('已安装'),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                backgroundColor:
                                    Colors.green.withAlpha(25),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (info?.author != null &&
                          info!.author.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '作者: ${info.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Description
        _sectionCard(
          context,
          title: '简介',
          icon: Icons.description_outlined,
          child: Text(
            (info?.summary ?? widget.initialDescription).isEmpty
                ? '暂无描述'
                : (info?.summary ?? widget.initialDescription),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        const SizedBox(height: 12),

        // Details grid
        if (info != null)
          _sectionCard(
            context,
            title: '详细信息',
            icon: Icons.info_outlined,
            child: Column(
              children: [
                if (info.packageUrl.isNotEmpty)
                  _detailRow(
                    context,
                    label: '包页面',
                    value: info.packageUrl,
                    isLink: true,
                  ),
                if (info.projectUrl.isNotEmpty)
                  _detailRow(
                    context,
                    label: '项目主页',
                    value: info.projectUrl,
                    isLink: true,
                  ),
                if (info.downloadCount.isNotEmpty)
                  _detailRow(
                    context,
                    label: '下载次数',
                    value: info.downloadCount,
                  ),
                if (info.licenseUrl.isNotEmpty)
                  _detailRow(
                    context,
                    label: '许可证',
                    value: info.licenseUrl,
                    isLink: true,
                  ),
                if (info.tags.isNotEmpty)
                  _detailRow(context, label: '标签', value: info.tags),
                if (info.dependencies.isNotEmpty)
                  _detailRow(
                      context, label: '依赖', value: info.dependencies),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Install command card
        _sectionCard(
          context,
          title: '安装命令',
          icon: Icons.terminal,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    'choco install ${widget.packageName} -y',
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 13,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  tooltip: '复制命令',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'choco install ${widget.packageName} -y'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('命令已复制'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isLink = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink
                ? InkWell(
                    onTap: () => _launchUrl(value),
                    child: Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(
                    value,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _install(BuildContext context, AppProvider provider) async {
    if (!provider.chocoInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先安装 Chocolatey！')),
      );
      return;
    }

    final result = await showDialog<_InstallConfirmResult>(
      context: context,
      builder: (ctx) => _InstallConfirmDialog(
        packageName: widget.packageName,
        defaultDir: provider.installDir,
        chocoInstallPath: provider.chocoInstallPath,
      ),
    );

    if (result == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DetailInstallDialog(
        packageName: widget.packageName,
        provider: provider,
        version: result.version,
        installDir: result.installDir,
      ),
    );
  }

  Future<void> _uninstall(BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text('确定要卸载 "${widget.packageName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('卸载'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DetailInstallDialog(
        packageName: widget.packageName,
        provider: provider,
        isUninstall: true,
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
// Install confirm dialog with version selection and directory override
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
        child: SingleChildScrollView(
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
            ],
          ),
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

class _DetailInstallDialog extends StatefulWidget {
  const _DetailInstallDialog({
    required this.packageName,
    required this.provider,
    this.isUninstall = false,
    this.version,
    this.installDir,
  });
  final String packageName;
  final AppProvider provider;
  final bool isUninstall;
  final String? version;
  final String? installDir;

  @override
  State<_DetailInstallDialog> createState() => _DetailInstallDialogState();
}

class _DetailInstallDialogState extends State<_DetailInstallDialog> {
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
    final result = widget.isUninstall
        ? await widget.provider.uninstallPackage(widget.packageName)
        : await widget.provider.installPackage(
            widget.packageName,
            version: widget.version,
            installDir: widget.installDir,
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
    final title =
        widget.isUninstall ? '卸载 ${widget.packageName}' : '安装 ${widget.packageName}';
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (!widget.isUninstall && widget.version != null && widget.version!.isNotEmpty)
            Text(
              '版本: ${widget.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          if (!widget.isUninstall && widget.installDir != null && widget.installDir!.isNotEmpty)
            Text(
              '目标目录: ${widget.installDir}',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
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
                    Text(_success
                        ? (widget.isUninstall ? '卸载成功！' : '安装成功！')
                        : (widget.isUninstall
                            ? '卸载失败，请查看日志。'
                            : '安装失败，请查看日志。')),
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

// ---------------------------------------------------------------------------
// Data model for package info parsed from choco info output
// ---------------------------------------------------------------------------

class PackageInfo {
  final String name;
  final String title;
  final String version;
  final String author;
  final String summary;
  final String description;
  final String packageUrl;
  final String projectUrl;
  final String licenseUrl;
  final String downloadCount;
  final String tags;
  final String dependencies;

  const PackageInfo({
    required this.name,
    required this.title,
    required this.version,
    required this.author,
    required this.summary,
    required this.description,
    required this.packageUrl,
    required this.projectUrl,
    required this.licenseUrl,
    required this.downloadCount,
    required this.tags,
    required this.dependencies,
  });
}
