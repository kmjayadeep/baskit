import 'package:flutter/material.dart';
import '../../../models/shopping_list_model.dart';

/// Widget that provides the add item form interface
class AddItemWidget extends StatelessWidget {
  final ShoppingList list;
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final bool isAddingItem;
  final VoidCallback onAddItem;

  const AddItemWidget({
    super.key,
    required this.list,
    required this.itemController,
    required this.quantityController,
    required this.isAddingItem,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final listColor = list.displayColor;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main item name input
          TextField(
            controller: itemController,
            enabled: !isAddingItem,
            decoration: InputDecoration(
              hintText: isAddingItem ? 'Adding item...' : 'Add new item...',
              border: const OutlineInputBorder(),
              prefixIcon:
                  isAddingItem
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : const Icon(Icons.add),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => isAddingItem ? null : onAddItem(),
          ),

          const SizedBox(height: 12),

          // Quantity input and add button row
          Row(
            children: [
              // Quantity input
              Expanded(
                child: TextField(
                  controller: quantityController,
                  enabled: !isAddingItem,
                  decoration: const InputDecoration(
                    hintText: 'Quantity (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => isAddingItem ? null : onAddItem(),
                ),
              ),

              const SizedBox(width: 12),

              // Add button
              ElevatedButton(
                onPressed: isAddingItem ? null : onAddItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddingItem ? Colors.grey : listColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    isAddingItem
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
