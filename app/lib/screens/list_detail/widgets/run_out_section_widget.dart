import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'collapsible_section_widget.dart';
import 'run_out_item_card.dart';

/// A collapsible section that groups "Run Out" items under a tappable header.
///
/// Mirrors [CompletedItemsSection]: a count badge ("Run out (2)") and an
/// expand/collapse chevron. Tapping the header toggles visibility. Each item
/// offers "Move back" and Delete.
///
/// All layout and interaction lives in the shared [CollapsibleListSection];
/// this wrapper keeps the existing public API for callers and tests.
class RunOutSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final count = runOutItems.length;
    return CollapsibleListSection(
      title: 'Run out ($count)',
      icon: Icons.remove_shopping_cart_outlined,
      iconColor: AppColors.basketOrange,
      itemNames: runOutItems.map((item) => item.name).toList(),
      collapsedSummaryBuilder: buildCollapsedSummary,
      items: runOutItems
          .map((item) => RunOutItemCard(
                key: ValueKey(item.id),
                item: item,
                isProcessing: processingItems.contains(item.id),
                onMoveBack:
                    onMoveBack == null ? null : () => onMoveBack!(item),
                onDelete: onDelete == null ? null : () => onDelete!(item),
                onEdit: onEdit == null ? null : () => onEdit!(item),
              ))
          .toList(),
    );
  }
}
