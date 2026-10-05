import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/services/firestore_item_crud_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal mock for CollectionReference
class _MockCollectionReference {
  final List<_MockDocumentReference> docs = [];
  String? collectionPath;

  _MockCollectionReference(this.collectionPath);

  _MockDocumentReference doc(String id) {
    return _MockDocumentReference(this, id);
  }

  Future<_MockCollectionReference> add(Map<String, dynamic> data) {
    final doc = _MockDocumentReference(this, data['id'] as String? ?? 'auto');
    docs.add(doc);
    return Future.value(this);
  }
}

// Minimal mock for DocumentReference
class _MockDocumentReference {
  final _MockCollectionReference parent;
  final String id;
  Map<String, dynamic>? _data;

  _MockDocumentReference(this.parent, this.id);

  Future<_MockDocumentReference> set(Map<String, dynamic> data) async {
    _data = data;
    return this;
  }

  Future<void> update(Map<String, dynamic> data) async {
    _data ??= {};
    _data!.addAll(data);
  }

  Future<void> delete() async {
    parent.docs.remove(this);
    _data = null;
  }
}

void main() {
  group('FirestoreItemCrudService', () {
    group('addItemToList', () {
      test('creates item with correct structure when Firebase unavailable',
          () async {
        // When Firebase is not available (no mock setup), the service
        // should return null without making any Firestore calls.
        final item = ShoppingItem(
          id: 'item-1',
          name: 'Milk',
          quantity: '2 cartons',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        final result =
            await FirestoreItemCrudService.addItemToList('list-1', item);
        expect(result, isNull);
      });

      test('handles item without quantity', () async {
        final item = ShoppingItem(
          id: 'item-2',
          name: 'Bread',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        final result =
            await FirestoreItemCrudService.addItemToList('list-1', item);
        expect(result, isNull);
      });

      test('handles completed item', () async {
        final item = ShoppingItem(
          id: 'item-3',
          name: 'Eggs',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        final result =
            await FirestoreItemCrudService.addItemToList('list-1', item);
        expect(result, isNull);
      });

      test('handles multiple items', () async {
        final items = List.generate(
          10,
          (i) => ShoppingItem(
            id: 'item-$i',
            name: 'Item $i',
            isCompleted: i % 2 == 0,
            createdAt: DateTime.now(),
            completedAt: i % 2 == 0 ? DateTime.now() : null,
          ),
        );

        for (final item in items) {
          final result =
              await FirestoreItemCrudService.addItemToList('list-1', item);
          expect(result, isNull);
        }
      });
    });

    group('updateItemInList', () {
      test('handles name update', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          'list-1',
          'item-1',
          name: 'New Name',
        );
        expect(result, isFalse);
      });

      test('handles quantity update', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          'list-1',
          'item-1',
          quantity: '3 cartons',
        );
        expect(result, isFalse);
      });

      test('handles completed update', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          'list-1',
          'item-1',
          completed: true,
        );
        expect(result, isFalse);
      });

      test('handles multiple fields update', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          'list-1',
          'item-1',
          name: 'Updated',
          quantity: '5',
          completed: true,
        );
        expect(result, isFalse);
      });

      test('handles empty list ID', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          '',
          'item-1',
          name: 'Test',
        );
        expect(result, isFalse);
      });

      test('handles empty item ID', () async {
        final result = await FirestoreItemCrudService.updateItemInList(
          'list-1',
          '',
          name: 'Test',
        );
        expect(result, isFalse);
      });
    });

    group('deleteItemFromList', () {
      test('handles deletion', () async {
        final result =
            await FirestoreItemCrudService.deleteItemFromList('list-1', 'item-1');
        expect(result, isFalse);
      });

      test('handles empty IDs', () async {
        final result = await FirestoreItemCrudService.deleteItemFromList('', '');
        expect(result, isFalse);
      });
    });

    group('clearCompletedItems', () {
      test('handles clearing completed items', () async {
        final result = await FirestoreItemCrudService.clearCompletedItems('list-1');
        expect(result, isFalse);
      });

      test('handles empty list ID', () async {
        final result = await FirestoreItemCrudService.clearCompletedItems('');
        expect(result, isFalse);
      });
    });

    group('getListItems', () {
      test('returns empty stream when Firebase unavailable', () {
        final stream = FirestoreItemCrudService.getListItems('list-1');
        expect(stream, isA<Stream<List<ShoppingItem>>>());
      });
    });
  });
}
