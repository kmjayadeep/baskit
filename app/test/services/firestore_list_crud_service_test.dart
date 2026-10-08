import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/services/firestore_list_crud_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  ShoppingList list({int itemCount = 1}) => ShoppingList(
    id: 'local-list',
    name: 'Groceries',
    description: 'Weekly shop',
    color: '#F59E0B',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    items: List.generate(
      itemCount,
      (index) => ShoppingItem(
        id: 'item-$index',
        name: 'Milk $index',
        quantity: '2',
        createdAt: DateTime(2026),
        listItemType: ItemType.haveAtHome,
      ),
    ),
  );

  Future<String?> upload(ShoppingList value) =>
      FirestoreListCrudService.createListForUser(
        value,
        firestore: firestore,
        userId: 'owner',
        displayName: 'Alex',
        email: 'alex@example.com',
        avatarUrl: 'https://example.com/alex.png',
      );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('owner').set({'listIds': []});
  });

  test(
    'creates list and items with stable local IDs and owner profile',
    () async {
      expect(await upload(list()), 'local-list');
      final data = (await firestore.collection('lists').doc('local-list').get())
          .data()!;
      expect(data['name'], 'Groceries');
      expect(data['description'], 'Weekly shop');
      expect(data['color'], '#F59E0B');
      expect(data['ownerId'], 'owner');
      expect(data['memberIds'], ['owner']);
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
      final members = data['members'] as Map<String, dynamic>;
      final owner = members['owner'] as Map<String, dynamic>;
      expect(owner, containsPair('displayName', 'Alex'));
      expect(owner, containsPair('email', 'alex@example.com'));
      expect(owner, containsPair('avatarUrl', 'https://example.com/alex.png'));
      expect(owner['permissions'], {
        'read': true,
        'write': true,
        'delete': true,
        'share': true,
      });
      final item =
          (await firestore
                  .collection('lists')
                  .doc('local-list')
                  .collection('items')
                  .doc('item-0')
                  .get())
              .data()!;
      expect(item['name'], 'Milk 0');
      expect(item['quantity'], '2');
      expect(item['completed'], false);
      expect(item['listItemType'], 'haveAtHome');
      expect(item['createdBy'], 'owner');
      expect(
        (await firestore.collection('users').doc('owner').get())
            .data()!['listIds'],
        ['local-list'],
      );
    },
  );

  test('retry uploads missing items without overwriting cloud edits', () async {
    await upload(list());
    final doc = firestore.collection('lists').doc('local-list');
    await doc.update({'name': 'Cloud name'});
    await doc.collection('items').doc('item-0').update({'name': 'Cloud milk'});
    expect(await upload(list(itemCount: 2)), 'local-list');
    expect((await doc.get()).data()!['name'], 'Cloud name');
    expect(
      (await doc.collection('items').doc('item-0').get()).data()!['name'],
      'Cloud milk',
    );
    expect((await doc.collection('items').get()).docs, hasLength(2));
    expect(
      (await firestore.collection('users').doc('owner').get())
          .data()!['listIds'],
      ['local-list'],
    );
  });

  test('refuses to overwrite a list owned by another user', () async {
    final doc = firestore.collection('lists').doc('local-list');
    await doc.set({'ownerId': 'someone-else', 'name': 'Private'});
    expect(await upload(list()), isNull);
    expect((await doc.get()).data()!['name'], 'Private');
    expect((await doc.collection('items').get()).docs, isEmpty);
    expect(
      (await firestore.collection('users').doc('owner').get())
          .data()!['listIds'],
      isEmpty,
    );
  });

  test('creates an empty list without a pending item batch', () async {
    expect(await upload(list(itemCount: 0)), 'local-list');
    expect(
      (await firestore
              .collection('lists')
              .doc('local-list')
              .collection('items')
              .get())
          .docs,
      isEmpty,
    );
  });

  test(
    'uploads multiple batches and retries without duplicating items',
    () async {
      final value = list(itemCount: 451);
      expect(await upload(value), 'local-list');
      expect(await upload(value), 'local-list');
      final items = await firestore
          .collection('lists')
          .doc('local-list')
          .collection('items')
          .get();
      expect(items.docs, hasLength(451));
      expect(items.docs.map((doc) => doc.id).toSet(), hasLength(451));
    },
  );

  test('does not treat other read failures as a missing document', () async {
    whenCalling(Invocation.method(#get, null))
        .on(firestore.collection('lists').doc('local-list'))
        .thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
    expect(await upload(list()), isNull);
    expect(firestore.dump(), isNot(contains('Groceries')));
    expect(
      (await firestore.collection('users').doc('owner').get())
          .data()!['listIds'],
      isEmpty,
    );
  });

  test('returns null on unexpected upload errors', () async {
    whenCalling(Invocation.method(#get, null))
        .on(firestore.collection('lists').doc('local-list'))
        .thenThrow(Exception('Unexpected read failure'));
    expect(await upload(list()), isNull);
    expect(firestore.dump(), isNot(contains('Groceries')));
    expect(
      (await firestore.collection('users').doc('owner').get())
          .data()!['listIds'],
      isEmpty,
    );
  });

  test(
    'retry recovers when the previous upload could not register the list',
    () async {
      await firestore.collection('users').doc('owner').delete();
      expect(await upload(list()), isNull);
      final doc = firestore.collection('lists').doc('local-list');
      expect((await doc.get()).exists, isTrue);
      await doc.collection('items').doc('item-0').update({
        'name': 'Cloud edit',
      });
      await firestore.collection('users').doc('owner').set({'listIds': []});
      expect(await upload(list()), 'local-list');
      expect(
        (await doc.collection('items').doc('item-0').get()).data()!['name'],
        'Cloud edit',
      );
      expect(
        (await firestore.collection('users').doc('owner').get())
            .data()!['listIds'],
        ['local-list'],
      );
    },
  );

  test('creates after a denied read of a not-yet-created document', () async {
    whenCalling(Invocation.method(#get, null))
        .on(firestore.collection('lists').doc('local-list'))
        .thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
    expect(await upload(list(itemCount: 0)), 'local-list');
    expect(
      (await firestore.collection('users').doc('owner').get())
          .data()!['listIds'],
      ['local-list'],
    );
  });
}
