import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/package_model.dart';

/// Card widget displaying a single Chocolatey package entry.
///
/// Shows name, version, optional description, install path, and action buttons
/// (install / uninstall) depending on context.
class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    required this.isInstalled,
    this.installPath,
    this.onInstall,
    this.onUninstall,
    this.onTap,
  });

  final PackageModel package;

  /// Whether this package is currently installed (affects which button shown).
  final bool isInstalled;

  /// The local install path (shown only for installed packages when non-null).
  final String? installPath;

  /// Called when the user taps the install button; nullable means hidden.
  final VoidCallback? onInstall;

  /// Called when the user taps the uninstall button; nullable means hidden.
  final VoidCallback? onUninstall;

  /// Called when the user taps the card body to view details.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package icon placeholder
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  package.name.isNotEmpty
                      ? package.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + version + description + install path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        package.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(package.version),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                  if (package.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      package.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (isInstalled && installPath != null &&
                      installPath!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InstallPathRow(path: installPath!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isInstalled && onInstall != null)
                    FilledButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('安装'),
                      onPressed: onInstall,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (isInstalled && onUninstall != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('卸载'),
                      onPressed: onUninstall,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A small row showing the install path with a copy-to-clipboard button.
class _InstallPathRow extends StatelessWidget {
  const _InstallPathRow({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.folder_outlined,
            size: 13, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            path,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Consolas',
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: path));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('路径已复制到剪贴板'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.copy_outlined,
                size: 13, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
