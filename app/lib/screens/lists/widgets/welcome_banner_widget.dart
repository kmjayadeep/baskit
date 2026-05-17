import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_list_model.dart';

/// A compact dashboard summary for the user's list overview.
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
    final subtitle =
        lists.isEmpty
            ? 'Create a list to start tracking what you need.'
            : remainingItems == 0
            ? 'All listed items are checked off.'
            : '$remainingItems ${remainingItems == 1 ? 'item' : 'items'} left across $activeLists ${activeLists == 1 ? 'list' : 'lists'}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopping snapshot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lists.isNotEmpty && totalItems > 0) ...[
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                end: totalItems == 0 ? 0 : completedItems / totalItems,
              ),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: value,
                    backgroundColor: AppColors.border.withValues(alpha: 0.65),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.list_alt_outlined,
                  label: 'Active',
                  value: activeLists.toString(),
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.local_grocery_store_outlined,
                  label: 'To buy',
                  value: remainingItems.toString(),
                  color: AppColors.basketOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.group_outlined,
                  label: 'Shared',
                  value: sharedLists.toString(),
                  color: AppColors.freshGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
