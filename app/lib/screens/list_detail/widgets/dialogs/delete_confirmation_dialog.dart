import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../constants/app_colors.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final ShoppingList list;

  const DeleteConfirmationDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delete "${list.name}"?',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'This will permanently delete the list and all of its items.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete List'),
        ),
      ],
    );
  }
}
