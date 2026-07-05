import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'item_card_widget.dart';

/// A collapsible section that groups completed items under a tappable header.
///
/// Shows a count badge ("Completed (3)") and an expand/collapse chevron.
/// Tapping the header toggles visibility of the completed items.
class CompletedItemsSection extends StatefulWidget {
  final List<ShoppingItem> completedItems;
  final Set<String> processingItems;
  final Function(ShoppingItem)? onToggleCompleted;
  final Function(ShoppingItem)? onDelete;
  final Function(ShoppingItem)? onEdit;

  const CompletedItemsSection({
    super.key,
    required this.completedItems,
    required this.processingItems,
    this.onToggleCompleted,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<CompletedItemsSection> createState() => _CompletedItemsSectionState();
}

class _CompletedItemsSectionState extends State<CompletedItemsSection> {
  bool _isExpanded = false;

  String get _collapsedSummary {
    final previewNames = widget.completedItems
        .take(2)
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    if (previewNames.isEmpty) {
      return 'Tap to show';
    }

    final remainingCount = widget.completedItems.length - 2;
    final moreLabel = remainingCount > 0 ? ' +$remainingCount more' : '';
    return '$previewNames$moreLabel · Tap to show';
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.completedItems.length;
    final summaryText = _isExpanded ? 'Hide' : _collapsedSummary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsible header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primaryGreen.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed ($count)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryGreen.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Completed items list
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: widget.completedItems.map((item) {
                      return ItemCardWidget(
                        key: ValueKey(item.id),
                        item: item,
                        isProcessing: widget.processingItems.contains(item.id),
                        onToggleCompleted: widget.onToggleCompleted,
                        onDelete: widget.onDelete,
                        onEdit: widget.onEdit,
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
