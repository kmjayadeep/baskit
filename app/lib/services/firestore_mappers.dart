import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/list_member_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';

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
    return ShoppingItem(
      id: id,
      name: data['name'] ?? '',
      quantity: data['quantity']?.toString(),
      isCompleted: data['completed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
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
      color: data['color'] ?? '#2196F3',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
      ownerId: data['ownerId'] as String?,
      members: membersFromData(data),
    );
  }
}
