import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'run_out_item_card.dart';

/// A collapsible section that groups "Run Out" items under a tappable header.
///
/// Mirrors [CompletedItemsSection]: a count badge ("Run out (2)") and an
/// expand/collapse chevron. Tapping the header toggles visibility. Each item
/// offers "Move back" and Delete.
class RunOutSection extends StatefulWidget {
  final List<ShoppingItem> runOutItems;
  final Set<String> processingItems;
  final Function(ShoppingItem)? onMoveBack;
  final Function(ShoppingItem)? onDelete;
  final Function(ShoppingItem)? onEdit;

  const RunOutSection({
    super.key,
    required this.runOutItems,
    required this.processingItems,
    this.onMoveBack,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<RunOutSection> createState() => _RunOutSectionState();
}

class _RunOutSectionState extends State<RunOutSection> {
  bool _isExpanded = false;

  String get _collapsedSummary {
    final previewNames = widget.runOutItems
        .take(2)
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    if (previewNames.isEmpty) {
      return 'Tap to show';
    }

    final remainingCount = widget.runOutItems.length - 2;
    final moreLabel = remainingCount > 0 ? ' +$remainingCount more' : '';
    return '$previewNames$moreLabel · Tap to show';
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.runOutItems.length;
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
                  Icons.remove_shopping_cart_outlined,
                  size: 18,
                  color: AppColors.basketOrange.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  'Run out ($count)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.basketOrange,
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

        // Run out items list
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: widget.runOutItems.map((item) {
                      return RunOutItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        isProcessing: widget.processingItems.contains(item.id),
                        onMoveBack:
                            widget.onMoveBack == null
                                ? null
                                : () => widget.onMoveBack!(item),
                        onDelete:
                            widget.onDelete == null
                                ? null
                                : () => widget.onDelete!(item),
                        onEdit:
                            widget.onEdit == null
                                ? null
                                : () => widget.onEdit!(item),
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
