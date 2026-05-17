import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Widget that displays an empty state when no items are in the list.
class EmptyItemsStateWidget extends StatelessWidget {
  const EmptyItemsStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.basketOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_shopping_cart_outlined,
                size: 34,
                color: AppColors.basketOrange,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first thing you need and build the list as you shop.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
