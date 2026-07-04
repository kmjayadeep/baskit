import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/shopping_list_model.dart';

class ClearCompletedConfirmationDialog extends StatelessWidget {
  final ShoppingList list;

  const ClearCompletedConfirmationDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final completedCount = list.completedItemsCount;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.basketOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.clear_all, color: AppColors.basketOrange),
          ),
          const SizedBox(width: 10),
          Text(
            'Clear completed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently remove $completedCount completed ${completedCount == 1 ? 'item' : 'items'} from "${list.name}".',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.basketOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.basketOrange.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.basketOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is useful for reusing lists like weekly grocery lists.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.basketOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Clear Items'),
        ),
      ],
    );
  }
}
