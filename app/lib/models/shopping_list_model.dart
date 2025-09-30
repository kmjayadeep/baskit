import 'package:hive/hive.dart';
import 'shopping_item_model.dart';
import 'list_member_model.dart';

part 'shopping_list_model.g.dart';

@HiveType(typeId: 0)
class ShoppingList {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String color; // Store as hex string
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime updatedAt;
  @HiveField(6)
  final List<ShoppingItem> items; // Updated to use ShoppingItem objects
  @HiveField(7)
  final List<String> members; // List of member names/emails (backward compatibility)
  @HiveField(8)
  final String? ownerId; // Owner's user ID from Firestore
  @HiveField(9)
  final List<ListMember>? memberDetails; // Rich member data from Firestore

  ShoppingList({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.members = const [],
    this.ownerId,
    this.memberDetails,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'members': members,
      'ownerId': ownerId,
      'memberDetails': memberDetails?.map((member) => member.toJson()).toList(),
    };
  }

  // Create from JSON
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((itemJson) => ShoppingItem.fromJson(itemJson))
              .toList() ??
          [],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((member) => member.toString())
              .toList() ??
          [],
      ownerId: json['ownerId'],
      memberDetails:
          (json['memberDetails'] as List<dynamic>?)
              ?.map((memberJson) => ListMember.fromJson(memberJson))
              .toList(),
    );
  }

  // Create a copy with updated fields
  ShoppingList copyWith({
    String? name,
    String? description,
    String? color,
    DateTime? updatedAt,
    List<ShoppingItem>? items,
    List<String>? members,
    String? ownerId,
    List<ListMember>? memberDetails,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      members: members ?? this.members,
      ownerId: ownerId ?? this.ownerId,
      memberDetails: memberDetails ?? this.memberDetails,
    );
  }

  // Helper methods for item management
  int get completedItemsCount => items.where((item) => item.isCompleted).length;
  int get totalItemsCount => items.length;

  // Helper methods for member management
  bool get isShared => memberCount > 0;

  /// Get total member count, preferring rich data when available
  int get memberCount {
    if (memberDetails != null && memberDetails!.isNotEmpty) {
      return memberDetails!.length;
    }
    return members.length;
  }

  /// Check if rich member data is available (from Firestore)
  bool get hasRichMemberData =>
      memberDetails != null && memberDetails!.isNotEmpty;

  /// Get member details, falling back to simple strings if rich data unavailable
  List<ListMember> get allMembers {
    if (hasRichMemberData) {
      return memberDetails!;
    }
    // Convert simple member strings to ListMember objects for consistency
    return members
        .map((member) => ListMember.fromLegacyString(member))
        .toList();
  }

  /// Get display names for all members (for backward compatibility)
  List<String> get allMemberDisplayNames {
    if (hasRichMemberData) {
      return memberDetails!.map((member) => member.displayName).toList();
    }
    return members;
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, description: $description, color: $color, items: ${items.length}, members: ${members.length})';
  }
}
