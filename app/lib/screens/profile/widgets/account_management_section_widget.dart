import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';

/// Profile account management actions.
///
/// Account deletion is currently completed through the documented request page
/// so backend/manual cleanup boundaries remain explicit until a full self-serve
/// deletion backend is available.
class AccountManagementSectionWidget extends StatelessWidget {
  static final Uri accountDeletionUri = Uri.parse(
    'https://kmjayadeep.github.io/baskit/delete-account.html',
  );

  final bool isAnonymous;
  final Future<bool> Function(Uri uri)? launchAccountDeletionRequest;

  const AccountManagementSectionWidget({
    super.key,
    required this.isAnonymous,
    this.launchAccountDeletionRequest,
  });

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
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Account management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isAnonymous
                  ? 'You are using guest mode. Guest lists stay on this device unless you sign in.'
                  : 'Need your Baskit account deleted? Open the deletion request page to start the verified cleanup process.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openDeletionRequest(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Request account deletion'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeletionRequest(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final launcher = launchAccountDeletionRequest ?? _launchExternal;
    final launched = await launcher(accountDeletionUri);

    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open account deletion request page'),
        ),
      );
    }
  }

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
