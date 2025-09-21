import 'package:flutter/material.dart';
import '../../../models/shopping_list_model.dart';

/// A card widget that displays shopping list information in a compact format
///
/// Shows list details including name, description, progress, and sharing status.
/// Provides tap interaction for navigation to the list detail screen.
class ListCardWidget extends StatelessWidget {
  /// The shopping list to display
  final ShoppingList list;

  /// Callback function executed when the card is tapped
  final VoidCallback onTap;

  const ListCardWidget({super.key, required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = list.displayColor;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with color indicator, name, and item count
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${list.items.length} items',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),

              // Optional description
              if (list.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  list.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],

              const SizedBox(height: 12),

              // Progress indicator and completion status
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: list.completionProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${list.completedItemsCount}/${list.totalItemsCount} done',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Sharing status
              Row(
                children: [
                  Icon(list.sharingIcon, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      list.sharingText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
