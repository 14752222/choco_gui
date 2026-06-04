import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../widgets/package_card.dart';
import '../widgets/pagination_bar.dart';
import 'package_detail_screen.dart';

/// Screen displaying all locally installed Chocolatey packages with pagination.
class InstalledScreen extends StatelessWidget {
  const InstalledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = AppProviderScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(context, provider),
        const Divider(height: 1),
        Expanded(child: _buildBody(context, provider)),
        if (!provider.loadingInstalled && provider.installedPackages.isNotEmpty)
          PaginationBar(
            currentPage: provider.installedPage,
            totalPages: provider.installedTotalPages,
            onPageChanged: provider.setInstalledPage,
          ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('已安装的包', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 12),
          if (!provider.loadingInstalled && provider.installedPackages.isNotEmpty)
            Chip(
              label: Text('${provider.installedPackages.length} 个'),
              visualDensity: VisualDensity.compact,
            ),
          const Spacer(),
          // Show install Chocolatey button when not installed
          if (!provider.chocoInstalled && !provider.detectingChoco)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('安装 Chocolatey'),
                onPressed: () => _installChoco(context, provider),
              ),
            ),
          IconButton.outlined(
            icon: provider.loadingInstalled
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: provider.loadingInstalled
                ? null
                : provider.loadInstalledPackages,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider) {
    if (provider.detectingChoco) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!provider.chocoInstalled) {
      return _buildNotInstalled(context, provider);
    }
    if (provider.loadingInstalled) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.installedPackages.isEmpty) {
      return const Center(child: Text('未找到已安装的包，请刷新重试。'));
    }

    final items = provider.installedPageItems;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final pkg = items[index];
        return PackageCard(
          package: pkg,
          isInstalled: true,
          installPath: provider.getPackagePath(pkg.name),
          onUninstall: () => _uninstall(context, provider, pkg.name),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PackageDetailScreen(
              packageName: pkg.name,
              initialDescription: pkg.description,
              isInstalled: true,
            ),
          )),
        );
      },
    );
  }

  Widget _buildNotInstalled(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            '未检测到 Chocolatey',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('请先安装 Chocolatey 包管理器以使用此应用。'),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('安装 Chocolatey'),
            onPressed: () => _installChoco(context, provider),
          ),
        ],
      ),
    );
  }

  Future<void> _installChoco(
      BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('安装 Chocolatey'),
        content: const Text(
          '将以管理员权限运行 PowerShell 安装脚本。\n'
          '系统会弹出 UAC 授权窗口，请点击"是"继续。',
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('正在安装 Chocolatey…'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '请在弹出的 UAC 窗口中点击"是"，\n安装完成后窗口将自动关闭。',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );

    final success = await provider.installChocolatey();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close progress dialog

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        success ? 'Chocolatey 安装成功！' : 'Chocolatey 安装失败，请检查权限后重试。',
      ),
      backgroundColor:
          success ? Colors.green : Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _uninstall(
      BuildContext context, AppProvider provider, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text('确定要卸载 "$name" 吗？'),
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
      builder: (ctx) => _OperationProgressDialog(
        title: '卸载 $name',
        provider: provider,
        operation: () => provider.uninstallPackage(name),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable stateful dialog that streams operation output.
// ---------------------------------------------------------------------------

class _OperationProgressDialog extends StatefulWidget {
  const _OperationProgressDialog({
    required this.title,
    required this.provider,
    required this.operation,
  });

  final String title;
  final AppProvider provider;
  final Future<bool> Function() operation;

  @override
  State<_OperationProgressDialog> createState() =>
      _OperationProgressDialogState();
}

class _OperationProgressDialogState
    extends State<_OperationProgressDialog> {
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
    final result = await widget.operation();
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
      title: Text(widget.title),
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
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(_success ? '操作完成！' : '操作失败，请查看上方日志。'),
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
