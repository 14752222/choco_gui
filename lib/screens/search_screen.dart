import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/choco_service.dart';
import '../widgets/package_card.dart';
import '../widgets/pagination_bar.dart';
import 'package_detail_screen.dart';

/// Screen for searching Chocolatey packages from the community feed.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _exactSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Search bar ----
        _buildSearchBar(context, provider),
        const Divider(height: 1),
        // ---- Results ----
        Expanded(
          child: _buildBody(context, provider),
        ),
        // ---- Pagination ----
        if (!provider.searching && provider.searchResults.isNotEmpty)
          PaginationBar(
            currentPage: provider.searchPage,
            totalPages: provider.searchTotalPages,
            onPageChanged: provider.setSearchPage,
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索 Chocolatey 包 (e.g. git, vlc, nodejs)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) => _doSearch(context, provider, value),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: provider.searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: const Text('搜索'),
                onPressed: provider.searching
                    ? null
                    : () => _doSearch(
                        context, provider, _searchController.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('搜索模式:', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _exactSearch = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: !_exactSearch ? cs.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !_exactSearch ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Text('模糊搜索',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: !_exactSearch ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      fontWeight: !_exactSearch ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _exactSearch = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _exactSearch ? cs.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _exactSearch ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Text('精确搜索',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _exactSearch ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      fontWeight: _exactSearch ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider) {
    if (provider.searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.lastQuery.isEmpty) {
      return const Center(
        child: Text('输入关键词后按回车或点击搜索'),
      );
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Text('未找到与 "${provider.lastQuery}" 相关的包'),
      );
    }

    final items = provider.searchPageItems;
    final installedNames = provider.installedPackages
        .map((p) => p.name.toLowerCase())
        .toSet();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final pkg = items[index];
        final isInstalled = installedNames.contains(pkg.name.toLowerCase());
        return PackageCard(
          package: pkg,
          isInstalled: isInstalled,
          installPath: isInstalled ? provider.getPackagePath(pkg.name) : null,
          onInstall: isInstalled
              ? null
              : () => _confirmAndInstall(context, provider, pkg.name),
          onUninstall: isInstalled
              ? () => _confirmAndUninstall(context, provider, pkg.name)
              : null,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PackageDetailScreen(
              packageName: pkg.name,
              initialDescription: pkg.description,
              isInstalled: isInstalled,
            ),
          )),
        );
      },
    );
  }

  void _doSearch(BuildContext context, AppProvider provider, String query) {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    provider.searchPackages(query.trim(), exact: _exactSearch);
  }

  /// Shows a confirmation dialog where the user can optionally override the
  /// install directory for this single installation, then proceeds to install.
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
      builder: (ctx) => _InstallProgressDialog(
        packageName: packageName,
        provider: provider,
        installDir: result.installDir,
        version: result.version,
      ),
    );
  }

  /// Shows a confirmation dialog then uninstalls the package.
  Future<void> _confirmAndUninstall(
    BuildContext context,
    AppProvider provider,
    String packageName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text('确定要卸载 "$packageName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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
      builder: (ctx) => _UninstallProgressDialog(
        packageName: packageName,
        provider: provider,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class returned by confirm dialog
// ---------------------------------------------------------------------------

class _InstallConfirmResult {
  final String? installDir; // null or empty = use default
  final String? version;
  const _InstallConfirmResult({this.installDir, this.version});
}

// ---------------------------------------------------------------------------
// Confirm + version selection + path override dialog
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
  late TextEditingController _dirController;
  String? _selectedVersion;
  List<String> _versions = [];
  bool _loadingVersions = false;
  final ChocoService _service = ChocoService();

  String get _effectiveDefaultDir =>
      widget.defaultDir.isNotEmpty ? widget.defaultDir : widget.chocoInstallPath;

  @override
  void initState() {
    super.initState();
    _dirController = TextEditingController(text: _effectiveDefaultDir);
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
    _dirController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择安装目录',
    );
    if (result != null && mounted) {
      setState(() => _dirController.text = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: colorScheme.primary),
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
            Text('即将安装包 "${widget.packageName}"。',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),

            // ---- Version selector ----
            Text(
              '安装版本',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
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

            // ---- Install directory ----
            Text(
              '安装目录（可选）',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dirController,
                    decoration: InputDecoration(
                      hintText: '留空则使用默认路径',
                      prefixIcon: const Icon(Icons.folder_open, size: 18),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: _effectiveDefaultDir.isNotEmpty
                          ? 'Choco 默认: $_effectiveDefaultDir'
                          : '默认目录: Chocolatey 自动决定',
                      helperMaxLines: 2,
                      suffixIcon: _dirController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              tooltip: '清除',
                              onPressed: () {
                                _dirController.clear();
                                setState(() {});
                              },
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.download, size: 16),
          label: const Text('开始安装'),
          onPressed: () => Navigator.of(context).pop(
            _InstallConfirmResult(
              installDir: _dirController.text.trim().isEmpty
                  ? null
                  : _dirController.text.trim(),
              version: _selectedVersion,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stateful install progress dialog
// ---------------------------------------------------------------------------

class _InstallProgressDialog extends StatefulWidget {
  const _InstallProgressDialog({
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
  State<_InstallProgressDialog> createState() =>
      _InstallProgressDialogState();
}

class _InstallProgressDialogState extends State<_InstallProgressDialog> {
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
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
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
          if (widget.version != null && widget.version!.isNotEmpty)
            Text(
              '版本: ${widget.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          if (widget.installDir != null && widget.installDir!.isNotEmpty)
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
                          ? '正在启动...'
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
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : Colors.red,
                    ),
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

// ---------------------------------------------------------------------------
// Uninstall progress dialog
// ---------------------------------------------------------------------------

class _UninstallProgressDialog extends StatefulWidget {
  const _UninstallProgressDialog({
    required this.packageName,
    required this.provider,
  });

  final String packageName;
  final AppProvider provider;

  @override
  State<_UninstallProgressDialog> createState() =>
      _UninstallProgressDialogState();
}

class _UninstallProgressDialogState extends State<_UninstallProgressDialog> {
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
    final result =
        await widget.provider.uninstallPackage(widget.packageName);
    if (mounted) {
      setState(() {
        _done = true;
        _success = result;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);

    return AlertDialog(
      title: Text('卸载 ${widget.packageName}'),
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
                          ? '正在启动...'
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
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(_success ? '卸载成功！' : '卸载失败，请查看上方日志。'),
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
