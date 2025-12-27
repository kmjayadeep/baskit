import '../models/list_member_model.dart';
import '../models/shopping_list_model.dart';

/// Service for checking user permissions based on their role and list membership
///
/// This service uses the rich member data from Firestore to determine what actions
/// a user can perform on a shopping list. It provides both granular permission
/// checks and convenience methods for common UI decisions.
class PermissionService {
  /// Check if a member has a specific permission
  ///
  /// For owners: Always returns true (admin access)
  /// For members: Uses the granular permissions map from Firestore
  /// Permissions include: 'read', 'write', 'delete', 'share'
  static bool hasPermission(ListMember member, String permission) {
    // Owners have all permissions regardless of permissions map
    if (member.role == MemberRole.owner) {
      return true;
    }

    // Members use individual permission settings
    return member.permissions[permission] == true;
  }

  /// Check if a member can edit items (add/edit/complete items)
  static bool canEditItems(ListMember member) {
    // Must have write permission
    return hasPermission(member, 'write');
  }

  /// Check if a member can delete items
  static bool canDeleteItems(ListMember member) {
    // Must have delete permission
    return hasPermission(member, 'delete');
  }

  /// Check if a member can delete the entire list
  static bool canDeleteList(ListMember member) {
    // Only owners can delete lists
    return member.role == MemberRole.owner;
  }

  /// Check if a member can manage other members (add/remove/change roles)
  static bool canManageMembers(ListMember member) {
    // Must be owner
    return member.role == MemberRole.owner;
  }

  /// Check if a member can share the list with new users
  static bool canShareList(ListMember member) {
    // Must have share permission (typically owners and some editors)
    return hasPermission(member, 'share');
  }

  /// Check if a member can edit list metadata (name, description, color)
  static bool canEditListMetadata(ListMember member) {
    // Owners can always edit metadata, members need write permission
    return hasPermission(member, 'write');
  }

  /// Check if a member can view the list (basic read access)
  static bool canViewList(ListMember member) {
    // Must have read permission (all active members should have this)
    return hasPermission(member, 'read') && member.isActive;
  }

  /// Get current user's member data from a shopping list
  ///
  /// Returns null if user is not found or list has no rich member data
  static ListMember? getCurrentUserMember(
    ShoppingList list,
    String? currentUserId,
  ) {
    if (currentUserId == null || list.members.isEmpty) {
      return null;
    }

    // Find the member with matching userId
    try {
      return list.members.firstWhere(
        (member) => member.userId == currentUserId,
      );
    } catch (e) {
      // User not found in member details
      return null;
    }
  }

  /// Get permission summary text for a member (for UI display)
  static String getPermissionSummary(ListMember member) {
    final permissions = <String>[];

    if (hasPermission(member, 'read')) permissions.add('View');
    if (hasPermission(member, 'write')) permissions.add('Edit items');
    if (hasPermission(member, 'delete')) permissions.add('Delete items');
    if (hasPermission(member, 'share')) permissions.add('Share');

    if (permissions.isEmpty) {
      return 'No permissions';
    }

    return permissions.join(', ');
  }

  /// Check if user has permission for a list operation with fallback logic
  ///
  /// This method provides graceful degradation for lists without rich member data:
  /// - If rich data available: Use granular permissions based on role + permissions
  /// - If true local-only list: Full access (return true)
  /// - If Firestore list but user not found: Limited access (no owner privileges)
  static bool hasListPermission(
    ShoppingList list,
    String? currentUserId,
    String permissionType,
  ) {
    // Try to get rich member data first
    final currentMember = getCurrentUserMember(list, currentUserId);

    if (currentMember != null) {
      // Use granular permissions from Firestore
      switch (permissionType) {
        case 'read':
          return canViewList(currentMember);
        case 'write':
          return canEditItems(currentMember);
        case 'delete':
          return canDeleteItems(currentMember);
        case 'share':
          return canShareList(currentMember);
        case 'manage_members':
          return canManageMembers(currentMember);
        case 'edit_metadata':
          return canEditListMetadata(currentMember);
        case 'delete_list':
          // Only owners can delete lists, regardless of individual permissions
          return currentMember.role == MemberRole.owner;
        default:
          return false;
      }
    }

    // Fallback for local-only mode: User has full access to everything
    return true;
  }

  /// Validate permission and return error message if denied
  ///
  /// Returns null if permission granted, error message if denied
  static String? validatePermission(
    ShoppingList list,
    String? currentUserId,
    String permissionType,
  ) {
    if (hasListPermission(list, currentUserId, permissionType)) {
      return null; // Permission granted
    }

    // Return appropriate error message
    switch (permissionType) {
      case 'write':
        return 'You don\'t have permission to edit items in this list';
      case 'delete':
        return 'You don\'t have permission to delete items from this list';
      case 'share':
        return 'You don\'t have permission to share this list';
      case 'manage_members':
        return 'Only the list owner can manage members';
      case 'edit_metadata':
        return 'You don\'t have permission to edit this list';
      case 'delete_list':
        return 'Only the list owner can delete this list';
      default:
        return 'You don\'t have permission to perform this action';
    }
  }
}
