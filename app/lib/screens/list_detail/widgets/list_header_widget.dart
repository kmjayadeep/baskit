import 'package:flutter/material.dart';
import '../../../models/shopping_list_model.dart';
import '../../../extensions/shopping_list_extensions.dart';

/// Widget that displays the list header with info, progress, and sharing status
class ListHeaderWidget extends StatelessWidget {
  final ShoppingList list;

  const ListHeaderWidget({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final listColor = list.displayColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: listColor.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List name with color indicator
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: listColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  list.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // List description (if available)
          if (list.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              list.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],

          // Progress text
          const SizedBox(height: 8),
          Text(
            '${list.completedItemsCount} of ${list.totalItemsCount} items completed',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),

          // Progress bar
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: list.completionProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(listColor),
          ),

          // Sharing status
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(list.sharingIcon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  list.sharingText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
