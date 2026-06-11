import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Horizontal row of tappable quick-add chips showing frequent item names.
///
/// Each chip adds its item instantly when tapped. Only renders when
/// [itemNames] is non-empty. When [enabled] is false, chips appear
/// greyed out and non-interactive.
class QuickAddChips extends StatelessWidget {
  final List<String> itemNames;
  final bool enabled;
  final ValueChanged<String> onItemTap;

  const QuickAddChips({
    super.key,
    required this.itemNames,
    required this.enabled,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (itemNames.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children:
            itemNames.map((name) {
              return ActionChip(
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
                    fontSize: 13,
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
              );
            }).toList(),
      ),
    );
  }
}
