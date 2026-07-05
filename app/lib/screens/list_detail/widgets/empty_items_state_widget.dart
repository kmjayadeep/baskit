import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Widget that displays an empty state when no items are in the list.
class EmptyItemsStateWidget extends StatelessWidget {
  final VoidCallback? onAddFirstItem;

  const EmptyItemsStateWidget({super.key, this.onAddFirstItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.basketOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_shopping_cart_outlined,
                size: 28,
                color: AppColors.basketOrange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              onAddFirstItem == null
                  ? 'Items added to this list will appear here.'
                  : 'Add the first thing you need and build the list as you shop.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onAddFirstItem != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAddFirstItem,
                icon: const Icon(Icons.add),
                label: const Text('Add first item'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
