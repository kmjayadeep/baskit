import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final ShoppingList list;

  const DeleteConfirmationDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete "${list.name}"?'),
      content: const Text(
        'This action cannot be undone. All items in this list will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
