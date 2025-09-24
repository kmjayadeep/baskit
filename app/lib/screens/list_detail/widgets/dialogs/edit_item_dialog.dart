import 'package:flutter/material.dart';
import '../../../../models/shopping_item_model.dart';

class EditItemDialog extends StatefulWidget {
  final ShoppingItem item;

  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late final TextEditingController nameController;
  late final TextEditingController quantityController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    quantityController = TextEditingController(
      text: widget.item.quantity ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': nameController.text.trim(),
        'quantity':
            quantityController.text.trim().isEmpty
                ? null
                : quantityController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
              autofocus: true,
              onFieldSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onFieldSubmitted: (_) => _handleSave(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _handleSave, child: const Text('Save')),
      ],
    );
  }
}
