import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Single-row scrollable chips for quick-adding frequent items.
///
/// Shows a horizontal scrollable row with a close button at the end.
/// Only renders when [itemNames] is non-empty. When [enabled] is false,
/// chips appear greyed out and non-interactive.
class QuickAddChips extends StatelessWidget {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 6),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...itemNames.map((name) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  avatar: Icon(
                    Icons.add,
                    size: 14,
                    color:
                        enabled
                            ? AppColors.primaryGreen
                            : AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  label: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          enabled
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                    ),
                  ),
                  onPressed:
                      enabled
                          ? () => onItemTap(name)
                          : null,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }),
            if (onDismiss != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Hide suggestions',
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
