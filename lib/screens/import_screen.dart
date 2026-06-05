import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/imported_config.dart';
import '../providers/bundle_provider.dart';

/// 配置导入页
///
/// 支持粘贴 JSON 或从剪贴板导入别人分享的软件配置。
/// 导入后会自动验证每个包在 Chocolatey 上是否存在，
/// 然后可以一键安装所有可用包。
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _controller = TextEditingController();
  ImportedConfig? _config;
  Map<String, bool>? _verifyResult;
  bool _parsing = false;
  bool _verifying = false;
  String? _parseError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- 解析 JSON ----

  void _parseJson() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _parseError = '请粘贴 JSON 配置内容');
      return;
    }

    setState(() {
      _parsing = true;
      _parseError = null;
      _config = null;
      _verifyResult = null;
    });

    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) {
        setState(() {
          _parseError = 'JSON 格式错误：需要一个对象（{ ... }）';
          _parsing = false;
        });
        return;
      }

      final config = ImportedConfig.fromJson(data);
      if (!config.isValid) {
        setState(() {
          _parseError = '配置中没有有效的包名列表（packages 字段为空）';
          _parsing = false;
        });
        return;
      }

      setState(() {
        _config = config;
        _parseError = null;
        _parsing = false;
      });
    } catch (e) {
      setState(() {
        _parseError = 'JSON 解析失败：$e';
        _parsing = false;
      });
    }
  }

  /// 从剪贴板导入
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _controller.text = data.text!;
      _parseJson();
    } else {
      setState(() => _parseError = '剪贴板为空');
    }
  }

  // ---- 验证 ----

  Future<void> _verify() async {
    if (_config == null) return;

    setState(() => _verifying = true);

    final provider = BundleProviderScope.of(context);
    final result = await provider.verifyPackages(_config!.packages);

    if (mounted) {
      setState(() {
        _verifyResult = result;
        _verifying = false;
      });
    }
  }

  // ---- 安装 ----

  void _startInstall() {
    if (_config == null) return;

    final available = _verifyResult != null
        ? _config!.packages.where((p) => _verifyResult![p] == true).toList()
        : _config!.packages;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可安装的包')),
      );
      return;
    }

    final installConfig = ImportedConfig(
      name: _config!.name,
      description: _config!.description,
      author: _config!.author,
      packages: available,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ImportInstallDialog(
        config: installConfig,
        provider: BundleProviderScope.of(context),
      ),
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入配置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            _buildHelpCard(theme, cs),
            const SizedBox(height: 16),

            // JSON 输入框
            TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: _exampleJson(),
                hintStyle: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: '粘贴 JSON 配置',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // 操作按钮行
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: const Text('从剪贴板导入'),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('解析'),
                    onPressed: _parsing ? null : _parseJson,
                  ),
                ),
              ],
            ),

            // 错误信息
            if (_parseError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _parseError!,
                        style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 解析结果
            if (_config != null) ...[
              const SizedBox(height: 16),
              _buildConfigPreview(theme, cs),
              const SizedBox(height: 12),

              // 验证按钮
              if (_verifyResult == null)
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    icon: _verifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.verified),
                    label: Text(_verifying ? '正在验证 ${_config!.packages.length} 个包…' : '验证 Chocolatey 包是否存在'),
                    onPressed: _verifying ? null : _verify,
                  ),
                ),

              // 验证结果
              if (_verifyResult != null) ...[
                const SizedBox(height: 12),
                _buildVerifyResult(theme, cs),
                const SizedBox(height: 16),

                // 安装按钮
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      '一键安装 ${_getAvailableCount()} 个可用包',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    onPressed: _getAvailableCount() > 0 ? _startInstall : null,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                '导入别人分享的软件配置',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '粘贴 JSON 配置后，先解析再验证，确认每个包在 Chocolatey 上存在后即可一键安装。',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPreview(ThemeData theme, ColorScheme cs) {
    final config = _config!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${config.packages.length} 个包',
                    style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            if (config.description != null && config.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                config.description!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (config.author != null && config.author!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '作者：${config.author}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyResult(ThemeData theme, ColorScheme cs) {
    final result = _verifyResult!;
    final available = result.entries.where((e) => e.value).map((e) => e.key).toList();
    final notFound = result.entries.where((e) => !e.value).map((e) => e.key).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  notFound.isEmpty ? Icons.check_circle : Icons.warning_amber,
                  color: notFound.isEmpty ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '验证结果',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 可用包
            if (available.isNotEmpty) ...[
              Text(
                '✅ 可用 (${available.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: available.map((p) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],

            // 不可用包
            if (notFound.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '❌ 未找到 (${notFound.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: notFound.map((p) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    backgroundColor: cs.errorContainer.withValues(alpha: 0.5),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    deleteIcon: const Icon(Icons.help_outline, size: 14),
                    onDeleted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$p 在 Chocolatey 仓库中未找到，请检查包名是否正确'),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                '以上包在 Chocolatey 仓库中未找到。可点击 × 查看提示。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getAvailableCount() {
    if (_verifyResult == null) return _config?.packages.length ?? 0;
    return _verifyResult!.entries.where((e) => e.value).length;
  }

  String _exampleJson() {
    return '{\n'
        '  "name": "前端开发环境",\n'
        '  "description": "React + TypeScript 开发",\n'
        '  "packages": [\n'
        '    "vscode",\n'
        '    "zed-editor",\n'
        '    "git",\n'
        '    "nodejs"\n'
        '  ]\n'
        '}';
  }
}

// ---------------------------------------------------------------------------
// 安装进度 Dialog
// ---------------------------------------------------------------------------

class _ImportInstallDialog extends StatefulWidget {
  final ImportedConfig config;
  final BundleProvider provider;

  const _ImportInstallDialog({
    required this.config,
    required this.provider,
  });

  @override
  State<_ImportInstallDialog> createState() => _ImportInstallDialogState();
}

class _ImportInstallDialogState extends State<_ImportInstallDialog> {
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
    widget.provider.clearInstallLog();
    final result = await widget.provider.installImportedConfig(widget.config);
    if (mounted) {
      setState(() {
        _done = true;
        _success = result;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    _scrollToBottom();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('📥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '安装 ${widget.config.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!_done)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.currentIndex + 1}/${provider.totalCount}  正在安装 ${provider.currentPackage}...',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 580,
        height: 360,
        child: Column(
          children: [
            if (!_done)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(value: provider.installProgress),
              ),
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
                      provider.installLog.isEmpty ? '等待开始…' : provider.installLog,
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
            if (_done) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _success ? Icons.check_circle : Icons.warning_amber,
                    color: _success ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _success ? '全部安装成功！' : '部分包安装失败，请查看上方日志。',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_done)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          )
        else
          OutlinedButton(
            onPressed: () {
              provider.cancelInstall();
              Navigator.of(context).pop();
            },
            child: const Text('取消安装'),
          ),
      ],
    );
  }
}
