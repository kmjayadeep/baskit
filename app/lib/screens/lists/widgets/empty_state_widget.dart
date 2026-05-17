import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// An empty state widget that displays when no lists are available.
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateList;

  const EmptyStateWidget({super.key, required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  size: 34,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No lists yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a grocery, home, or party list and keep every item in one place.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onCreateList,
                icon: const Icon(Icons.add),
                label: const Text('Create List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
