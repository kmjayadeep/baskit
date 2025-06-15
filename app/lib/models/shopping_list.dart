import 'dart:convert';

class ShoppingList {
  final String id;
  final String name;
  final String description;
  final String color; // Store as hex string
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> items; // For now, just store item names

  ShoppingList({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
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
      'items': items,
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
      items: List<String>.from(json['items'] ?? []),
    );
  }

  // Create a copy with updated fields
  ShoppingList copyWith({
    String? name,
    String? description,
    String? color,
    DateTime? updatedAt,
    List<String>? items,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, description: $description, color: $color, items: ${items.length})';
  }
}
