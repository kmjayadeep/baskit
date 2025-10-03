import 'package:flutter/material.dart';
import '../models/whats_new_model.dart';
import '../services/version_service.dart';

/// Dialog to show "What's New" content to users after app updates
class WhatsNewDialog extends StatelessWidget {
  final WhatsNewContent content;

  const WhatsNewDialog({super.key, required this.content});

  /// Show the What's New dialog if needed
  ///
  /// This is the main entry point - call this on app startup
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      // Check if we should show the dialog
      if (!await VersionService.shouldShowWhatsNew()) {
        return;
      }

      // Get current version and load content
      final currentVersion = await VersionService.getCurrentVersion();
      final content = await WhatsNewContent.loadForVersion(currentVersion);

      if (content == null || !content.hasItems) {
        // No content for this version, mark as seen and return
        await VersionService.markVersionAsSeen();
        return;
      }

      // Show the dialog
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => WhatsNewDialog(content: content),
        );
      }

      // Mark version as seen after showing
      await VersionService.markVersionAsSeen();
    } catch (e) {
      debugPrint('❌ Error showing What\'s New dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.celebration, color: theme.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version ${content.version}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Items list
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 400, // Prevent dialog from being too tall
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: content.items.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = content.items[index];
                  return _buildWhatsNewItem(context, item);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Skip',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildWhatsNewItem(BuildContext context, WhatsNewItem item) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.getColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.getColor(context).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.getColor(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.getColor(context), size: 24),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with emoji
                Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.getColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Service to manage What's New dialog display
class WhatsNewService {
  /// Show What's New dialog with proper error handling and logging
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      debugPrint('🔍 Checking if What\'s New dialog should be shown...');
      await WhatsNewDialog.showIfNeeded(context);
    } catch (e) {
      debugPrint('❌ Error in WhatsNewService.checkAndShow: $e');
      // Don't rethrow - we don't want to crash the app over this
    }
  }

  /// Force show What's New dialog for current version (for testing)
  static Future<void> forceShow(BuildContext context) async {
    try {
      final currentVersion = await VersionService.getCurrentVersion();
      final content = await WhatsNewContent.loadForVersion(currentVersion);

      if (content != null && content.hasItems && context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => WhatsNewDialog(content: content),
        );
      } else {
        debugPrint(
          'ℹ️  No What\'s New content available for version $currentVersion',
        );
      }
    } catch (e) {
      debugPrint('❌ Error force showing What\'s New dialog: $e');
    }
  }
}
