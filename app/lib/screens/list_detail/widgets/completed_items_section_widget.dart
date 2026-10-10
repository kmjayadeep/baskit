import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_item_model.dart';
import 'collapsible_section_widget.dart';
import 'item_card_widget.dart';

/// A collapsible section that groups completed items under a tappable header.
///
/// Shows a count badge ("Completed (3)") and an expand/collapse chevron.
/// Tapping the header toggles visibility of the completed items.
///
/// All layout and interaction lives in the shared [CollapsibleListSection];
/// this wrapper keeps the existing public API for callers and tests.
class CompletedItemsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final count = completedItems.length;
    return CollapsibleListSection(
      title: 'Completed ($count)',
      icon: Icons.check_circle_outline,
      iconColor: AppColors.primaryGreen,
      itemNames: completedItems.map((item) => item.name).toList(),
      collapsedSummaryBuilder: buildCollapsedSummary,
      items: completedItems
          .map((item) => ItemCardWidget(
                key: ValueKey(item.id),
                item: item,
                isProcessing: processingItems.contains(item.id),
                onToggleCompleted: onToggleCompleted,
                onDelete: onDelete,
                onEdit: onEdit,
              ))
          .toList(),
    );
  }
}
