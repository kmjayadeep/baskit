import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_list_model.dart';

/// A compact summary for the user's list overview.
class WelcomeBannerWidget extends StatelessWidget {
  final List<ShoppingList> lists;

  const WelcomeBannerWidget({super.key, required this.lists});

  @override
  Widget build(BuildContext context) {
    final totalItems = lists.fold<int>(
      0,
      (sum, list) => sum + list.totalItemsCount,
    );
    final completedItems = lists.fold<int>(
      0,
      (sum, list) => sum + list.completedItemsCount,
    );
    final remainingItems = totalItems - completedItems;
    final activeLists = lists.where((list) => list.totalItemsCount > 0).length;
    final sharedLists = lists.where((list) => list.isShared).length;
    final hasItems = totalItems > 0;
    final progress = hasItems ? completedItems / totalItems : 0.0;
    final summaryText =
        remainingItems == 0 && hasItems
            ? 'All items checked off'
            : '$remainingItems ${remainingItems == 1 ? 'item' : 'items'} left';
    final detailText =
        hasItems
            ? '$completedItems of $totalItems done'
            : '${lists.length} ${lists.length == 1 ? 'list' : 'lists'} ready';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progress),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: value,
                        backgroundColor: AppColors.border.withValues(
                          alpha: 0.65,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 3),
                Text(
                  detailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _MetricsPill(activeLists: activeLists, sharedLists: sharedLists),
        ],
      ),
    );
  }
}

class _MetricsPill extends StatelessWidget {
  final int activeLists;
  final int sharedLists;

  const _MetricsPill({required this.activeLists, required this.sharedLists});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricLine(
            icon: Icons.list_alt_outlined,
            value: activeLists.toString(),
            label: 'active',
          ),
          const SizedBox(height: 3),
          _MetricLine(
            icon: Icons.group_outlined,
            value: sharedLists.toString(),
            label: 'shared',
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricLine({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
