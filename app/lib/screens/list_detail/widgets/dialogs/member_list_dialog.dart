import 'package:flutter/material.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../extensions/shopping_list_extensions.dart';

/// Dialog that displays the complete list of members for a shopping list
///
/// Shows all members with their display names/emails, includes the current user,
/// and provides an option to invite more members.
class MemberListDialog extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onInviteMore;

  const MemberListDialog({super.key, required this.list, this.onInviteMore});

  @override
  Widget build(BuildContext context) {
    // Get all members including indication of current user
    final allMembers = _getAllMembers();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            list.sharingIcon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'List Members',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List info
            Text(
              list.name,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${allMembers.length} ${allMembers.length == 1 ? 'member' : 'members'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Members list
            if (allMembers.isEmpty)
              _buildEmptyState(context)
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allMembers.length,
                  itemBuilder: (context, index) {
                    final member = allMembers[index];
                    return _buildMemberTile(context, member);
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (onInviteMore != null)
          TextButton.icon(
            onPressed: onInviteMore,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Invite More'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Get all members including current user indication
  List<MemberInfo> _getAllMembers() {
    final members = <MemberInfo>[];

    // Add current user (list owner)
    members.add(
      MemberInfo(displayName: 'You', isCurrentUser: true, role: 'Owner'),
    );

    // Add shared members
    for (final memberName in list.members) {
      members.add(
        MemberInfo(
          displayName: memberName,
          isCurrentUser: false,
          role: 'Member',
        ),
      );
    }

    return members;
  }

  /// Build member list tile
  Widget _buildMemberTile(BuildContext context, MemberInfo member) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: _buildMemberAvatar(context, member),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight:
                    member.isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (member.isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        member.role,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }

  /// Build member avatar with initials
  Widget _buildMemberAvatar(BuildContext context, MemberInfo member) {
    final initials = _getInitials(member.displayName);
    final backgroundColor =
        member.isCurrentUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary;
    final textColor =
        member.isCurrentUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary;

    return CircleAvatar(
      radius: 18,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Extract initials from display name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    } else {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final last =
          parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
      return (first + last).toUpperCase();
    }
  }

  /// Build empty state when no members
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.person_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Just you for now',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this list to collaborate with others',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Simple data class to hold member information
class MemberInfo {
  final String displayName;
  final bool isCurrentUser;
  final String role;

  MemberInfo({
    required this.displayName,
    required this.isCurrentUser,
    required this.role,
  });
}
