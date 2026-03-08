import 'package:flutter/material.dart';
import '../../../../models/list_member_model.dart';
import '../../../../models/shopping_list_model.dart';

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
      title: const Row(
        children: [
          Icon(Icons.person_remove, color: Colors.red),
          SizedBox(width: 8),
          Text('Remove Member'),
        ],
      ),
      content: Text(
        'Remove ${member.displayName} from "${list.name}"? They will lose access to this list unless they are invited again.',
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
