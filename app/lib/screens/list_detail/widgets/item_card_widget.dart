import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';

enum _ItemAction { edit, delete }

/// Widget that displays an individual shopping item row with interactions.
class ItemCardWidget extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final ValueChanged<ShoppingItem>? onToggleCompleted;
  final ValueChanged<ShoppingItem>? onDelete;
  final ValueChanged<ShoppingItem>? onEdit;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onToggleCompleted,
    this.onDelete,
    this.onEdit,
  });

  bool get _hasActions => !isProcessing && (onEdit != null || onDelete != null);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _itemDecoration(item.isCompleted),
      child: InkWell(
        onTap: isProcessing || onToggleCompleted == null
            ? null
            : () => onToggleCompleted!(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _CompletionControl(
                item: item,
                isProcessing: isProcessing,
                onToggleCompleted: onToggleCompleted,
              ),
              const SizedBox(width: 8),
              Expanded(child: _ItemDetails(item: item)),
              if (_hasActions) ...[
                const SizedBox(width: 4),
                _ItemActions(item: item, onDelete: onDelete, onEdit: onEdit),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _itemDecoration(bool isCompleted) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: isCompleted ? AppColors.completedSurface : Colors.white,
    border: Border.all(
      color: isCompleted
          ? AppColors.primaryGreen.withValues(alpha: 0.16)
          : AppColors.border,
    ),
  );
}

class _CompletionControl extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final ValueChanged<ShoppingItem>? onToggleCompleted;

  const _CompletionControl({
    required this.item,
    required this.isProcessing,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: Checkbox(
        value: item.isCompleted,
        onChanged: onToggleCompleted == null
            ? null
            : (_) => onToggleCompleted!(item),
        activeColor: AppColors.primaryGreen,
        shape: const CircleBorder(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ItemDetails extends StatelessWidget {
  final ShoppingItem item;

  const _ItemDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            decoration: item.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isCompleted
                ? AppColors.textMuted
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          child: Text(item.name),
        ),
        if (quantity != null && quantity.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            quantity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _ItemActions extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<ShoppingItem>? onDelete;
  final ValueChanged<ShoppingItem>? onEdit;

  const _ItemActions({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<_ItemAction>(
        tooltip: 'Item actions',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: _handleAction,
        itemBuilder: (_) => [
          if (onEdit != null)
            const PopupMenuItem(
              value: _ItemAction.edit,
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
          if (onDelete != null)
            const PopupMenuItem(
              value: _ItemAction.delete,
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleAction(_ItemAction action) {
    switch (action) {
      case _ItemAction.edit:
        onEdit?.call(item);
      case _ItemAction.delete:
        onDelete?.call(item);
    }
  }
}
