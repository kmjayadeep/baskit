import 'package:flutter/material.dart';

/// Widget that prompts anonymous users to sign in
class SignInPromptWidget extends StatelessWidget {
  const SignInPromptWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_queue, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Sign In to Unlock Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with Google to sync your lists across devices and collaborate with others.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
