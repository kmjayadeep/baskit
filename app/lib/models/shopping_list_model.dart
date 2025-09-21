import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'shopping_item_model.dart';

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

  /// Get items sorted by completion status (incomplete first, completed last)
  /// Within each group, items are sorted by creation time (oldest first)
  List<ShoppingItem> get sortedItems {
    return [...items]..sort((a, b) {
      // Incomplete items first, completed items last
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Within each group, maintain original order (by creation time)
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  // Helper methods for member management
  bool get isShared => members.isNotEmpty;
  int get memberCount => members.length;

  // UI Helper Methods

  /// Get the display color for this list by parsing the hex color string
  ///
  /// Supports both 6-character (#RRGGBB) and 7-character (#RRGGBB) hex strings.
  /// Automatically adds alpha channel (FF) for 6-character strings.
  /// Returns default blue color if parsing fails.
  Color get displayColor {
    try {
      final buffer = StringBuffer();
      if (color.length == 6 || color.length == 7) buffer.write('ff');
      buffer.write(color.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }

  /// Get appropriate sharing status text based on member count
  String get sharingText {
    // Note: list.members contains display names, not IDs
    // Current user's name is not included in members
    if (members.isEmpty) {
      return 'Private';
    } else if (members.length == 1) {
      return 'Shared with ${members[0]}';
    } else if (members.length == 2) {
      return 'Shared with ${members[0]} and ${members[1]}';
    } else {
      return 'Shared with ${members.length} people';
    }
  }

  /// Get appropriate sharing icon based on member count
  IconData get sharingIcon {
    if (members.isEmpty) {
      return Icons.lock;
    } else if (members.length == 1) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, description: $description, color: $color, items: ${items.length}, members: ${members.length})';
  }
}
