import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/shopping_list_model.dart';

/// Compact widget that displays list info and progress.
class ListHeaderWidget extends StatelessWidget {
  final ShoppingList list;

  const ListHeaderWidget({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final listColor = list.displayColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: listColor.withValues(alpha: 0.11),
        border: Border(
          bottom: BorderSide(color: listColor.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: listColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (list.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        list.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${list.completedItemsCount} of ${list.totalItemsCount} done',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(list.completionProgress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: list.completionProgress),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  valueColor: AlwaysStoppedAnimation<Color>(listColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
