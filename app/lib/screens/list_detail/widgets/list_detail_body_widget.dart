import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_list_model.dart';
import '../../../models/shopping_item_model.dart';
import '../utils/item_sorter.dart';
import 'list_header_widget.dart';
import 'add_item_widget.dart';
import 'quick_add_chips_widget.dart';
import 'empty_items_state_widget.dart';
import 'items_header_widget.dart';
import 'item_card_widget.dart';
import 'completed_items_section_widget.dart';

/// The main body content for a loaded list (list info header, add item,
/// quick-add chips, and items list).
///
/// Extracted from [ListDetailScreen] to improve readability.
class ListDetailBodyWidget extends StatelessWidget {
  final ShoppingList list;
  final bool canWrite;
  final bool canDeleteItems;
  final ItemsSortOption selectedSort;
  final bool showQuickAddChips;
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final bool isAddingItem;
  final Set<String> processingItems;
  final VoidCallback onAddItem;
  final ValueChanged<String> onQuickAddItem;
  final VoidCallback onDismissChips;
  final ValueChanged<ItemsSortOption> onSortChanged;
  final void Function(ShoppingItem) onToggleCompleted;
  final void Function(ShoppingItem) onDelete;
  final void Function(ShoppingItem) onEdit;

  const ListDetailBodyWidget({
    super.key,
    required this.list,
    required this.canWrite,
    required this.canDeleteItems,
    required this.selectedSort,
    required this.showQuickAddChips,
    required this.itemController,
    required this.quantityController,
    required this.isAddingItem,
    required this.processingItems,
    required this.onAddItem,
    required this.onQuickAddItem,
    required this.onDismissChips,
    required this.onSortChanged,
    required this.onToggleCompleted,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = ItemSorter.sort(list.items, selectedSort);
    final pendingItems =
        sortedItems.where((item) => !item.isCompleted).toList();
    final completedItems =
        sortedItems.where((item) => item.isCompleted).toList();

    return Column(
      children: [
        // List info header
        ListHeaderWidget(list: list),

        // Add item section — only if user can write
        if (canWrite)
          AddItemWidget(
            list: list,
            itemController: itemController,
            quantityController: quantityController,
            isAddingItem: isAddingItem,
            onAddItem: onAddItem,
          ),

        // Quick-add chips
        if (canWrite &&
            list.frequentItemNames.isNotEmpty &&
            showQuickAddChips)
          QuickAddChips(
            itemNames: list.frequentItemNames,
            enabled: !isAddingItem,
            onItemTap: onQuickAddItem,
            onDismiss: onDismissChips,
          ),

        // Items header
        if (list.items.isNotEmpty)
          ItemsHeaderWidget(
            itemsCount: pendingItems.length,
            selectedSort: selectedSort,
            onSortChanged: onSortChanged,
          ),

        // Items list
        Expanded(
          child:
              list.items.isEmpty
                  ? const EmptyItemsStateWidget()
                  : SafeArea(
                    child: CustomScrollView(
                      slivers: [
                        // Pending items
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = pendingItems[index];
                              return ItemCardWidget(
                                key: ValueKey(item.id),
                                item: item,
                                isProcessing: processingItems.contains(item.id),
                                onToggleCompleted:
                                    canWrite ? onToggleCompleted : null,
                                onDelete:
                                    canDeleteItems ? onDelete : null,
                                onEdit: canWrite ? onEdit : null,
                              );
                            }, childCount: pendingItems.length),
                          ),
                        ),

                        // Completed items section
                        if (completedItems.isNotEmpty)
                          SliverToBoxAdapter(
                            child: CompletedItemsSection(
                              completedItems: completedItems,
                              processingItems: processingItems,
                              onToggleCompleted:
                                  canWrite ? onToggleCompleted : null,
                              onDelete: canDeleteItems ? onDelete : null,
                              onEdit: canWrite ? onEdit : null,
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}
