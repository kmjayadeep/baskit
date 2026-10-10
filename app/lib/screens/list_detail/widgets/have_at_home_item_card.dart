import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';

/// A card for a single "Have at Home" item (an item the user already owns).
///
/// Unlike [ItemCardWidget] (the shopping checkbox row), this card uses a
/// "Finished" action to mark the item as used up. Tapping the card also
/// finishes it, matching the "tap = mark finished" convention in the spec.
class HaveAtHomeItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool isProcessing;
  final VoidCallback? onFinished;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const HaveAtHomeItemCard({
    super.key,
    required this.item,
    required this.isProcessing,
    this.onFinished,
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
        color: AppColors.completedSurface,
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.16),
        ),
      ),
      child: InkWell(
        onTap: isProcessing || onFinished == null ? null : onFinished,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.home_filled,
                size: 20,
                color: AppColors.primaryGreen,
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // "Finished" primary action.
              if (!isProcessing)
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: onFinished,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Finished'),
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
                _HaveAtHomeItemActions(
                  onDelete: onDelete,
                  onEdit: onEdit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HaveAtHomeItemActions extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _HaveAtHomeItemActions({this.onDelete, this.onEdit});

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
