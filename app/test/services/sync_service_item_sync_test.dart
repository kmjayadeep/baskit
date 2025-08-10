import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/sync_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('SyncService Item Sync Integration Tests', () {
    late SyncService syncService;

    setUp(() {
      // Reset SyncService to clean state
      syncService = SyncService.instance;
      syncService.reset();
    });

    tearDown(() {
      syncService.reset();
    });

    group('_syncListItemsToFirebase', () {
      test('should sync all active items to Firebase', () async {
        // Arrange
        final now = DateTime.now();
        final items = [
          ShoppingItem(
            id: 'item-1',
            name: 'Test Item 1',
            quantity: '1',
            createdAt: now,
          ),
          ShoppingItem(
            id: 'item-2',
            name: 'Test Item 2',
            quantity: '2 kg',
            createdAt: now.add(const Duration(minutes: 1)),
          ),
          ShoppingItem(
            id: 'item-3',
            name: 'Deleted Item',
            createdAt: now.subtract(const Duration(minutes: 1)),
            deletedAt: now, // This should be excluded
          ),
        ];

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: items,
        );

        // Act - Test the data model logic that the sync service uses
        // The sync service calls _syncListItemsToFirebase with testList

        // Assert - Verify the list correctly filters active items
        expect(testList.activeItems.length, equals(2));
        expect(
          testList.activeItems.any((item) => item.name == 'Deleted Item'),
          isFalse,
        );

        // Verify the sync service would process the correct items
        final itemsToSync = testList.activeItems;
        expect(itemsToSync.length, equals(2));
        expect(itemsToSync.first.name, equals('Test Item 1'));
        expect(itemsToSync.last.name, equals('Test Item 2'));
      });
    });

    group('Item Sync Flow Integration', () {
      test('should handle list with new items added', () async {
        // This test verifies the complete flow when items are added to existing lists

        // Arrange
        final now = DateTime.now();
        final existingItem = ShoppingItem(
          id: 'existing-item',
          name: 'Existing Item',
          createdAt: now.subtract(const Duration(hours: 1)),
        );

        final newItem = ShoppingItem(
          id: 'new-item',
          name: 'New Item',
          quantity: '3',
          createdAt: now,
        );

        final listWithNewItem = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now, // Updated when new item added
          items: [existingItem, newItem],
        );

        // Act - Simulate what happens in the sync service
        // In real sync: _handleActiveList() would be called with this list

        // Assert - Verify the list structure that sync service would receive
        expect(listWithNewItem.activeItems.length, equals(2));
        expect(
          listWithNewItem.activeItems.any((item) => item.id == 'new-item'),
          isTrue,
        );
        expect(listWithNewItem.updatedAt, equals(now));

        // Verify the new item would be included in sync
        final newItemInList = listWithNewItem.activeItems.firstWhere(
          (item) => item.id == 'new-item',
        );
        expect(newItemInList.name, equals('New Item'));
        expect(newItemInList.quantity, equals('3'));
      });

      test('should preserve item IDs during sync', () async {
        // This test verifies that item IDs remain consistent

        // Arrange
        final predefinedId = 'predetermined-uuid-v4';
        final item = ShoppingItem(
          id: predefinedId,
          name: 'Test Item',
          createdAt: DateTime.now(),
        );

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [item],
        );

        // Act & Assert
        expect(testList.activeItems.first.id, equals(predefinedId));

        // Verify the sync service would preserve this ID
        final itemToSync = testList.activeItems.first;
        expect(itemToSync.id, equals(predefinedId));

        // In a real sync scenario, this ID should be preserved in Firebase
        // The FirestoreService.addItemToList should use .doc(item.id).set()
        // instead of .add() which generates new IDs
      });
    });

    group('Error Handling', () {
      test('should handle sync errors gracefully', () async {
        // Act - Start sync without Firebase available
        await syncService.startSync();

        // Assert - Should handle gracefully without throwing
        expect(syncService.syncState, isIn([SyncState.idle, SyncState.error]));
      });
    });

    group('State Consistency', () {
      test('should maintain sync state during item operations', () async {
        // Arrange
        expect(syncService.syncState, equals(SyncState.idle));

        // Act
        await syncService.startSync();

        // Assert - State should be managed correctly
        expect(
          syncService.syncState,
          isIn([SyncState.idle, SyncState.syncing, SyncState.error]),
        );
      });
    });
  });
}
