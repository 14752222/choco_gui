import 'package:flutter/material.dart';

/// Pagination bar with numbered page buttons.
///
/// Shows up to [_maxVisiblePages] page number buttons, with "..." ellipsis
/// when there are many pages. [currentPage] is zero-based.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final void Function(int page) onPageChanged;

  static const int _maxVisiblePages = 7;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page
          _NavButton(
            icon: Icons.first_page,
            tooltip: '第一页',
            enabled: currentPage > 0,
            onTap: () => onPageChanged(0),
          ),
          // Prev page
          _NavButton(
            icon: Icons.chevron_left,
            tooltip: '上一页',
            enabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          // Number buttons
          ..._buildPageNumbers(context),
          const SizedBox(width: 4),
          // Next page
          _NavButton(
            icon: Icons.chevron_right,
            tooltip: '下一页',
            enabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
          ),
          // Last page
          _NavButton(
            icon: Icons.last_page,
            tooltip: '最后一页',
            enabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(totalPages - 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pages = <Widget>[];

    // Compute which page indices to show
    final indices = _visiblePageIndices();

    int? prev;
    for (final idx in indices) {
      if (prev != null && idx - prev > 1) {
        // Insert ellipsis
        pages.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('…',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant)),
        ));
      }
      final isCurrent = idx == currentPage;
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 34,
            height: 34,
            child: FilledButton(
              onPressed: isCurrent ? null : () => onPageChanged(idx),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor:
                    isCurrent ? cs.primary : cs.surfaceContainerHighest,
                foregroundColor:
                    isCurrent ? cs.onPrimary : cs.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(34, 34),
              ),
              child: Text(
                '${idx + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
      prev = idx;
    }
    return pages;
  }

  List<int> _visiblePageIndices() {
    if (totalPages <= _maxVisiblePages) {
      return List.generate(totalPages, (i) => i);
    }

    // Always show first, last, current and neighbours
    final Set<int> show = {0, totalPages - 1, currentPage};

    // Add neighbours of current
    for (int d = -2; d <= 2; d++) {
      final p = currentPage + d;
      if (p >= 0 && p < totalPages) show.add(p);
    }

    // If we still have room, fill from the side closer to current
    while (show.length < _maxVisiblePages) {
      final sorted = show.toList()..sort();
      bool added = false;
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i + 1] - sorted[i] > 1) {
          final mid = sorted[i] + 1;
          if (mid >= 0 && mid < totalPages) {
            show.add(mid);
            added = true;
            break;
          }
        }
      }
      if (!added) break;
    }

    return show.toList()..sort();
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
    );
  }
}
