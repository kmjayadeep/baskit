import 'package:flutter/material.dart';
import '../../../../extensions/shopping_list_extensions.dart';
import '../../../../models/list_member_model.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../constants/app_colors.dart';
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _list.sharingIcon,
              size: 20,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getMemberCountText(allMembers.length),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
          FilledButton.icon(
            onPressed: widget.onInviteMore,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Invite'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.warmBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildMemberAvatar(context, member),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      member.isCurrentUser ? FontWeight.w800 : FontWeight.w700,
                  color: AppColors.textPrimary,
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
                    color: AppColors.textMuted,
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
                  color: AppColors.textMuted,
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
      ),
    );
  }

  /// Build member avatar with initials
  Widget _buildMemberAvatar(BuildContext context, MemberInfo member) {
    final initials = _getInitials(member.displayName);
    final backgroundColor =
        member.isCurrentUser ? AppColors.primaryGreen : AppColors.basketOrange;
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_add_alt_1_outlined,
              size: 30,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _list.members.isEmpty ? 'Just you' : 'No members to display',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _list.members.isEmpty
                ? 'Share this list to collaborate with others'
                : 'Unable to load member information',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
