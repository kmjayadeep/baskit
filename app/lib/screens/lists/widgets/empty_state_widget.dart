import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// An empty state widget that displays when no lists are available.
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateList;
  final VoidCallback? onSignIn;
  final bool showSignInPrompt;
  final bool isSigningIn;

  const EmptyStateWidget({
    super.key,
    required this.onCreateList,
    this.onSignIn,
    this.showSignInPrompt = false,
    this.isSigningIn = false,
  });

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
              if (showSignInPrompt && onSignIn != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text(
                  'Already have an account?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to see your saved and shared lists.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSigningIn ? null : onSignIn,
                  icon: isSigningIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Sign in to see my lists'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
