import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import 'installed_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'recommended_screen.dart';

/// Main scaffold with NavigationRail on the left and content on the right.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0=推荐, 1=已安装, 2=搜索, 3=设置
  int _selectedIndex = 0;

  static const List<NavigationRailDestination> _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.star_outline),
      selectedIcon: Icon(Icons.star),
      label: Text('推荐'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('已安装'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: Text('搜索'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('设置'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = AppProviderScope.of(context);
      await provider.loadInstallDir();
      await provider.detectChoco();
      if (provider.chocoInstalled) {
        await provider.loadInstalledPackages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Row(
          children: [
            // App logo
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.local_cafe_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Chocolatey GUI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: _buildChocoStatusChip(context, provider),
          ),
          IconButton(
            icon: Icon(
              provider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: '切换主题',
            onPressed: provider.toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chocolatey not installed banner
          if (!provider.detectingChoco && !provider.chocoInstalled)
            _buildChocoBanner(context, provider),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orange banner shown when Chocolatey is not installed.
  Widget _buildChocoBanner(BuildContext context, AppProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 20, color: cs.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '未检测到 Chocolatey，部分功能不可用。',
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
              ),
              onPressed: () => _installChocoFromBanner(context, provider),
              child: const Text('立即安装'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChocoStatusChip(BuildContext context, AppProvider provider) {
    if (provider.detectingChoco) {
      return const Chip(
        avatar: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('检测中…'),
      );
    }
    if (provider.chocoInstalled) {
      return Chip(
        avatar: const Icon(Icons.check_circle, size: 16),
        label: Text('choco v${provider.chocoVersion}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      );
    }
    return Chip(
      avatar: const Icon(Icons.warning_amber, size: 16),
      label: const Text('未安装 Chocolatey'),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const RecommendedScreen();
      case 1:
        return const InstalledScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const RecommendedScreen();
    }
  }

  Future<void> _installChocoFromBanner(
      BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('安装 Chocolatey'),
        content: const Text(
          '将运行官方安装脚本。\n系统会弹出 UAC 授权窗口，请点击"是"继续。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认安装'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 展示实时日志 Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChocoInstallingDialog(),
    );

    final success = await provider.installChocolatey();

    if (!context.mounted) return;
    // 关闭安装中 Dialog
    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chocolatey 安装成功！'),
        backgroundColor: Colors.green,
      ));
      await provider.loadInstalledPackages();
    } else {
      // 安装失败 → 展示详细错误 Dialog
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => _ChocoInstallFailedDialog(
          log: provider.chocoInstallLog,
          onCleanup: () async {
            Navigator.of(ctx).pop();
            await _cleanupCache(context, provider);
          },
        ),
      );
    }
  }

  /// 调用清理缓存并展示结果
  Future<void> _cleanupCache(
      BuildContext context, AppProvider provider) async {
    // 展示 loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('正在清理缓存…'),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final logs = await provider.cleanupChocoFailedInstall();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // 关闭 loading

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded),
            SizedBox(width: 8),
            Text('清理完成'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: SelectableText(
              logs.join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 安装中实时日志 Dialog
// ---------------------------------------------------------------------------

class _ChocoInstallingDialog extends StatefulWidget {
  const _ChocoInstallingDialog();

  @override
  State<_ChocoInstallingDialog> createState() => _ChocoInstallingDialogState();
}

class _ChocoInstallingDialogState extends State<_ChocoInstallingDialog> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);
    final log = provider.chocoInstallLog;
    _scrollToBottom();

    return AlertDialog(
      title: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('正在安装 Chocolatey…'),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请在弹出的 UAC 窗口中点击"是"，安装完成后窗口将自动关闭。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: SelectableText(
                    log.isEmpty ? '等待输出…' : log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 安装失败 Dialog — 展示详细日志 + 清理缓存按钮
// ---------------------------------------------------------------------------

class _ChocoInstallFailedDialog extends StatelessWidget {
  const _ChocoInstallFailedDialog({
    required this.log,
    required this.onCleanup,
  });

  final String log;
  final VoidCallback onCleanup;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 8),
          const Text('Chocolatey 安装失败'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '安装过程中发生错误，请查看以下日志。\n'
              '如果是网络或权限问题导致文件残留，可点击"清理缓存"按钮清除临时文件后重试。',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cs.error.withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: SelectableText(
                    log.isEmpty ? '（无日志输出）' : log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.cleaning_services_rounded, size: 16),
          label: const Text('清理缓存'),
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          onPressed: onCleanup,
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
