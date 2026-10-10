import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';

enum _ItemAction { edit, delete }

/// A card for a single shopping item shown in a list.
///
/// Renders the item icon, name, optional quantity, a primary action button,
/// a processing spinner, and an edit/delete actions menu.
///
/// This is the shared implementation behind [HaveAtHomeItemCard] and
/// [RunOutItemCard]; both are thin wrappers so callers keep their existing
/// APIs while the layout/interaction logic lives in one place.
class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final IconData icon;
  final Color iconColor;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.isProcessing,
    required this.icon,
    required this.iconColor,
    required this.primaryLabel,
    this.onPrimary,
    this.onDelete,
    this.onEdit,
  });

  bool get _hasActions => !isProcessing && (onEdit != null || onDelete != null);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: isProcessing || onPrimary == null ? null : onPrimary,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.quantity != null && item.quantity!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.quantity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
            // Primary action (e.g. "Finished" / "Move back"). Shown unless the
            // item is being processed; disabled when no handler is provided.
            if (primaryLabel.isNotEmpty && !isProcessing)
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: onPrimary,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.basketOrange.withValues(
                      alpha: 0.14,
                    ),
                    foregroundColor: AppColors.basketOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(primaryLabel),
                ),
              ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_hasActions) ...[
              const SizedBox(width: 2),
              _ItemActions(onDelete: onDelete, onEdit: onEdit),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ItemActions({this.onDelete, this.onEdit});

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
        onEdit?.call();
      case _ItemAction.delete:
        onDelete?.call();
    }
  }
}
