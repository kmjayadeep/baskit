import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../extensions/shopping_list_extensions.dart';
import '../../../models/shopping_list_model.dart';

/// Widget that provides the add item form interface.
class AddItemWidget extends StatefulWidget {
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
  State<AddItemWidget> createState() => _AddItemWidgetState();
}

class _AddItemWidgetState extends State<AddItemWidget> {
  bool _showDetails = false;
  bool _hasItemName = false;

  bool get _canAddItem => !widget.isAddingItem && _hasItemName;

  @override
  void initState() {
    super.initState();
    _hasItemName = widget.itemController.text.trim().isNotEmpty;
    widget.itemController.addListener(_handleItemNameChanged);
  }

  @override
  void didUpdateWidget(covariant AddItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_handleItemNameChanged);
      _hasItemName = widget.itemController.text.trim().isNotEmpty;
      widget.itemController.addListener(_handleItemNameChanged);
    }
  }

  @override
  void dispose() {
    widget.itemController.removeListener(_handleItemNameChanged);
    super.dispose();
  }

  void _handleItemNameChanged() {
    final hasItemName = widget.itemController.text.trim().isNotEmpty;
    if (hasItemName == _hasItemName) {
      return;
    }

    setState(() => _hasItemName = hasItemName);
  }

  @override
  Widget build(BuildContext context) {
    final listColor = widget.list.displayColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.warmBackground,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.itemController,
                  enabled: !widget.isAddingItem,
                  decoration: InputDecoration(
                    hintText:
                        widget.isAddingItem ? 'Adding item...' : 'Add item',
                    prefixIcon:
                        widget.isAddingItem
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : const Icon(Icons.add_shopping_cart_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Quantity, note, or type',
                      onPressed:
                          widget.isAddingItem
                              ? null
                              : () {
                                setState(() => _showDetails = !_showDetails);
                              },
                      icon: Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.notes_outlined,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _canAddItem ? widget.onAddItem() : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _canAddItem ? widget.onAddItem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: listColor,
                    disabledBackgroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon:
                      widget.isAddingItem
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child:
                _showDetails
                    ? Padding(
                      key: const ValueKey('details-field'),
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: widget.quantityController,
                        enabled: !widget.isAddingItem,
                        decoration: const InputDecoration(
                          hintText: 'Qty, note, or type',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        onSubmitted:
                            (_) => _canAddItem ? widget.onAddItem() : null,
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey('details-hidden')),
          ),
        ],
      ),
    );
  }
}
