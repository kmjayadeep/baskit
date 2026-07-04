import 'permission_service.dart';

class FirestorePermissionRules {
  const FirestorePermissionRules._();

  static bool hasPermission(
    Map<String, dynamic> data,
    String userId,
    Object permission,
  ) {
    if (data['ownerId'] == userId) return true;

    final permissionKey = _permissionKey(permission);
    if (permissionKey == null) return false;

    final members = data['members'] as Map<String, dynamic>? ?? {};
    final userMember = members[userId];
    if (userMember is! Map<String, dynamic>) return false;
    if (userMember['role'] == 'owner') return true;

    final permissions =
        userMember['permissions'] as Map<String, dynamic>? ?? {};
    return permissions[permissionKey] == true;
  }

  static bool canRemoveMember(
    Map<String, dynamic> data,
    String currentUserId,
    String targetUserId,
  ) {
    if (data['ownerId'] == targetUserId) return false;
    if (currentUserId == targetUserId) return true;

    return data['ownerId'] == currentUserId ||
        hasPermission(data, currentUserId, ListPermission.manageMembers);
  }

  static String? _permissionKey(Object permission) {
    if (permission is ListPermission) return permission.key;
    if (permission is String) return permission;
    return null;
  }
}
