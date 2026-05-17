import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../constants/app_colors.dart';

class LeaveListConfirmationDialog extends StatelessWidget {
  final ShoppingList list;

  const LeaveListConfirmationDialog({super.key, required this.list});

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
            child: const Icon(Icons.exit_to_app, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Text(
            'Leave list',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to leave "${list.name}"? You will lose access to this list unless you are invited again.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
