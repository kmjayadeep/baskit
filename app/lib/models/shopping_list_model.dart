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
  @HiveField(8)
  final String? ownerId; // Owner's user ID from Firestore
  @HiveField(9)
  final List<ListMember> members; // Rich member data from Firestore

  ShoppingList({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.ownerId,
    this.members = const [],
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
      'ownerId': ownerId,
      'members': members.map((member) => member.toJson()).toList(),
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
      ownerId: json['ownerId'],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((memberJson) => ListMember.fromJson(memberJson))
              .toList() ??
          [],
    );
  }

  // Create a copy with updated fields
  ShoppingList copyWith({
    String? name,
    String? description,
    String? color,
    DateTime? updatedAt,
    List<ShoppingItem>? items,
    String? ownerId,
    List<ListMember>? members,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
    );
  }

  // Helper methods for item management
  int get completedItemsCount => items.where((item) => item.isCompleted).length;
  int get totalItemsCount => items.length;

  // Helper methods for member management
  bool get isShared => sharedMemberCount > 0;

  /// Get total member count
  int get memberCount => members.length;

  /// Get count of shared members (excluding the owner)
  /// This is used for display purposes to show "Shared with X people"
  int get sharedMemberCount {
    return memberCount - 1; // Exclude owner
  }

  /// Get list of shared members (excluding the owner)
  List<ListMember> get sharedMembers {
    return members.where((m) => m.role == MemberRole.member).toList();
  }

  /// Get display names of shared members (excluding the owner)
  List<String> get sharedMemberDisplayNames {
    return members
        .where((m) => m.role == MemberRole.member)
        .map((m) => m.displayName)
        .toList();
  }

  /// Get all members
  List<ListMember> get allMembers => members;

  /// Get display names for all members
  List<String> get allMemberDisplayNames {
    return members.map((member) => member.displayName).toList();
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, description: $description, color: $color, items: ${items.length}, members: $memberCount)';
  }
}
