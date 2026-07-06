import '../models/list_member_model.dart';
import '../models/shopping_list_model.dart';

/// Typed list permissions used across UI, ViewModels, and storage logic.
///
/// The [key] values are the Firestore permission-map keys, so conversion at the
/// persistence boundary stays explicit and typo-safe in app code.
enum ListPermission {
  read('read'),
  write('write'),
  deleteItems('delete'),
  share('share'),
  manageMembers('manage_members'),
  editMetadata('edit_metadata'),
  deleteList('delete_list');

  const ListPermission(this.key);

  final String key;

  static ListPermission? fromKey(String key) {
    for (final permission in values) {
      if (permission.key == key) return permission;
    }
    return null;
  }
}

/// Service for checking user permissions based on their role and list membership.
class PermissionService {
  /// Check if a member has a specific permission.
  ///
  /// Owners always have access. Members use the granular permissions map from
  /// Firestore. A String is still accepted for older tests/callers, but app code
  /// should pass [ListPermission].
  static bool hasPermission(ListMember member, Object permission) {
    if (member.role == MemberRole.owner) {
      return true;
    }

    final key = _permissionKey(permission);
    return key != null && member.permissions[key] == true;
  }

  /// Check if a member can edit items (add/edit/complete items).
  static bool canEditItems(ListMember member) {
    return hasPermission(member, ListPermission.write);
  }

  /// Check if a member can delete items.
  static bool canDeleteItems(ListMember member) {
    return hasPermission(member, ListPermission.deleteItems);
  }

  /// Check if a member can delete the entire list.
  static bool canDeleteList(ListMember member) {
    return member.role == MemberRole.owner;
  }

  /// Check if a member can manage other members (add/remove/change roles).
  static bool canManageMembers(ListMember member) {
    return member.role == MemberRole.owner;
  }

  /// Check if a member can share the list with new users.
  static bool canShareList(ListMember member) {
    return hasPermission(member, ListPermission.share);
  }

  /// Check if a member can edit list metadata (name, description, color).
  static bool canEditListMetadata(ListMember member) {
    return hasPermission(member, ListPermission.write);
  }

  /// Check if a member can view the list (basic read access).
  static bool canViewList(ListMember member) {
    return hasPermission(member, ListPermission.read) && member.isActive;
  }

  /// Get current user's member data from a shopping list.
  static ListMember? getCurrentUserMember(
    ShoppingList list,
    String? currentUserId,
  ) {
    if (currentUserId == null || list.members.isEmpty) {
      return null;
    }

    try {
      return list.members.firstWhere(
        (member) => member.userId == currentUserId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get permission summary text for a member (for UI display).
  static String getPermissionSummary(ListMember member) {
    final permissions = <String>[];

    if (hasPermission(member, ListPermission.read)) permissions.add('View');
    if (hasPermission(member, ListPermission.write)) {
      permissions.add('Edit items');
    }
    if (hasPermission(member, ListPermission.deleteItems)) {
      permissions.add('Delete items');
    }
    if (hasPermission(member, ListPermission.share)) {
      permissions.add('Share');
    }

    if (permissions.isEmpty) {
      return 'No permissions';
    }

    return permissions.join(', ');
  }

  /// Check if user has permission for a list operation with fallback logic.
  static bool hasListPermission(
    ShoppingList list,
    String? currentUserId,
    Object permission,
  ) {
    final typedPermission = _typedPermission(permission);
    if (typedPermission == null) return false;

    final currentMember = getCurrentUserMember(list, currentUserId);

    if (currentMember != null) {
      return switch (typedPermission) {
        ListPermission.read => canViewList(currentMember),
        ListPermission.write => canEditItems(currentMember),
        ListPermission.deleteItems => canDeleteItems(currentMember),
        ListPermission.share => canShareList(currentMember),
        ListPermission.manageMembers => canManageMembers(currentMember),
        ListPermission.editMetadata => canEditListMetadata(currentMember),
        ListPermission.deleteList => currentMember.role == MemberRole.owner,
      };
    }

    // Fallback only for local-only lists that are not backed by owner/member
    // data. Shared lists must deny unknown users instead of granting full access.
    return _isLocalOnlyList(list);
  }

  /// Validate permission and return a user-facing error message if denied.
  static String? validatePermission(
    ShoppingList list,
    String? currentUserId,
    Object permission,
  ) {
    final typedPermission = _typedPermission(permission);
    if (typedPermission == null) {
      return 'You don\'t have permission to perform this action';
    }

    if (hasListPermission(list, currentUserId, typedPermission)) {
      return null;
    }

    return switch (typedPermission) {
      ListPermission.write =>
        'You don\'t have permission to edit items in this list',
      ListPermission.deleteItems =>
        'You don\'t have permission to delete items from this list',
      ListPermission.share => 'You don\'t have permission to share this list',
      ListPermission.manageMembers => 'Only the list owner can manage members',
      ListPermission.editMetadata =>
        'You don\'t have permission to edit this list',
      ListPermission.deleteList => 'Only the list owner can delete this list',
      ListPermission.read => 'You don\'t have permission to view this list',
    };
  }

  static ListPermission? _typedPermission(Object permission) {
    if (permission is ListPermission) return permission;
    if (permission is String) return ListPermission.fromKey(permission);
    return null;
  }

  static String? _permissionKey(Object permission) {
    if (permission is ListPermission) return permission.key;
    if (permission is String) return permission;
    return null;
  }

  static bool _isLocalOnlyList(ShoppingList list) {
    return list.ownerId == null && list.members.isEmpty;
  }
}
