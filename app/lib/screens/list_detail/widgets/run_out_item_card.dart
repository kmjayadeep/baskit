import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';

/// A card for a single "Run Out" item (a Have-at-Home item marked finished).
///
/// Offers "Move back" (restore to Have at Home) and a Delete action, matching
/// the spec: "Move back / Delete".
class RunOutItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final VoidCallback? onMoveBack;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RunOutItemCard({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onMoveBack,
    this.onDelete,
    this.onEdit,
  });

  bool get _hasActions =>
      !isProcessing && (onEdit != null || onDelete != null);

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 20,
              color: AppColors.basketOrange,
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
                  if (quantity != null && quantity.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        quantity,
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
            // "Move back" primary action.
            if (!isProcessing)
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: onMoveBack,
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
                  child: const Text('Move back'),
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
              _RunOutItemActions(onDelete: onDelete, onEdit: onEdit),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunOutItemActions extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _RunOutItemActions({this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<_Action>(
        tooltip: 'Item actions',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: _handleAction,
        itemBuilder: (_) => [
          if (onEdit != null)
            const PopupMenuItem(
              value: _Action.edit,
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
              value: _Action.delete,
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

  void _handleAction(_Action action) {
    switch (action) {
      case _Action.edit:
        onEdit?.call();
      case _Action.delete:
        onDelete?.call();
    }
  }
}

enum _Action { edit, delete }
