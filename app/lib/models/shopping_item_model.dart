import 'package:hive/hive.dart';

part 'shopping_item_model.g.dart';

/// Enum representing the type/category of a shopping list item.
///
/// Existing Hive items default to [needsPurchase] because Hive enum fields
/// default to the first value in the enum when the field is missing.
/// Firestore items that lack the field also fall back to [needsPurchase] in
/// the mapper layer.
enum ItemType {
  /// A regular shopping item the user needs to purchase.
  @HiveField(0)
  needsPurchase,

  /// An item the user already has at home (pantry, fridge, cupboard, etc.).
  ///
  /// These items can be marked as "Finished" to move them to [runOut].
  @HiveField(1)
  haveAtHome,

  /// An item that was [haveAtHome] but the user has marked as "Finished"
  /// (used up / consumed). Useful for restocking decisions.
  @HiveField(2)
  runOut,
}

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

  /// The type of this item.
  ///
  /// Hive defaults to [needsPurchase] (first enum value) when the field is
  /// absent, so existing items remain unaffected by this migration.
  /// Firestore items without the field are mapped to [needsPurchase] in
  /// [FirestoreMappers.itemFromData].
  @HiveField(6)
  final ItemType listItemType;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.listItemType = ItemType.needsPurchase,
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
      'listItemType': listItemType.name,
    };
  }

  // Create from JSON
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    return ShoppingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: createdAtStr != null
          ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? (() {
              final value = json['completedAt'];
              if (value is String) {
                return DateTime.tryParse(value);
              }
              if (value is DateTime) return value;
              return null;
            })()
          : null,
      listItemType: _parseItemType(json['listItemType'] as String?),
    );
  }

  /// Parses [ItemType] from a string, falling back to [needsPurchase].
  static ItemType _parseItemType(String? type) {
    if (type == null) return ItemType.needsPurchase;
    for (final value in ItemType.values) {
      if (value.name == type) return value;
    }
    return ItemType.needsPurchase;
  }

  // Create a copy with updated fields
  ShoppingItem copyWith({
    String? name,
    String? quantity,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearQuantity = false,
    ItemType? listItemType,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      listItemType: listItemType ?? this.listItemType,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, quantity: $quantity, isCompleted: $isCompleted, listItemType: $listItemType)';
  }
}
