import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/shopping_list_model.dart';

class ListDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ShoppingList list;
  final bool canShare;
  final bool canEditMetadata;
  final bool canDeleteItems;
  final bool canDeleteList;
  final bool canLeaveList;
  final VoidCallback onShowMembers;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClearCompleted;
  final VoidCallback onLeave;

  const ListDetailAppBar({
    super.key,
    required this.list,
    required this.canShare,
    required this.canEditMetadata,
    required this.canDeleteItems,
    required this.canDeleteList,
    required this.canLeaveList,
    required this.onShowMembers,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    required this.onClearCompleted,
    required this.onLeave,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  bool get _canClearCompleted => canDeleteItems && list.completedItemsCount > 0;

  bool get _hasOverflowActions =>
      _canClearCompleted || canDeleteList || canLeaveList;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/lists');
          }
        },
      ),
      backgroundColor: AppColors.warmBackground,
      surfaceTintColor: Colors.transparent,
      actions: [
        if (list.sharedMemberCount > 0)
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: onShowMembers,
            tooltip: 'View Members',
          ),
        if (canShare)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: 'Share List',
          ),
        if (canEditMetadata)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
            tooltip: 'Edit List',
          ),
        if (_hasOverflowActions)
          PopupMenuButton<_ListDetailMenuAction>(
            itemBuilder:
                (_) => [
                  if (_canClearCompleted)
                    const PopupMenuItem(
                      value: _ListDetailMenuAction.clearCompleted,
                      child: _MenuRow(
                        icon: Icons.clear_all,
                        label: 'Clear Completed Items',
                        color: Colors.orange,
                      ),
                    ),
                  if (canLeaveList)
                    const PopupMenuItem(
                      value: _ListDetailMenuAction.leave,
                      child: _MenuRow(
                        icon: Icons.exit_to_app,
                        label: 'Leave List',
                        color: Colors.red,
                      ),
                    ),
                  if (canDeleteList)
                    const PopupMenuItem(
                      value: _ListDetailMenuAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete,
                        label: 'Delete List',
                        color: Colors.red,
                      ),
                    ),
                ],
            onSelected: (value) {
              switch (value) {
                case _ListDetailMenuAction.clearCompleted:
                  onClearCompleted();
                case _ListDetailMenuAction.leave:
                  onLeave();
                case _ListDetailMenuAction.delete:
                  onDelete();
              }
            },
          ),
      ],
    );
  }
}

enum _ListDetailMenuAction { clearCompleted, leave, delete }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
