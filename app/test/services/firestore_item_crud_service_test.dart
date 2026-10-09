import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/firestore_item_crud_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> seedListWithItem({
    String listId = 'local-list',
    String itemId = 'item-0',
    String? quantity,
  }) async {
    await firestore.collection('lists').doc(listId).set({
      'name': 'Groceries',
      'ownerId': 'owner',
      'members': {'owner': <String, dynamic>{}},
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    final seedData = <String, dynamic>{
      'name': 'Milk',
      'completed': false,
      'listItemType': 'haveAtHome',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'createdBy': 'owner',
    };
    if (quantity != null) seedData['quantity'] = quantity;
    await firestore
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(itemId)
        .set(seedData);
  }

  Future<Map<String, dynamic>> itemData(
    String listId,
    String itemId,
  ) async =>
      (await firestore
              .collection('lists')
              .doc(listId)
              .collection('items')
              .doc(itemId)
              .get())
          .data()!;

  test(
    'clears the quantity field when clearQuantity is requested',
    () async {
      await seedListWithItem(quantity: '2');

      final ok = await FirestoreItemCrudService.updateItemInListForUser(
        'local-list',
        'item-0',
        firestore: firestore,
        clearQuantity: true,
      );

      expect(ok, isTrue);
      final item = await itemData('local-list', 'item-0');
      expect(item.containsKey('quantity'), isFalse);
    },
  );

  test('updates the quantity field when a non-blank value is provided',
    () async {
      await seedListWithItem(quantity: '2');

      final ok = await FirestoreItemCrudService.updateItemInListForUser(
        'local-list',
        'item-0',
        firestore: firestore,
        quantity: '5',
      );

      expect(ok, isTrue);
      final item = await itemData('local-list', 'item-0');
      expect(item['quantity'], '5');
    },
  );
}
