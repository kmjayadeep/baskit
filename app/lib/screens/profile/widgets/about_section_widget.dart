import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_version.dart';

/// Widget that shows the about section with dialog
class AboutSectionWidget extends StatelessWidget {
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://kmjayadeep.github.io/baskit/privacy-policy.html',
  );
  static final Uri _accountDeletionUri = Uri.parse(
    'https://kmjayadeep.github.io/baskit/delete-account.html',
  );

  @visibleForTesting
  static Future<bool> Function(Uri uri, LaunchMode mode)?
  launchUrlOverrideForTest;

  const AboutSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.info_outline, color: AppColors.primaryGreen),
        ),
        title: const Text('About Baskit'),
        subtitle: const Text(
          'Collaborative shopping lists • v${AppVersion.version}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAboutDialog(context),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'About Baskit',
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
                  'A collaborative shopping list app that makes shopping with friends and family easy.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Guest-first experience'),
                const Text('• Real-time collaboration'),
                const Text('• Cross-device sync'),
                const Text('• Offline support'),
                const SizedBox(height: 16),
                Text(
                  'Version ${AppVersion.version}',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _openPrivacyPolicy(context),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Privacy Policy'),
                ),
                TextButton.icon(
                  onPressed: () => _openAccountDeletion(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Request account deletion'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) {
    return _openExternalUrl(
      context,
      _privacyPolicyUri,
      'Could not open privacy policy',
    );
  }

  Future<void> _openAccountDeletion(BuildContext context) {
    return _openExternalUrl(
      context,
      _accountDeletionUri,
      'Could not open account deletion page',
    );
  }

  Future<void> _openExternalUrl(
    BuildContext context,
    Uri uri,
    String failureMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched =
        launchUrlOverrideForTest != null
            ? await launchUrlOverrideForTest!(
              uri,
              LaunchMode.externalApplication,
            )
            : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }
}
