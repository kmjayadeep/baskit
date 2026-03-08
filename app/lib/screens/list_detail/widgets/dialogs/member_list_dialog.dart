import 'package:flutter/material.dart';
import '../../../../extensions/shopping_list_extensions.dart';
import '../../../../models/list_member_model.dart';
import '../../../../models/shopping_list_model.dart';
import 'remove_member_confirmation_dialog.dart';

/// Dialog that displays the complete list of members for a shopping list
///
/// Shows all members with their display names/emails, includes the current user,
/// and provides an option to invite more members.
class MemberListDialog extends StatefulWidget {
  final ShoppingList list;
  final VoidCallback? onInviteMore;
  final String? currentUserEmail;
  final String? currentUserId; // Firebase UID for accurate ownership comparison
  final Future<bool> Function(ListMember member)? onRemoveMember;

  const MemberListDialog({
    super.key,
    required this.list,
    this.onInviteMore,
    this.currentUserEmail,
    this.currentUserId,
    this.onRemoveMember,
  });

  @override
  State<MemberListDialog> createState() => _MemberListDialogState();
}

class _MemberListDialogState extends State<MemberListDialog> {
  late ShoppingList _list;

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  @override
  void didUpdateWidget(covariant MemberListDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list != widget.list) {
      _list = widget.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all members including indication of current user
    final allMembers = _getAllMembers();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _list.sharingIcon,
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
              _list.name,
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
        if (widget.onInviteMore != null)
          TextButton.icon(
            onPressed: widget.onInviteMore,
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

  /// Get all members including current user indication with rich data support
  List<MemberInfo> _getAllMembers() {
    final members = <MemberInfo>[];

    // Get all members using the enhanced method
    final allMembers = _list.allMembers;

    // Determine if current user is the owner
    final isCurrentUserOwner = _isCurrentUserOwner();

    // Add current user first if they're not already in the member list
    final currentUserInList = allMembers.any(
      (member) =>
          member.userId == widget.currentUserId ||
          (widget.currentUserEmail != null &&
              member.email == widget.currentUserEmail),
    );

    if (!currentUserInList) {
      final currentUserRole =
          isCurrentUserOwner ? MemberRole.owner : MemberRole.member;
      members.add(
        MemberInfo(
          displayName: isCurrentUserOwner ? 'You' : currentUserRole.displayName,
          email: widget.currentUserEmail,
          isCurrentUser: true,
          role: currentUserRole.displayName,
          roleEmoji: currentUserRole.emoji,
          hasRichData: true,
        ),
      );
    }

    // Add all other members
    for (final member in allMembers) {
      final isCurrentMember =
          member.userId == widget.currentUserId ||
          (widget.currentUserEmail != null &&
              member.email == widget.currentUserEmail);

      members.add(
        MemberInfo(
          displayName: isCurrentMember ? 'You' : member.displayName,
          email: member.email,
          isCurrentUser: isCurrentMember,
          role: member.role.displayName,
          roleEmoji: member.role.emoji,
          hasRichData: true,
          listMember: member,
        ),
      );
    }

    return members;
  }

  /// Get appropriate member count text
  String _getMemberCountText(int count) {
    if (count == 1) {
      return _list.members.isEmpty ? 'Just you' : '1 member';
    }
    return '$count members';
  }

  /// Determine if the current user is the owner of the list
  bool _isCurrentUserOwner() {
    // Primary check: Compare current user ID with list owner ID
    if (_list.ownerId != null && widget.currentUserId != null) {
      return _list.ownerId == widget.currentUserId;
    }

    // Fallback for local-only mode or missing IDs
    // If no members are shared, current user is the owner
    if (_list.members.isEmpty) {
      return true;
    }

    // If we can't determine ownership definitively, assume they're a member
    return false;
  }

  /// Build member list tile with rich data support
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role with emoji (when rich data is available)
          Row(
            children: [
              if (member.roleEmoji != null) ...[
                Text(member.roleEmoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              Text(
                member.role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Email (when available and different from display name)
          if (member.email != null &&
              member.email != member.displayName &&
              !member.isCurrentUser) ...[
            const SizedBox(height: 2),
            Text(
              member.email!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      trailing:
          _canRemoveMember(member)
              ? IconButton(
                tooltip: 'Remove member',
                icon: const Icon(Icons.person_remove, color: Colors.red),
                onPressed: () => _showRemoveMemberDialog(context, member),
              )
              : null,
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
            _list.members.isEmpty ? 'Just you' : 'No members to display',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _list.members.isEmpty
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

  bool _canRemoveMember(MemberInfo member) {
    if (!_isCurrentUserOwner()) {
      return false;
    }

    final listMember = member.listMember;
    if (listMember == null) {
      return false;
    }

    if (_list.ownerId != null && listMember.userId == _list.ownerId) {
      return false;
    }

    return !member.isCurrentUser;
  }

  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    MemberInfo member,
  ) async {
    final onRemoveMember = widget.onRemoveMember;
    final listMember = member.listMember;
    if (onRemoveMember == null || listMember == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) =>
              RemoveMemberConfirmationDialog(list: _list, member: listMember),
    );

    if (confirmed != true) {
      return;
    }

    final success = await onRemoveMember(listMember);
    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _list = _list.copyWith(
          members:
              _list.members
                  .where((member) => member.userId != listMember.userId)
                  .toList(),
        );
      });
    }
  }
}

/// Enhanced data class to hold member information with rich data support
class MemberInfo {
  final String displayName;
  final String? email;
  final bool isCurrentUser;
  final String role;
  final String? roleEmoji;
  final bool hasRichData;
  final ListMember? listMember;

  MemberInfo({
    required this.displayName,
    this.email,
    required this.isCurrentUser,
    required this.role,
    this.roleEmoji,
    this.hasRichData = false,
    this.listMember,
  });
}
