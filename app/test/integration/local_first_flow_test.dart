import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/services/storage_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('Local-First Flow Integration Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing with temporary directory
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_integration_test',
      );
      Hive.init(tempDir.path);

      // Register type adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() async {
      // Reset SharedPreferences with empty values (for migration tests)
      SharedPreferences.setMockInitialValues({});

      // Reset the StorageService singleton
      StorageService.resetInstanceForTest();

      // Get fresh instance
      storageService = StorageService.instance;

      // Initialize the service
      await storageService.init();
    });

    tearDown(() async {
      // Clear all data and reset instance
      await storageService.clearLocalDataForTest();
      StorageService.resetInstanceForTest();

      // Close and delete Hive boxes for clean test state
      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (e) {
        // Box might not exist, that's okay
      }
    });

    tearDownAll(() async {
      // Clean up Hive completely
      try {
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('Complete User Journey', () {
      test(
        'FLOW 1: Create lists offline → Login → Migration → Logout → Fresh start',
        () async {
          // ========== PHASE 1: Anonymous User Creates Lists Locally ==========
          debugPrint('📱 PHASE 1: Anonymous user creates lists locally');

          // Create multiple lists with items
          final now = DateTime.now();
          final list1 = ShoppingList(
            id: 'offline-list-1',
            name: 'Grocery List',
            description: 'Weekly groceries',
            color: '#FF0000',
            createdAt: now,
            updatedAt: now,
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Milk',
                quantity: '2 gallons',
                isCompleted: false,
                createdAt: now,
              ),
              ShoppingItem(
                id: 'item-2',
                name: 'Bread',
                quantity: '1 loaf',
                isCompleted: true,
                createdAt: now,
              ),
            ],
            members: [],
          );

          final list2 = ShoppingList(
            id: 'offline-list-2',
            name: 'Hardware Store',
            description: 'Home improvement items',
            color: '#00FF00',
            createdAt: now.add(const Duration(seconds: 1)),
            updatedAt: now.add(const Duration(seconds: 1)),
            items: [
              ShoppingItem(
                id: 'item-3',
                name: 'Screws',
                quantity: '1 box',
                isCompleted: false,
                createdAt: now.add(const Duration(seconds: 1)),
              ),
            ],
            members: [],
          );

          // Save lists locally (simulating anonymous user behavior)
          await storageService.saveListLocallyForTest(list1);
          await storageService.saveListLocallyForTest(list2);

          // Verify lists are stored locally
          final localLists = await storageService.getAllListsLocallyForTest();
          expect(localLists.length, equals(2));
          expect(
            localLists.first.items.length,
            equals(1),
          ); // list2 has 1 item (most recent)
          expect(
            localLists.last.items.length,
            equals(2),
          ); // list1 has 2 items (older)

          debugPrint('✅ Created 2 lists locally with items');

          // ========== PHASE 2: Simulate Migration on Login ==========
          debugPrint('📱 PHASE 2: User logs in, data should be migrated');

          // Check migration status before migration
          expect(
            await storageService.isMigrationCompleteForTest(),
            isTrue,
          ); // Anonymous users don't need migration

          // Simulate the migration process that would happen on login
          // (In real scenario, this would happen automatically in _ensureMigrationComplete)
          final listsToMigrate =
              await storageService.getAllListsLocallyForTest();
          expect(listsToMigrate.length, equals(2));

          // Mark migration as complete (simulating successful Firebase migration)
          await storageService.markMigrationCompleteForTest();

          // Clear local data after migration (simulating _clearLocalData after migration)
          await storageService.clearLocalDataForTest();

          // Verify local data is cleared after migration
          final listsAfterMigration =
              await storageService.getAllListsLocallyForTest();
          expect(listsAfterMigration.length, equals(0));

          debugPrint('✅ Migration completed, local data cleared');

          // ========== PHASE 3: Simulate Logout and Data Cleanup ==========
          debugPrint(
            '📱 PHASE 3: User logs out, all data should be cleaned up',
          );

          // Add some data that might exist in local cache (simulating Firebase offline cache)
          await storageService.saveListLocallyForTest(
            ShoppingList(
              id: 'cached-list',
              name: 'Cached List',
              description: 'From Firebase cache',
              color: '#0000FF',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              items: [],
              members: ['user@example.com'],
            ),
          );

          // Verify data exists before logout
          expect(
            (await storageService.getAllListsLocallyForTest()).length,
            equals(1),
          );

          // Simulate logout cleanup
          await storageService.clearUserData();

          // Verify all local data is cleaned up
          final listsAfterLogout =
              await storageService.getAllListsLocallyForTest();
          expect(listsAfterLogout.length, equals(0));

          debugPrint('✅ Logout cleanup completed');

          // ========== PHASE 4: Fresh Start After Logout ==========
          debugPrint(
            '📱 PHASE 4: Fresh start - user can create new lists or login again',
          );

          // User should be able to create new lists locally again
          final newOfflineList = ShoppingList(
            id: 'new-offline-list',
            name: 'Fresh Start List',
            description: 'New list after logout',
            color: '#FF00FF',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            members: [],
          );

          await storageService.saveListLocallyForTest(newOfflineList);

          // Verify new list is created
          final freshLists = await storageService.getAllListsLocallyForTest();
          expect(freshLists.length, equals(1));
          expect(freshLists.first.name, equals('Fresh Start List'));

          debugPrint('✅ Fresh start verified - user can create new lists');

          debugPrint('🎉 Complete local-first flow test passed!');
        },
      );

      test('FLOW 2: Data persistence and recovery', () async {
        debugPrint('📱 Testing data persistence and recovery scenarios');

        // Create test data
        final testList = ShoppingList(
          id: 'persistence-test',
          name: 'Persistence Test',
          description: 'Testing data persistence',
          color: '#123456',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [
            ShoppingItem(
              id: 'persist-item-1',
              name: 'Persistent Item',
              quantity: '1',
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          ],
          members: [],
        );

        // Save and verify persistence
        await storageService.saveListLocallyForTest(testList);
        var storedLists = await storageService.getAllListsLocallyForTest();
        expect(storedLists.length, equals(1));
        expect(storedLists.first.id, equals('persistence-test'));

        // Test item operations persistence
        // Add item
        final newItem = ShoppingItem(
          id: 'persist-item-2',
          name: 'Added Item',
          quantity: '2',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await storageService.addItemToLocalListForTest(
          'persistence-test',
          newItem,
        );
        var updatedList = await storageService.getListByIdLocallyForTest(
          'persistence-test',
        );
        expect(updatedList!.items.length, equals(2));

        // Update item (mark as completed)
        await storageService.updateItemInLocalListForTest(
          'persistence-test',
          'persist-item-1',
          name: 'Updated Persistent Item',
          isCompleted: true,
        );

        updatedList = await storageService.getListByIdLocallyForTest(
          'persistence-test',
        );
        // With new sorting: incomplete items first, completed items last
        // So 'Added Item' (incomplete) should be first, 'Updated Persistent Item' (completed) should be last
        expect(updatedList!.items.length, equals(2));
        expect(updatedList.items.first.name, equals('Added Item'));
        expect(updatedList.items.first.isCompleted, isFalse);
        expect(updatedList.items.last.name, equals('Updated Persistent Item'));
        expect(updatedList.items.last.isCompleted, isTrue);

        // Delete item
        await storageService.deleteItemFromLocalListForTest(
          'persistence-test',
          'persist-item-2',
        );
        updatedList = await storageService.getListByIdLocallyForTest(
          'persistence-test',
        );
        expect(updatedList!.items.length, equals(1));

        debugPrint('✅ Data persistence and recovery test passed');
      });

      test('FLOW 3: Edge cases and error handling', () async {
        debugPrint('📱 Testing edge cases and error handling');

        // Test operations on non-existent data
        final nonExistentList = await storageService.getListByIdLocallyForTest(
          'does-not-exist',
        );
        expect(nonExistentList, isNull);

        final updateResult = await storageService.updateItemInLocalListForTest(
          'does-not-exist',
          'item-does-not-exist',
          name: 'Test',
        );
        expect(updateResult, isFalse);

        final deleteResult = await storageService
            .deleteItemFromLocalListForTest(
              'does-not-exist',
              'item-does-not-exist',
            );
        expect(deleteResult, isFalse);

        final addResult = await storageService.addItemToLocalListForTest(
          'does-not-exist',
          ShoppingItem(
            id: 'test-item',
            name: 'Test Item',
            quantity: '1',
            isCompleted: false,
            createdAt: DateTime.now(),
          ),
        );
        expect(addResult, isFalse);

        // Test empty data scenarios
        final emptyLists = await storageService.getAllListsLocallyForTest();
        expect(emptyLists, isEmpty);

        // Test multiple cleanup operations
        await storageService.clearLocalDataForTest();
        await storageService.clearUserData();
        final stillEmpty = await storageService.getAllListsLocallyForTest();
        expect(stillEmpty, isEmpty);

        debugPrint('✅ Edge cases and error handling test passed');
      });

      test('FLOW 4: Migration tracking and user separation', () async {
        debugPrint('📱 Testing migration tracking and user separation');

        // Test initial migration state
        expect(
          await storageService.isMigrationCompleteForTest(),
          isTrue,
        ); // Anonymous users

        // Test setting migration complete
        await storageService.markMigrationCompleteForTest();
        expect(await storageService.isMigrationCompleteForTest(), isTrue);

        // Create some data
        final testList = ShoppingList(
          id: 'migration-test',
          name: 'Migration Test List',
          description: 'Testing migration logic',
          color: '#ABCDEF',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.saveListLocallyForTest(testList);
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Test data cleanup
        await storageService.clearUserData();
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(0),
        );

        debugPrint('✅ Migration tracking and user separation test passed');
      });
    });

    group('Performance and Reliability Tests', () {
      test('should handle large amounts of data efficiently', () async {
        debugPrint('📱 Testing performance with large data sets');

        // Create a list with many items
        final largeList = ShoppingList(
          id: 'large-list',
          name: 'Large Shopping List',
          description: 'List with many items',
          color: '#FF8800',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: List.generate(
            100,
            (index) => ShoppingItem(
              id: 'item-$index',
              name: 'Item $index',
              quantity: '${index + 1}',
              isCompleted: index % 2 == 0,
              createdAt: DateTime.now(),
            ),
          ),
          members: [],
        );

        // Test saving and retrieving large list
        final startTime = DateTime.now();
        await storageService.saveListLocallyForTest(largeList);
        final saveTime = DateTime.now().difference(startTime);

        final retrieveStartTime = DateTime.now();
        final retrievedList = await storageService.getListByIdLocallyForTest(
          'large-list',
        );
        final retrieveTime = DateTime.now().difference(retrieveStartTime);

        // Verify data integrity
        expect(retrievedList, isNotNull);
        expect(retrievedList!.items.length, equals(100));

        // With new sorting: incomplete items (odd indices) first, completed items (even indices) last
        // First item should be an incomplete item (odd index)
        expect(retrievedList.items.first.isCompleted, isFalse);
        expect(retrievedList.items.first.name.startsWith('Item '), isTrue);

        // Last item should be a completed item (even index)
        expect(retrievedList.items.last.isCompleted, isTrue);
        expect(retrievedList.items.last.name.startsWith('Item '), isTrue);

        // Verify we have the right split: 50 incomplete, 50 completed
        final incompleteCount =
            retrievedList.items.where((item) => !item.isCompleted).length;
        final completedCount =
            retrievedList.items.where((item) => item.isCompleted).length;
        expect(incompleteCount, equals(50));
        expect(completedCount, equals(50));

        // Performance should be reasonable (adjust thresholds as needed)
        expect(
          saveTime.inMilliseconds,
          lessThan(1000),
        ); // Should save in under 1 second
        expect(
          retrieveTime.inMilliseconds,
          lessThan(500),
        ); // Should retrieve in under 0.5 seconds

        debugPrint(
          '✅ Performance test passed: Save=${saveTime.inMilliseconds}ms, Retrieve=${retrieveTime.inMilliseconds}ms',
        );
      });

      test('should handle JSON corruption gracefully', () async {
        debugPrint('📱 Testing JSON corruption handling');

        // Manually corrupt the JSON in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'shopping_lists',
          '{"invalid": json, "structure"}',
        );

        // Should return empty list instead of crashing
        final lists = await storageService.getAllListsLocallyForTest();
        expect(lists, isEmpty);

        // Should be able to save new data after corruption
        final testList = ShoppingList(
          id: 'recovery-test',
          name: 'Recovery Test',
          description: 'Testing recovery from corruption',
          color: '#RECOVERED',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.saveListLocallyForTest(testList);
        final recoveredLists = await storageService.getAllListsLocallyForTest();
        expect(recoveredLists.length, equals(1));
        expect(recoveredLists.first.name, equals('Recovery Test'));

        debugPrint('✅ JSON corruption handling test passed');
      });
    });

    group('Item Sync Flow Integration', () {
      test('should maintain item ID consistency throughout the flow', () async {
        // This test verifies the complete item addition -> sync flow
        // that was missing and caused the item sync bug

        debugPrint('🧪 Testing item ID consistency flow...');

        // Step 1: Create a list with initial items
        final now = DateTime.now();
        final initialItem = ShoppingItem(
          id: 'initial-item-uuid',
          name: 'Initial Item',
          quantity: '1',
          createdAt: now.subtract(const Duration(minutes: 5)),
        );

        final testList = ShoppingList(
          id: 'consistency-test-list',
          name: 'ID Consistency Test',
          description: 'Testing item ID consistency',
          color: '#00FF00',
          createdAt: now.subtract(const Duration(minutes: 10)),
          updatedAt: now.subtract(const Duration(minutes: 5)),
          items: [initialItem],
        );

        // Step 2: Save list locally
        final createSuccess = await storageService.createList(testList);
        expect(createSuccess, isTrue);

        // Step 3: Add a new item (simulating user action)
        final newItemId = 'new-item-predetermined-uuid';
        final newItem = ShoppingItem(
          id: newItemId,
          name: 'Newly Added Item',
          quantity: '2 kg',
          createdAt: now,
        );

        final addItemSuccess = await storageService.addItem(
          testList.id,
          newItem,
        );
        expect(addItemSuccess, isTrue);

        // Step 4: Verify local storage has both items with correct IDs
        final updatedLists = await storageService.getAllListsLocallyForTest();
        expect(updatedLists.length, equals(1));

        final updatedList = updatedLists.first;
        expect(updatedList.items.length, equals(2));

        // Verify original item ID preserved
        final originalItem = updatedList.items.firstWhere(
          (item) => item.id == 'initial-item-uuid',
        );
        expect(originalItem.name, equals('Initial Item'));

        // Verify new item has predetermined ID
        final addedItem = updatedList.items.firstWhere(
          (item) => item.id == newItemId,
        );
        expect(addedItem.name, equals('Newly Added Item'));
        expect(addedItem.quantity, equals('2 kg'));

        debugPrint('✅ Item ID consistency test passed');
      });

      test('should handle item updates without changing IDs', () async {
        debugPrint('🧪 Testing item update ID preservation...');

        // Step 1: Create list with item
        final now = DateTime.now();
        final originalItem = ShoppingItem(
          id: 'update-test-item-id',
          name: 'Original Name',
          quantity: '1',
          isCompleted: false,
          createdAt: now,
        );

        final testList = ShoppingList(
          id: 'update-test-list',
          name: 'Update Test List',
          description: 'Testing item updates',
          color: '#0000FF',
          createdAt: now,
          updatedAt: now,
          items: [originalItem],
        );

        await storageService.createList(testList);

        // Step 2: Update the item
        final updateSuccess = await storageService.updateItem(
          testList.id,
          originalItem.id,
          name: 'Updated Name',
          quantity: '2 kg',
          isCompleted: true,
        );
        expect(updateSuccess, isTrue);

        // Step 3: Verify ID preserved and properties updated
        final updatedLists = await storageService.getAllListsLocallyForTest();
        final updatedList = updatedLists.first;
        final updatedItem = updatedList.items.first;

        expect(updatedItem.id, equals('update-test-item-id')); // ID unchanged
        expect(updatedItem.name, equals('Updated Name'));
        expect(updatedItem.quantity, equals('2 kg'));
        expect(updatedItem.isCompleted, isTrue);

        debugPrint('✅ Item update ID preservation test passed');
      });

      test('should handle item deletion with proper cleanup', () async {
        debugPrint('🧪 Testing item deletion flow...');

        // Step 1: Create list with multiple items
        final now = DateTime.now();
        final items = [
          ShoppingItem(
            id: 'keep-item-id',
            name: 'Keep This Item',
            createdAt: now,
          ),
          ShoppingItem(
            id: 'delete-item-id',
            name: 'Delete This Item',
            createdAt: now.add(const Duration(minutes: 1)),
          ),
        ];

        final testList = ShoppingList(
          id: 'deletion-test-list',
          name: 'Deletion Test List',
          description: 'Testing item deletion',
          color: '#FF00FF',
          createdAt: now,
          updatedAt: now,
          items: items,
        );

        await storageService.createList(testList);

        // Step 2: Delete one item
        final deleteSuccess = await storageService.deleteItem(
          testList.id,
          'delete-item-id',
        );
        expect(deleteSuccess, isTrue);

        // Step 3: Verify only active items remain
        final updatedLists = await storageService.getAllListsLocallyForTest();
        final updatedList = updatedLists.first;

        expect(updatedList.activeItems.length, equals(1));
        expect(updatedList.activeItems.first.id, equals('keep-item-id'));
        expect(updatedList.activeItems.first.name, equals('Keep This Item'));

        // Step 4: Verify deleted item is soft-deleted (still in items but marked)
        expect(updatedList.items.length, equals(2)); // Both items still exist
        final deletedItem = updatedList.items.firstWhere(
          (item) => item.id == 'delete-item-id',
        );
        expect(deletedItem.deletedAt, isNotNull); // Marked as deleted

        debugPrint('✅ Item deletion flow test passed');
      });

      test('should simulate complete user item addition workflow', () async {
        debugPrint('🧪 Testing complete user item addition workflow...');

        // This test simulates the exact flow that happens when a user adds an item
        // in the UI, which was the scenario that revealed the sync bug

        // Step 1: User creates a new list (like in CreateListScreen)
        final now = DateTime.now();
        final userList = ShoppingList(
          id: 'user-workflow-list',
          name: 'My Shopping List',
          description: 'Weekly groceries',
          color: '#4CAF50',
          createdAt: now,
          updatedAt: now,
        );

        final listCreated = await storageService.createList(userList);
        expect(listCreated, isTrue);

        // Step 2: User adds first item (like in ListDetailScreen._addItem)
        final firstItemId = 'first-item-uuid-v4';
        final firstItem = ShoppingItem(
          id: firstItemId,
          name: 'Milk',
          quantity: '1 gallon',
          createdAt: now.add(const Duration(minutes: 1)),
        );

        final firstItemAdded = await storageService.addItem(
          userList.id,
          firstItem,
        );
        expect(firstItemAdded, isTrue);

        // Step 3: User adds second item
        final secondItemId = 'second-item-uuid-v4';
        final secondItem = ShoppingItem(
          id: secondItemId,
          name: 'Bread',
          quantity: '2 loaves',
          createdAt: now.add(const Duration(minutes: 2)),
        );

        final secondItemAdded = await storageService.addItem(
          userList.id,
          secondItem,
        );
        expect(secondItemAdded, isTrue);

        // Step 4: User toggles completion of first item
        final toggleSuccess = await storageService.updateItem(
          userList.id,
          firstItemId,
          isCompleted: true,
        );
        expect(toggleSuccess, isTrue);

        // Step 5: Verify final state matches expected user experience
        final finalLists = await storageService.getAllListsLocallyForTest();
        expect(finalLists.length, equals(1));

        final finalList = finalLists.first;
        expect(finalList.items.length, equals(2));
        expect(finalList.activeItems.length, equals(2));

        // Verify first item (completed)
        final milkItem = finalList.items.firstWhere(
          (item) => item.id == firstItemId,
        );
        expect(milkItem.name, equals('Milk'));
        expect(milkItem.quantity, equals('1 gallon'));
        expect(milkItem.isCompleted, isTrue);

        // Verify second item (not completed)
        final breadItem = finalList.items.firstWhere(
          (item) => item.id == secondItemId,
        );
        expect(breadItem.name, equals('Bread'));
        expect(breadItem.quantity, equals('2 loaves'));
        expect(breadItem.isCompleted, isFalse);

        debugPrint('✅ Complete user workflow test passed');

        // NOTE: In a real sync scenario, this updated list would trigger
        // SyncService._handleActiveList() which would call
        // FirestoreService.createList() (fails if exists) ->
        // FirestoreService.updateList() (metadata only) ->
        // SyncService._syncListItemsToFirebase() (sync all items)
        //
        // The bug was that _syncListItemsToFirebase() didn't exist,
        // so items were never synced to Firebase after initial list creation.
      });
    });
  });
}
