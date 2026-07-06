import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Widget that prompts anonymous users to sign in
class SignInPromptWidget extends StatelessWidget {
  const SignInPromptWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.basketOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_queue,
                    color: AppColors.basketOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sign in to unlock sync',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Your lists are stored on this device. Sign in with Google to sync them across devices and collaborate with others.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
