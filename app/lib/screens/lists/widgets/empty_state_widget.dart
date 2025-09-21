import 'package:flutter/material.dart';

/// An empty state widget that displays when no lists are available
///
/// Shows an encouraging message with a basket icon and a create list button
/// to help users get started with their first list.
class EmptyStateWidget extends StatelessWidget {
  /// Callback function executed when the "Create List" button is pressed
  final VoidCallback onCreateList;

  const EmptyStateWidget({super.key, required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first shopping list to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateList,
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
          ),
        ],
      ),
    );
  }
}
