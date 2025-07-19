import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 1)
class ShoppingItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? quantity;
  @HiveField(3)
  final bool isCompleted;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime? completedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
    );
  }

  // Create a copy with updated fields
  ShoppingItem copyWith({
    String? name,
    String? quantity,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity, isCompleted: $isCompleted)';
  }
}
