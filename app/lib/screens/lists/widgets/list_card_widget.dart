import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/shopping_list_model.dart';

/// A card widget that displays shopping list information in a compact format.
class ListCardWidget extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;

  const ListCardWidget({super.key, required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = list.displayColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 86,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            list.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${list.items.length} items',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    if (list.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        list.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: list.completionProgress),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: value,
                            backgroundColor: AppColors.border.withValues(
                              alpha: 0.65,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _StatusChip(
                              icon: list.sharingIcon,
                              text: _sharingSummaryText(list),
                              color:
                                  list.isShared
                                      ? AppColors.primaryGreen
                                      : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${list.completedItemsCount}/${list.totalItemsCount} done',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
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

  String _sharingSummaryText(ShoppingList list) {
    if (!list.isShared) {
      return 'Private';
    }

    return list.memberCount.toString();
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
