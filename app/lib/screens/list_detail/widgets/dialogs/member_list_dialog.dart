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
  final String? currentUserEmail;
  final String? currentUserId; // Firebase UID for accurate ownership comparison

  const MemberListDialog({
    super.key,
    required this.list,
    this.onInviteMore,
    this.currentUserEmail,
    this.currentUserId,
  });

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
              _getMemberCountText(allMembers.length),
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

    // Determine if current user is the owner or a member
    final isCurrentUserOwner = _isCurrentUserOwner();
    final currentUserRole = isCurrentUserOwner ? 'Owner' : 'Member';

    // Add current user first
    members.add(
      MemberInfo(
        displayName: 'You',
        isCurrentUser: true,
        role: currentUserRole,
      ),
    );

    // Add other members (excluding current user if they're in the list)
    for (final memberName in list.members) {
      // Skip if this member is the current user (avoid duplication)
      if (currentUserEmail != null && memberName == currentUserEmail) {
        continue;
      }

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

  /// Get appropriate member count text
  String _getMemberCountText(int count) {
    if (count == 1) {
      return list.members.isEmpty ? 'Just you' : '1 member';
    }
    return '$count members';
  }

  /// Determine if the current user is the owner of the list
  bool _isCurrentUserOwner() {
    // Primary check: Compare current user ID with list owner ID
    if (list.ownerId != null && currentUserId != null) {
      return list.ownerId == currentUserId;
    }

    // Fallback for local-only mode or missing IDs
    // If no members are shared, current user is the owner
    if (list.members.isEmpty) {
      return true;
    }

    // If current user email is provided and is NOT in the members list,
    // they're likely the owner (owner shares with others, but isn't in the members list)
    if (currentUserEmail != null && !list.members.contains(currentUserEmail)) {
      return true;
    }

    // If we can't determine ownership definitively, assume they're a member
    return false;
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
            list.members.isEmpty ? 'Just you' : 'No members to display',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            list.members.isEmpty
                ? 'Share this list to collaborate with others'
                : 'Unable to load member information',
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
