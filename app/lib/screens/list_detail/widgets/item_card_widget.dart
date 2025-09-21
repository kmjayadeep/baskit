import 'package:flutter/material.dart';
import '../../../models/shopping_item_model.dart';

/// Widget that displays an individual shopping item card with interactions
class ItemCardWidget extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final Function(ShoppingItem) onToggleCompleted;
  final Function(ShoppingItem) onDelete;
  final Function(ShoppingItem) onEdit;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.isProcessing,
    required this.onToggleCompleted,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            item.isCompleted
                ? Colors.grey.shade100
                : Theme.of(context).cardColor,
        border: Border.all(
          color: item.isCompleted ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        // Loading indicator or checkbox
        leading:
            isProcessing
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Checkbox(
                  value: item.isCompleted,
                  onChanged: (_) => onToggleCompleted(item),
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

        // Item details
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            decoration:
                item.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
            color:
                item.isCompleted
                    ? Colors.grey[600]
                    : Theme.of(context).textTheme.titleMedium?.color,
          ),
          child: Text(item.name),
        ),

        // Subtitle with quantity and notes
        subtitle: _buildSubtitle(context),

        // Action menu
        trailing: PopupMenuButton<String>(
          enabled: !isProcessing,
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit(item);
                break;
              case 'delete':
                onDelete(item);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),

        // Tap to toggle completion
        onTap: isProcessing ? null : () => onToggleCompleted(item),

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    // Only show quantity if available
    if (item.quantity == null || item.quantity!.isEmpty) {
      return null;
    }

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color:
            item.isCompleted
                ? Colors.grey[500]
                : Theme.of(context).textTheme.bodySmall?.color,
      ),
      child: Text(
        'Quantity: ${item.quantity}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
