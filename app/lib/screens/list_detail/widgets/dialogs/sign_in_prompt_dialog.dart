import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';

class SignInPromptDialog extends StatelessWidget {
  const SignInPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.basketOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.login,
              size: 20,
              color: AppColors.basketOrange,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Sign in required',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You need to sign in to share lists with others.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_sync_outlined,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Benefits of signing in',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• Share lists with friends and family'),
                const Text('• Sync lists across all your devices'),
                const Text('• Real-time collaboration'),
                const Text('• Never lose your lists'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
