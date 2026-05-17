import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/shopping_list_model.dart';

/// Widget that provides the add item form interface.
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: AppColors.warmBackground,
      child: Column(
        children: [
          TextField(
            controller: itemController,
            enabled: !isAddingItem,
            decoration: InputDecoration(
              hintText: isAddingItem ? 'Adding item...' : 'Add grocery item',
              prefixIcon:
                  isAddingItem
                      ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : const Icon(Icons.add_shopping_cart_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => isAddingItem ? null : onAddItem(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: quantityController,
                  enabled: !isAddingItem,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  onSubmitted: (_) => isAddingItem ? null : onAddItem(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isAddingItem ? null : onAddItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAddingItem ? AppColors.textMuted : listColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  icon:
                      isAddingItem
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
