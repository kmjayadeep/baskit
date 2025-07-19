import 'package:hive/hive.dart';
import 'shopping_item.dart';

part 'shopping_list.g.dart';

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
  final List<String> members; // List of member names/emails

  ShoppingList({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
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
      'members': members,
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
    );
  }

  // Helper methods for item management
  int get completedItemsCount => items.where((item) => item.isCompleted).length;
  int get totalItemsCount => items.length;
  double get completionProgress =>
      totalItemsCount == 0 ? 0.0 : completedItemsCount / totalItemsCount;

  // Helper methods for member management
  bool get isShared => members.isNotEmpty;
  int get memberCount => members.length;

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, description: $description, color: $color, items: ${items.length}, members: ${members.length})';
  }
}
