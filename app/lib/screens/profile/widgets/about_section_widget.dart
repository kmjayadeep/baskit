import 'package:flutter/material.dart';

/// Widget that shows the about section with dialog
class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('About Baskit'),
        subtitle: const Text('A collaborative shopping list app'),
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
            title: const Row(
              children: [
                Icon(Icons.shopping_basket, color: Colors.blue),
                SizedBox(width: 8),
                Text('About Baskit'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A collaborative shopping list app that makes shopping with friends and family easy.',
                ),
                SizedBox(height: 16),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Guest-first experience'),
                Text('• Real-time collaboration'),
                Text('• Cross-device sync'),
                Text('• Offline support'),
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
}
