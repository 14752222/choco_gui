import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bundle_model.dart';
import '../providers/bundle_provider.dart';

/// 套餐详情页
///
/// 展示套餐中所有软件槽位，支持切换免费/付费选项，底部一键安装。
class BundleDetailScreen extends StatefulWidget {
  final RecommendedBundle bundle;
  const BundleDetailScreen({super.key, required this.bundle});

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = BundleProviderScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final count = provider.getSelectedCount(widget.bundle.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.bundle.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(widget.bundle.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出配置 JSON',
            onPressed: () => _exportConfig(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Description header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: cs.surfaceContainerHighest,
            child: Text(
              widget.bundle.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          // Slot list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.bundle.slots.length,
              itemBuilder: (_, index) {
                return _SlotTile(
                  bundle: widget.bundle,
                  slotIndex: index,
                );
              },
            ),
          ),
          // Bottom bar: 一键安装
          _buildBottomBar(context, provider, count),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, BundleProvider provider, int count) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: Text('一键安装 $count 个软件'),
          style: FilledButton.styleFrom(
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: provider.installing
              ? null
              : () => _startBundleInstall(context),
        ),
      ),
    );
  }

  void _exportConfig(BuildContext context) {
    final provider = BundleProviderScope.of(context);
    final config = provider.exportBundleConfig(widget.bundle.id);
    final jsonStr = config.toJsonString();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制 ${widget.bundle.name} 的配置 JSON 到剪贴板'),
        action: SnackBarAction(
          label: '分享',
          onPressed: () {
            // 未来可以支持通过其他方式分享
          },
        ),
      ),
    );
  }

  Future<void> _startBundleInstall(BuildContext context) async {
    final provider = BundleProviderScope.of(context);
    final bundleId = widget.bundle.id;
    final count = provider.getSelectedCount(bundleId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(widget.bundle.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('正在安装 ${widget.bundle.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在批量安装 $count 个软件，请稍候…'),
          ],
        ),
      ),
    );

    await provider.installBundle(bundleId);

    if (context.mounted) {
      Navigator.of(context).pop(); // 关闭加载 Dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('批量安装完成'), duration: Duration(seconds: 2)),
      );
    }
  }
}

/// 单个软件槽位
class _SlotTile extends StatelessWidget {
  final RecommendedBundle bundle;
  final int slotIndex;

  const _SlotTile({required this.bundle, required this.slotIndex});

  @override
  Widget build(BuildContext context) {
    final provider = BundleProviderScope.of(context);
    final slot = bundle.slots[slotIndex];
    final isEnabled = provider.isSlotEnabled(bundle.id, slotIndex);
    final selectedOptions = provider.getSelectedOptions(bundle.id, slotIndex);
    final selectedNames = selectedOptions.map((o) => o.name).join(', ');
    final hasAnyPaid = selectedOptions.any((o) => o.isPaid);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: slot.hasAlternatives
              ? () => _showOptionSheet(context, provider, slot)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Checkbox to enable/disable this slot
                Checkbox(
                  value: isEnabled,
                  onChanged: (_) =>
                      provider.toggleSlot(bundle.id, slotIndex),
                  visualDensity: VisualDensity.compact,
                ),
                // Name + description
                Expanded(
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.35,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              slot.slotName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (hasAnyPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cs.tertiary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '付费',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedNames,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Select button
                if (slot.hasAlternatives)
                  TextButton.icon(
                    icon: const Icon(Icons.checklist, size: 16),
                    label: const Text('选择'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: isEnabled
                        ? () => _showOptionSheet(context, provider, slot)
                        : null,
                  )
                else
                  Icon(Icons.lock_outline,
                      size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionSheet(
      BuildContext context, BundleProvider provider, SoftwareSlot slot) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _MultiSelectSheet(
          bundle: bundle,
          slotIndex: slotIndex,
          slot: slot,
          provider: provider,
        );
      },
    );
  }
}

/// 多选底部 Sheet — 一个 StatefulWidget，管理本地临时选中状态
class _MultiSelectSheet extends StatefulWidget {
  final RecommendedBundle bundle;
  final int slotIndex;
  final SoftwareSlot slot;
  final BundleProvider provider;

  const _MultiSelectSheet({
    required this.bundle,
    required this.slotIndex,
    required this.slot,
    required this.provider,
  });

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late Set<int> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = Set<int>.from(
      widget.provider.getSelectedIndices(widget.bundle.id, widget.slotIndex),
    );
  }

  void _toggle(int optionIndex) {
    setState(() {
      if (_tempSelection.contains(optionIndex)) {
        if (_tempSelection.length > 1) {
          _tempSelection.remove(optionIndex);
        }
      } else {
        _tempSelection.add(optionIndex);
      }
    });
  }

  void _confirm() {
    widget.provider.setSlotSelection(
      widget.bundle.id,
      widget.slotIndex,
      _tempSelection,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final slot = widget.slot;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择 ${slot.slotName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '已选 ${_tempSelection.length}/${slot.options.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                slot.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: slot.options.length,
                itemBuilder: (context, i) {
                  final option = slot.options[i];
                  final isChecked = _tempSelection.contains(i);
                  final isLast = _tempSelection.length == 1 && isChecked;
                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: isLast ? null : (_) => _toggle(i),
                    activeColor: cs.primary,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.name,
                            style: TextStyle(
                              fontWeight:
                                  isChecked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (option.isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.tertiaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium,
                                    size: 14, color: cs.onTertiaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  option.priceHint ?? '付费',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '免费',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: option.description != null
                        ? Text(
                            option.description!,
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 确定按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _confirm,
                  child: Text('确定 (${_tempSelection.length} 个)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
