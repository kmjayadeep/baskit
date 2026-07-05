import 'package:flutter/material.dart';

import '../../../models/shopping_item_model.dart';
import 'completed_items_section_widget.dart';
import 'item_card_widget.dart';

/// Scrollable item list for the list-detail screen.
///
/// Keeps pending items visible in the main sliver list and delegates completed
/// items to the existing collapsible completed-items section.
class ListItemsScrollView extends StatelessWidget {
  final List<ShoppingItem> pendingItems;
  final List<ShoppingItem> completedItems;
  final Set<String> processingItems;
  final Function(ShoppingItem)? onToggleCompleted;
  final Function(ShoppingItem)? onDelete;
  final Function(ShoppingItem)? onEdit;

  const ListItemsScrollView({
    super.key,
    required this.pendingItems,
    required this.completedItems,
    required this.processingItems,
    this.onToggleCompleted,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = pendingItems[index];
                return ItemCardWidget(
                  key: ValueKey(item.id),
                  item: item,
                  isProcessing: processingItems.contains(item.id),
                  onToggleCompleted: onToggleCompleted,
                  onDelete: onDelete,
                  onEdit: onEdit,
                );
              }, childCount: pendingItems.length),
            ),
          ),
          if (completedItems.isNotEmpty)
            SliverToBoxAdapter(
              child: CompletedItemsSection(
                completedItems: completedItems,
                processingItems: processingItems,
                onToggleCompleted: onToggleCompleted,
                onDelete: onDelete,
                onEdit: onEdit,
              ),
            ),
        ],
      ),
    );
  }
}
