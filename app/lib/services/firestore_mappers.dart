import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/list_member_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';

/// String representation of [ItemType] used in Firestore.
class _ItemTypes {
  const _ItemTypes._();

  /// Reverse lookup: Firestore string → enum name for parsing.
  static const _nameMap = <String, String>{
    'needs_purchase': 'needsPurchase',
    'have_at_home': 'haveAtHome',
    'run_out': 'runOut',
  };

  /// Convert Firestore string to enum name, defaulting to 'needsPurchase'.
  static String toEnumName(String? type) {
    if (type == null) return 'needsPurchase';
    // Accept both the historical snake_case values and the enum names used
    // by the Firestore write paths.
    return _nameMap[type] ?? type;
  }

  /// Parse a Firestore 'listItemType' string into an [ItemType].
  static ItemType _parseItemType(String? type) {
    final enumName = toEnumName(type);
    return ItemType.values.firstWhere(
      (e) => e.name == enumName,
      orElse: () => ItemType.needsPurchase,
    );
  }
}

class FirestoreMappers {
  const FirestoreMappers._();

  static List<ListMember> membersFromData(Map<String, dynamic> data) {
    final membersData = data['members'] as Map<String, dynamic>? ?? {};
    return membersData.entries
        .where((entry) => entry.value is Map<String, dynamic>)
        .map(
          (entry) => ListMember.fromFirestore(
            entry.key,
            entry.value as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static ShoppingItem itemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return itemFromData(doc.id, doc.data());
  }

  static ShoppingItem itemFromData(String id, Map<String, dynamic> data) {
    final itemTypeString = data['listItemType'] as String?;
    return ShoppingItem(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity']?.toString(),
      isCompleted: data['completed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      listItemType: _ItemTypes._parseItemType(itemTypeString),
    );
  }

  static ShoppingList listFromData({
    required String id,
    required Map<String, dynamic> data,
    required List<ShoppingItem> items,
  }) {
    return ShoppingList(
      id: id,
      name: data['name'] ?? 'Unnamed List',
      description: data['description'] ?? '',
      color: data['color'] ?? '#F59E0B',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
      ownerId: data['ownerId'] as String?,
      members: membersFromData(data),
    );
  }
}
