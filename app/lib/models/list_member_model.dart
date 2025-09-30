import 'package:hive/hive.dart';

part 'list_member_model.g.dart';

/// Enum representing different member roles and their permission levels
@HiveType(typeId: 4)
enum MemberRole {
  @HiveField(0)
  owner, // Full control (delete list, manage members, edit items)

  @HiveField(1)
  editor, // Can add/edit/delete items, but cannot delete list or manage members

  @HiveField(2)
  viewer, // Can only view items, no editing permissions
}

/// Enhanced model representing a member of a shopping list with rich data from Firestore
///
/// This captures the full member information that Firestore stores, preventing data loss
/// during the mapping process. Designed to work alongside the existing simple string-based
/// member system for backward compatibility.
@HiveType(typeId: 5)
class ListMember {
  /// Firebase UID (primary key for identifying the member)
  @HiveField(0)
  final String userId;

  /// Display name to show in the UI (e.g., "John Doe")
  @HiveField(1)
  final String displayName;

  /// Email address of the member
  @HiveField(2)
  final String? email;

  /// Profile picture URL if available
  @HiveField(3)
  final String? avatarUrl;

  /// Member's role and permission level
  @HiveField(4)
  final MemberRole role;

  /// When the member joined the list
  @HiveField(5)
  final DateTime joinedAt;

  /// Whether the member still has access (for future soft-delete functionality)
  @HiveField(6)
  final bool isActive;

  /// Granular permissions from Firestore
  /// Keys: 'read', 'write', 'delete', 'share'
  /// Values: true/false for each permission
  @HiveField(7)
  final Map<String, bool> permissions;

  const ListMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    required this.permissions,
  });

  /// Create ListMember from Firestore member data
  factory ListMember.fromFirestore(
    String userId,
    Map<String, dynamic> memberData,
  ) {
    // Parse role from string to enum
    final roleString = memberData['role'] as String? ?? 'viewer';
    final role = MemberRole.values.firstWhere(
      (r) => r.name == roleString,
      orElse: () => MemberRole.viewer, // Default to viewer if unknown role
    );

    // Parse permissions map
    final permissionsData =
        memberData['permissions'] as Map<String, dynamic>? ?? {};
    final permissions = <String, bool>{};
    for (final entry in permissionsData.entries) {
      if (entry.value is bool) {
        permissions[entry.key] = entry.value as bool;
      }
    }

    // Parse joinedAt timestamp
    DateTime joinedAt = DateTime.now();
    final joinedAtData = memberData['joinedAt'];
    if (joinedAtData != null) {
      if (joinedAtData is DateTime) {
        joinedAt = joinedAtData;
      } else if (joinedAtData.toString().isNotEmpty) {
        try {
          // Handle Firestore Timestamp or ISO string
          joinedAt = DateTime.parse(joinedAtData.toString());
        } catch (e) {
          // Fallback to current time if parsing fails
          joinedAt = DateTime.now();
        }
      }
    }

    return ListMember(
      userId: userId,
      displayName: memberData['displayName'] as String? ?? 'Unknown User',
      email: memberData['email'] as String?,
      avatarUrl: memberData['avatarUrl'] as String?,
      role: role,
      joinedAt: joinedAt,
      isActive: memberData['isActive'] as bool? ?? true,
      permissions: permissions,
    );
  }

  /// Create ListMember from legacy string format (for migration support)
  ///
  /// This helps migrate from the old List of Strings members format
  /// Assumes the string is either an email or display name
  factory ListMember.fromLegacyString(String memberString) {
    final isEmail = memberString.contains('@');

    return ListMember(
      userId: memberString, // Use the string as a temp ID until we get real UID
      displayName: memberString,
      email: isEmail ? memberString : null,
      role: MemberRole.editor, // Default role for existing members
      joinedAt: DateTime.now(), // Current time for legacy members
      permissions: const {
        'read': true,
        'write': true,
        'delete': true,
        'share': false, // Only owners can share by default
      },
    );
  }

  /// Convert to JSON for API storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  /// Create from JSON
  factory ListMember.fromJson(Map<String, dynamic> json) {
    final roleString = json['role'] as String? ?? 'viewer';
    final role = MemberRole.values.firstWhere(
      (r) => r.name == roleString,
      orElse: () => MemberRole.viewer,
    );

    return ListMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Unknown User',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: role,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      permissions: Map<String, bool>.from(json['permissions'] as Map? ?? {}),
    );
  }

  /// Create a copy with updated fields
  ListMember copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    MemberRole? role,
    DateTime? joinedAt,
    bool? isActive,
    Map<String, bool>? permissions,
  }) {
    return ListMember(
      userId: userId, // userId never changes
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Get display string for backward compatibility
  String get displayString => displayName;

  @override
  String toString() {
    return 'ListMember(userId: $userId, displayName: $displayName, role: ${role.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListMember && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

/// Extension to provide human-readable role descriptions and UI helpers
extension MemberRoleExtensions on MemberRole {
  /// Get display name for the role
  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.editor:
        return 'Editor';
      case MemberRole.viewer:
        return 'Viewer';
    }
  }

  /// Get role description for tooltips
  String get description {
    switch (this) {
      case MemberRole.owner:
        return 'Full control over list and members';
      case MemberRole.editor:
        return 'Can add, edit, and delete items';
      case MemberRole.viewer:
        return 'Can only view items';
    }
  }

  /// Get appropriate emoji icon for the role
  String get emoji {
    switch (this) {
      case MemberRole.owner:
        return '👑'; // Crown for owner
      case MemberRole.editor:
        return '✏️'; // Pencil for editor
      case MemberRole.viewer:
        return '👁️'; // Eye for viewer
    }
  }
}
