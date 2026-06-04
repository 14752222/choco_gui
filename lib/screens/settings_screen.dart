import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../models/package_model.dart';

/// Settings page: theme toggle, install directory, source management, Chocolatey status, and app info.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _dirController;

  @override
  void initState() {
    super.initState();
    _dirController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = AppProviderScope.of(context);
    // Only update if the controller is out of sync (avoid cursor jump on every rebuild)
    if (_dirController.text != provider.installDir) {
      _dirController.text = provider.installDir;
    }
    // Load sources on first build — defer to after the frame to avoid
    // calling notifyListeners (via loadSources) during the build phase.
    if (provider.sources.isEmpty && !provider.loadingSources) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.loadSources();
        }
      });
    }
  }

  @override
  void dispose() {
    _dirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('设置', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 24),

        // ---- Appearance ----
        _sectionHeader(context, '外观'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色主题'),
            subtitle: const Text('切换浅色 / 深色外观'),
            value: provider.themeMode == ThemeMode.dark,
            onChanged: (_) => provider.toggleTheme(),
          ),
        ),
        const SizedBox(height: 20),

        // ---- Install Location ----
        _sectionHeader(context, '安装位置'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        color: colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '默认安装目录',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '留空则使用 Chocolatey 默认路径',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '通过 -ia 参数传递给安装程序（支持 NSIS/MSI 等）',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Show Choco install path info
                if (provider.chocoInstallPath.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chocolatey 安装路径: ${provider.chocoInstallPath}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dirController,
                        decoration: InputDecoration(
                          hintText: provider.chocoInstallPath.isNotEmpty
                              ? provider.chocoInstallPath
                              : '例如: D:\\Programs',
                          prefixIcon: const Icon(Icons.folder_open, size: 18),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: _dirController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  tooltip: '清除',
                                  onPressed: () {
                                    _dirController.clear();
                                    setState(() {});
                                    provider.setInstallDir('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Browse folder button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder, size: 16),
                      label: const Text('浏览'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result =
                            await FilePicker.platform.getDirectoryPath(
                          dialogTitle: '选择默认安装目录',
                        );
                        if (result == null || !mounted) return;
                        _dirController.text = result;
                        provider.setInstallDir(result);
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('已设置安装目录: $result'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('保存'),
                      onPressed: () {
                        provider.setInstallDir(_dirController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _dirController.text.trim().isEmpty
                                  ? '已恢复默认安装目录'
                                  : '默认安装目录已设为: ${_dirController.text.trim()}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (provider.installDir.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '当前默认安装目录: ${provider.installDir}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ---- Source management ----
        _sectionHeader(context, '软件源管理'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.cloud_outlined,
                        color: colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chocolatey 软件源',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '管理包下载源，可添加国内镜像源加速下载',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: '添加源',
                      onPressed: () => _showAddSourceDialog(context, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: '刷新源列表',
                      onPressed: provider.loadingSources ? null : () => provider.loadSources(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (provider.loadingSources)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.sources.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无软件源')),
                )
              else
                ...provider.sources.map((source) => _buildSourceTile(context, provider, source)),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- Chocolatey ----
        _sectionHeader(context, 'Chocolatey'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: provider.chocoInstalled
                        ? Colors.green.withAlpha(30)
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    provider.chocoInstalled
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: provider.chocoInstalled
                        ? Colors.green
                        : colorScheme.onErrorContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.detectingChoco
                            ? '正在检测...'
                            : provider.chocoInstalled
                                ? 'Chocolatey 已安装'
                                : 'Chocolatey 未安装',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (provider.chocoInstalled &&
                          provider.chocoVersion.isNotEmpty)
                        Text(
                          '版本 ${provider.chocoVersion}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (provider.detectingChoco)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '重新检测',
                    onPressed: () async {
                      await provider.detectChoco();
                      if (provider.chocoInstalled) {
                        await provider.loadInstalledPackages();
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ---- About ----
        _sectionHeader(context, '关于'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text('Chocolatey GUI'),
                  subtitle: Text('一款基于 Flutter 的 Windows 桌面 Chocolatey 图形界面'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.code),
                  title: Text('版本'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceTile(BuildContext context, AppProvider provider, ChocoSource source) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = source.name;
    final url = source.url;
    final disabled = source.disabled;
    final isBuiltin = name == 'chocolatey' || name == 'chocolatey.licensed';

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled ? cs.surfaceContainerHighest : cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          disabled ? Icons.cloud_off : Icons.cloud_done,
          size: 18,
          color: disabled ? cs.outline : cs.primary,
        ),
      ),
      title: Row(
        children: [
          Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (disabled) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('已禁用',
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onErrorContainer, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        url,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontFamily: 'Consolas',
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (disabled)
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 18),
              tooltip: '启用',
              onPressed: () async {
                final ok = await provider.enableSource(name);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '已启用源: $name' : '启用失败')),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.pause, size: 18),
              tooltip: '禁用',
              onPressed: isBuiltin ? null : () async {
                final ok = await provider.disableSource(name);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '已禁用源: $name' : '禁用失败')),
                );
              },
            ),
          if (!isBuiltin)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              tooltip: '删除',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除源 "$name" 吗？\n$url'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cs.error),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !mounted) return;
                final ok = await provider.removeSource(name);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '已删除源: $name' : '删除失败')),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showAddSourceDialog(BuildContext context, AppProvider provider) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final priorityCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline),
            SizedBox(width: 8),
            Text('添加软件源'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '源名称',
                  hintText: '例如: ustc',
                  prefixIcon: Icon(Icons.label, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: '源地址',
                  hintText: '例如: https://mirrors.ustc.edu.cn/chocolatey/',
                  prefixIcon: Icon(Icons.link, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priorityCtrl,
                decoration: const InputDecoration(
                  labelText: '优先级（可选）',
                  hintText: '数字越小优先级越高，留空使用默认',
                  prefixIcon: Icon(Icons.sort, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Text(
                '常用国内镜像源:\n'
                '  中科大: https://mirrors.ustc.edu.cn/chocolatey/\n'
                '  清华: https://mirrors.tuna.tsinghua.edu.cn/chocolatey/',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    urlCtrl.dispose();
    priorityCtrl.dispose();

    if (result != true || !mounted) return;

    final name = nameCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('源名称和地址不能为空')),
      );
      return;
    }

    final priority = priorityCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(priorityCtrl.text.trim());

    final ok = await provider.addSource(name: name, url: url, priority: priority);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已添加源: $name' : '添加失败，请查看日志')),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
    );
  }
}
