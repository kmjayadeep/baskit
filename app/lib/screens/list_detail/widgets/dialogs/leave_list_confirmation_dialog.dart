import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';

class LeaveListConfirmationDialog extends StatelessWidget {
  final ShoppingList list;

  const LeaveListConfirmationDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.exit_to_app, color: Colors.red),
          SizedBox(width: 8),
          Text('Leave List'),
        ],
      ),
      content: Text(
        'Are you sure you want to leave "${list.name}"? You will lose access to this list unless you are invited again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Leave List'),
        ),
      ],
    );
  }
}
