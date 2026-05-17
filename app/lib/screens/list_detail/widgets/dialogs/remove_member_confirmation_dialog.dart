import 'package:flutter/material.dart';
import '../../../../models/list_member_model.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../constants/app_colors.dart';

class RemoveMemberConfirmationDialog extends StatelessWidget {
  final ShoppingList list;
  final ListMember member;

  const RemoveMemberConfirmationDialog({
    super.key,
    required this.list,
    required this.member,
  });

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
            child: const Icon(Icons.person_remove, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Text(
            'Remove member',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Remove ${member.displayName} from "${list.name}"? They will lose access to this list unless they are invited again.',
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
          child: const Text('Remove Member'),
        ),
      ],
    );
  }
}
