import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// An empty state widget that displays when no lists are available.
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateList;

  const EmptyStateWidget({super.key, required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_basket_outlined,
                  size: 28,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No lists yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a grocery, home, or party list and keep every item in one place.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
