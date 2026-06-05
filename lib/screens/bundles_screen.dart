import 'package:flutter/material.dart';
import '../providers/bundle_provider.dart';
import '../models/bundle_model.dart';
import 'bundle_detail_screen.dart';
import 'import_screen.dart';

/// 推荐套餐列表页
///
/// 展示所有 9 种用户类型的套餐卡片，点击进入详情。
class BundlesScreen extends StatefulWidget {
  const BundlesScreen({super.key});

  @override
  State<BundlesScreen> createState() => _BundlesScreenState();
}

class _BundlesScreenState extends State<BundlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = BundleProviderScope.of(context);
      if (provider.bundles.isEmpty && !provider.loading) {
        provider.loadBundles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = BundleProviderScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 8),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(provider.error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              onPressed: () => provider.loadBundles(),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context, cs, theme),
        const SizedBox(height: 16),
        ...provider.bundles.map((bundle) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BundleCard(bundle: bundle),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme cs, ThemeData theme) {
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
          const Text('📦', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('推荐套餐',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('按用户类型定制，一键安装全套软件',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSecondaryContainer)),
              ],
            ),
          ),
          // 导入按钮
          OutlinedButton.icon(
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('导入'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onPrimaryContainer,
              side: BorderSide(color: cs.onPrimaryContainer.withValues(alpha: 0.5)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 套餐卡片
class _BundleCard extends StatelessWidget {
  final RecommendedBundle bundle;
  const _BundleCard({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = BundleProviderScope.of(context);

    // 检查是否有用户自定义选择（非默认 {0} 或多项选中）
    int customCount = 0;
    for (int i = 0; i < bundle.slots.length; i++) {
      final sel = provider.getSelectedIndices(bundle.id, i);
      if (!(sel.length == 1 && sel.contains(0))) customCount++;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BundleDetailScreen(bundle: bundle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(bundle.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bundle.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bundle.description,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              // Tags row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.apps, size: 14),
                    label: Text('${bundle.slots.length} 款软件'),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  if (customCount > 0)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.tune, size: 14),
                      label: Text('$customCount 个已自定义'),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      backgroundColor:
                          cs.tertiaryContainer.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
