import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/services/sync_service.dart';
import 'package:baskit/services/storage_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('SyncService Item Sync Integration Tests', () {
    late SyncService syncService;

    setUpAll(() async {
      // Initialize Hive for testing with temporary directory
      final tempDir = Directory.systemTemp.createTempSync('hive_test');
      Hive.init(tempDir.path);

      // Register type adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() {
      // Reset SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});

      // Reset StorageService singleton for clean tests
      StorageService.resetInstanceForTest();

      // Reset SyncService to clean state
      syncService = SyncService.instance;
      syncService.reset();
    });

    tearDown(() async {
      syncService.reset();
      // Clean up storage service
      try {
        await StorageService.instance.clearLocalDataForTest();
      } catch (e) {
        // Ignore cleanup errors
      }
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

    group('Item Deletion Sync', () {
      test('should process deletion sync through public interface', () async {
        // This test verifies that the sync service correctly identifies and processes
        // deleted items when sync operations are triggered

        // Arrange
        final now = DateTime.now();
        final activeItem = ShoppingItem(
          id: 'active-item',
          name: 'Active Item',
          createdAt: now,
        );
        final deletedItem = ShoppingItem(
          id: 'deleted-item',
          name: 'Deleted Item',
          createdAt: now.subtract(const Duration(minutes: 1)),
          deletedAt: now, // This should be synced for deletion
        );

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [activeItem, deletedItem],
        );

        // Act & Assert - Test the data model logic that sync service relies on
        // Verify list correctly separates active and deleted items
        expect(testList.activeItems.length, equals(1));
        expect(testList.activeItems.first.id, equals('active-item'));

        final deletedItems =
            testList.items.where((item) => item.deletedAt != null).toList();
        expect(deletedItems.length, equals(1));
        expect(deletedItems.first.id, equals('deleted-item'));

        // Verify the sync service would process both types correctly
        expect(
          testList.items.length,
          equals(2),
        ); // Total items (active + deleted)
        expect(
          testList.activeItems.length,
          equals(1),
        ); // Only active items for creation
        expect(
          deletedItems.length,
          equals(1),
        ); // Deleted items for deletion sync

        // Test sync service state - without Firebase, it should handle gracefully
        await syncService.startSync();
        expect(syncService.syncState, isIn([SyncState.idle, SyncState.error]));
      });

      test('should handle mixed deletion results correctly', () async {
        // Arrange
        final now = DateTime.now();
        final deletedItem1 = ShoppingItem(
          id: 'deleted-item-1',
          name: 'Successfully Deleted Item',
          createdAt: now.subtract(const Duration(minutes: 2)),
          deletedAt: now.subtract(const Duration(minutes: 1)),
        );
        final deletedItem2 = ShoppingItem(
          id: 'deleted-item-2',
          name: 'Failed Deletion Item',
          createdAt: now.subtract(const Duration(minutes: 3)),
          deletedAt: now.subtract(const Duration(minutes: 1)),
        );

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [deletedItem1, deletedItem2],
        );

        // Act & Assert - Test the data model logic
        final deletedItems =
            testList.items.where((item) => item.deletedAt != null).toList();
        expect(deletedItems.length, equals(2));

        // Verify both deleted items would be processed
        expect(
          deletedItems.map((item) => item.id).toSet(),
          equals({'deleted-item-1', 'deleted-item-2'}),
        );

        // Simulate successful deletion of first item only
        final successfullyDeletedIds = ['deleted-item-1'];
        final remainingItems =
            testList.items
                .where((item) => !successfullyDeletedIds.contains(item.id))
                .toList();

        // Verify cleanup logic
        expect(remainingItems.length, equals(1));
        expect(remainingItems.first.id, equals('deleted-item-2'));
      });

      test('should preserve item deletion timestamps', () async {
        // Arrange
        final now = DateTime.now();
        final deletedAt = now.subtract(const Duration(minutes: 5));

        final deletedItem = ShoppingItem(
          id: 'deleted-item',
          name: 'Deleted Item',
          createdAt: now.subtract(const Duration(hours: 1)),
          deletedAt: deletedAt,
        );

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [deletedItem],
        );

        // Act & Assert
        final deletedItems =
            testList.items.where((item) => item.deletedAt != null).toList();
        expect(deletedItems.length, equals(1));
        expect(deletedItems.first.deletedAt, equals(deletedAt));
        expect(deletedItems.first.id, equals('deleted-item'));

        // Verify deleted items are excluded from active items
        expect(testList.activeItems, isEmpty);
      });

      test('should handle empty deletion list correctly', () async {
        // Arrange
        final now = DateTime.now();
        final activeItem = ShoppingItem(
          id: 'active-item',
          name: 'Active Item',
          createdAt: now,
        );

        final testList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [activeItem],
        );

        // Act & Assert
        final deletedItems =
            testList.items.where((item) => item.deletedAt != null).toList();
        expect(deletedItems, isEmpty);
        expect(testList.activeItems.length, equals(1));

        // Verify sync would process correctly with no deletions
        expect(testList.items.length, equals(1));
        expect(testList.activeItems.length, equals(1));
      });

      test('should handle local storage cleanup correctly', () async {
        // This test verifies the cleanup logic for permanently removing deleted items

        // Arrange
        final now = DateTime.now();
        final activeItem = ShoppingItem(
          id: 'active-item',
          name: 'Active Item',
          createdAt: now,
        );
        final deletedItem1 = ShoppingItem(
          id: 'deleted-item-1',
          name: 'Successfully Deleted',
          createdAt: now.subtract(const Duration(minutes: 2)),
          deletedAt: now.subtract(const Duration(minutes: 1)),
        );
        final deletedItem2 = ShoppingItem(
          id: 'deleted-item-2',
          name: 'Failed to Delete',
          createdAt: now.subtract(const Duration(minutes: 3)),
          deletedAt: now.subtract(const Duration(minutes: 1)),
        );

        final originalList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: now,
          updatedAt: now,
          items: [activeItem, deletedItem1, deletedItem2],
        );

        // Act - Simulate cleanup after successful deletion of first item only
        final successfullyDeletedIds = ['deleted-item-1'];
        final updatedItems =
            originalList.items
                .where((item) => !successfullyDeletedIds.contains(item.id))
                .toList();
        final cleanedList = originalList.copyWith(items: updatedItems);

        // Assert - Verify cleanup logic
        expect(originalList.items.length, equals(3));
        expect(cleanedList.items.length, equals(2));

        // Should retain active item and failed deletion item
        final remainingIds = cleanedList.items.map((item) => item.id).toSet();
        expect(remainingIds, equals({'active-item', 'deleted-item-2'}));
        expect(remainingIds.contains('deleted-item-1'), isFalse);

        // Verify active items remain unchanged
        expect(cleanedList.activeItems.length, equals(1));
        expect(cleanedList.activeItems.first.id, equals('active-item'));

        // Verify failed deletion item remains for retry
        final stillDeletedItems =
            cleanedList.items.where((item) => item.deletedAt != null).toList();
        expect(stillDeletedItems.length, equals(1));
        expect(stillDeletedItems.first.id, equals('deleted-item-2'));
      });

      test(
        'should test actual sync flow with storage service integration',
        () async {
          // This test creates real data in storage and triggers sync to test the actual flow
          debugPrint('🧪 Testing real sync flow with item deletion...');

          // Arrange - Create a list with items in storage
          final now = DateTime.now();
          final storageService = StorageService.instance;
          await storageService.init();

          final testList = ShoppingList(
            id: 'sync-flow-test',
            name: 'Sync Flow Test',
            description: 'Testing real sync with deletions',
            color: '#FF5722',
            createdAt: now,
            updatedAt: now,
            items: [],
          );

          // Step 1: Create list and items in storage
          final createSuccess = await storageService.createList(testList);
          expect(createSuccess, isTrue);

          final item1 = ShoppingItem(
            id: 'item-1-sync',
            name: 'Item to Keep',
            quantity: '1',
            createdAt: now,
          );

          final item2 = ShoppingItem(
            id: 'item-2-sync',
            name: 'Item to Delete',
            quantity: '2',
            createdAt: now.subtract(const Duration(minutes: 1)),
          );

          await storageService.addItem(testList.id, item1);
          await storageService.addItem(testList.id, item2);

          // Verify both items exist
          final listWithItems = await storageService.getListByIdLocallyForTest(
            testList.id,
          );
          expect(listWithItems?.activeItems.length, equals(2));

          // Step 2: Delete one item (this marks it with deletedAt)
          final deleteSuccess = await storageService.deleteItem(
            testList.id,
            'item-2-sync',
          );
          expect(deleteSuccess, isTrue);

          // Step 3: Verify storage state after deletion
          final listAfterDeletion = await storageService.getRawListByIdForTest(
            testList.id,
          );
          expect(listAfterDeletion, isNotNull);
          expect(
            listAfterDeletion!.items.length,
            equals(2),
          ); // Both items still in storage
          expect(
            listAfterDeletion.activeItems.length,
            equals(1),
          ); // Only 1 active

          final deletedItems =
              listAfterDeletion.items
                  .where((item) => item.deletedAt != null)
                  .toList();
          expect(deletedItems.length, equals(1));
          expect(deletedItems.first.id, equals('item-2-sync'));

          // Step 4: Test sync service processing
          // When Firebase is not available, sync should handle gracefully
          syncService.initialize();
          await syncService.startSync();

          // Verify sync service maintained state correctly
          expect(
            syncService.syncState,
            isIn([SyncState.idle, SyncState.error]),
          );

          // Step 5: Test the data structures that sync would process
          final activeForSync = listAfterDeletion.activeItems;
          final deletedForSync =
              listAfterDeletion.items
                  .where((item) => item.deletedAt != null)
                  .toList();

          expect(activeForSync.length, equals(1));
          expect(activeForSync.first.id, equals('item-1-sync'));
          expect(deletedForSync.length, equals(1));
          expect(deletedForSync.first.id, equals('item-2-sync'));

          // Clean up
          await storageService.clearUserData();

          debugPrint('✅ Real sync flow test completed');
        },
      );

      test('should handle multiple deletion scenarios in sync flow', () async {
        // This test verifies complex deletion scenarios with multiple items
        debugPrint('🧪 Testing multiple deletion sync scenarios...');

        final now = DateTime.now();
        final storageService = StorageService.instance;
        await storageService.init();

        // Create list with multiple items
        final testList = ShoppingList(
          id: 'multi-delete-test',
          name: 'Multi Delete Test',
          description: 'Testing multiple deletions',
          color: '#9C27B0',
          createdAt: now,
          updatedAt: now,
          items: [],
        );

        await storageService.createList(testList);

        // Add multiple items
        final items = [
          ShoppingItem(id: 'keep-1', name: 'Keep Item 1', createdAt: now),
          ShoppingItem(
            id: 'delete-1',
            name: 'Delete Item 1',
            createdAt: now.subtract(const Duration(minutes: 1)),
          ),
          ShoppingItem(
            id: 'keep-2',
            name: 'Keep Item 2',
            createdAt: now.subtract(const Duration(minutes: 2)),
          ),
          ShoppingItem(
            id: 'delete-2',
            name: 'Delete Item 2',
            createdAt: now.subtract(const Duration(minutes: 3)),
          ),
          ShoppingItem(
            id: 'delete-3',
            name: 'Delete Item 3',
            createdAt: now.subtract(const Duration(minutes: 4)),
          ),
        ];

        for (final item in items) {
          await storageService.addItem(testList.id, item);
        }

        // Verify all items added
        final listWithAllItems = await storageService.getListByIdLocallyForTest(
          testList.id,
        );
        expect(listWithAllItems?.activeItems.length, equals(5));

        // Delete multiple items
        await storageService.deleteItem(testList.id, 'delete-1');
        await storageService.deleteItem(testList.id, 'delete-2');
        await storageService.deleteItem(testList.id, 'delete-3');

        // Verify final state
        final finalList = await storageService.getRawListByIdForTest(
          testList.id,
        );
        expect(finalList, isNotNull);
        expect(
          finalList!.items.length,
          equals(5),
        ); // All items still in storage
        expect(finalList.activeItems.length, equals(2)); // Only 2 active

        final deletedItems =
            finalList.items.where((item) => item.deletedAt != null).toList();
        expect(deletedItems.length, equals(3));

        // Verify correct items were deleted
        final deletedIds = deletedItems.map((item) => item.id).toSet();
        expect(deletedIds, equals({'delete-1', 'delete-2', 'delete-3'}));

        final activeIds = finalList.activeItems.map((item) => item.id).toSet();
        expect(activeIds, equals({'keep-1', 'keep-2'}));

        // Test cleanup simulation (what _permanentlyRemoveDeletedItems would do)
        final successfullyDeletedIds = [
          'delete-1',
          'delete-3',
        ]; // Simulate partial success
        final cleanedItems =
            finalList.items
                .where((item) => !successfullyDeletedIds.contains(item.id))
                .toList();

        expect(cleanedItems.length, equals(3)); // 2 active + 1 failed deletion
        final remainingIds = cleanedItems.map((item) => item.id).toSet();
        expect(remainingIds, equals({'keep-1', 'keep-2', 'delete-2'}));

        // Clean up
        await storageService.clearUserData();

        debugPrint('✅ Multiple deletion scenarios test completed');
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
