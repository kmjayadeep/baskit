import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';

/// Widget that displays an individual shopping item row with interactions.
class ItemCardWidget extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final Function(ShoppingItem)? onToggleCompleted;
  final Function(ShoppingItem)? onDelete;
  final Function(ShoppingItem)? onEdit;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onToggleCompleted,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = (onEdit != null || onDelete != null) && !isProcessing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: item.isCompleted ? AppColors.completedSurface : Colors.white,
        border: Border.all(
          color:
              item.isCompleted
                  ? AppColors.primaryGreen.withValues(alpha: 0.16)
                  : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap:
            isProcessing || onToggleCompleted == null
                ? null
                : () => onToggleCompleted!(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              isProcessing
                  ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Checkbox(
                    value: item.isCompleted,
                    onChanged:
                        onToggleCompleted != null
                            ? (_) => onToggleCompleted!(item)
                            : null,
                    activeColor: AppColors.primaryGreen,
                    shape: const CircleBorder(),
                    visualDensity: VisualDensity.compact,
                  ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        decoration:
                            item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        color:
                            item.isCompleted
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      child: Text(item.name),
                    ),
                    if (item.quantity != null && item.quantity!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.quantity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasActions)
                PopupMenuButton<String>(
                  tooltip: 'Item actions',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        if (onEdit != null) onEdit!(item);
                        break;
                      case 'delete':
                        if (onDelete != null) onDelete!(item);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final menuItems = <PopupMenuEntry<String>>[];

                    if (onEdit != null) {
                      menuItems.add(
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      );
                    }

                    if (onDelete != null) {
                      menuItems.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return menuItems;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
