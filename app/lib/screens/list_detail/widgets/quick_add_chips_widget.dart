import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Single-row scrollable chips for quick-adding frequent items.
///
/// Shows a horizontal scrollable row with a close button at the end.
/// Only renders when [itemNames] is non-empty. When [enabled] is false,
/// chips appear greyed out and non-interactive.
class QuickAddChips extends StatelessWidget {
  static const double _rowHeight = 44;
  static const double _dismissButtonSize = 40;

  final List<String> itemNames;
  final bool enabled;
  final ValueChanged<String> onItemTap;
  final VoidCallback? onDismiss;

  const QuickAddChips({
    super.key,
    required this.itemNames,
    required this.enabled,
    required this.onItemTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (itemNames.isEmpty) return const SizedBox.shrink();

    final visibleItems = itemNames.take(6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
      child: SizedBox(
        height: _rowHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...visibleItems.map((name) {
              final addLabel = 'Add $name';

              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Semantics(
                  label: addLabel,
                  button: true,
                  enabled: enabled,
                  onTap: enabled ? () => onItemTap(name) : null,
                  child: ExcludeSemantics(
                    child: ActionChip(
                      tooltip: addLabel,
                      avatar: Icon(
                        Icons.add,
                        size: 13,
                        color:
                            enabled
                                ? AppColors.primaryGreen
                                : AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                enabled
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                          ),
                        ),
                      ),
                      onPressed: enabled ? () => onItemTap(name) : null,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (onDismiss != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: SizedBox(
                  width: _dismissButtonSize,
                  height: _dismissButtonSize,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onDismiss,
                    padding: const EdgeInsets.all(8),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Hide suggestions',
                    constraints: const BoxConstraints.tightFor(
                      width: _dismissButtonSize,
                      height: _dismissButtonSize,
                    ),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
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
