import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/services/storage_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('StorageService Simplified Interface Tests', () {
    late StorageService storageService;

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

    group('Anonymous User Local Storage Tests', () {
      test('should create list locally for anonymous user', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-id-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        // Act - using new simplified interface
        final result = await storageService.createList(testList);

        // Assert
        expect(result, isTrue);

        // Verify it's stored locally using test helper
        final storedLists = await storageService.getAllListsLocallyForTest();
        expect(storedLists.length, equals(1));
        expect(storedLists.first.id, equals('test-id-1'));
        expect(storedLists.first.name, equals('Test List'));
      });

      test('should read lists locally for anonymous user', () async {
        // Arrange
        final testLists = [
          ShoppingList(
            id: 'test-id-1',
            name: 'Test List 1',
            description: 'Description 1',
            color: '#FF0000',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            members: [],
          ),
          ShoppingList(
            id: 'test-id-2',
            name: 'Test List 2',
            description: 'Description 2',
            color: '#00FF00',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            members: [],
          ),
        ];

        // Save test data using new interface
        for (final list in testLists) {
          await storageService.createList(list);
        }

        // Act - using test helper to verify storage
        final result = await storageService.getAllListsLocallyForTest();

        // Assert
        expect(result.length, equals(2));
        expect(
          result.map((l) => l.name),
          containsAll(['Test List 1', 'Test List 2']),
        );
      });

      test('should update list locally for anonymous user', () async {
        // Arrange
        final originalList = ShoppingList(
          id: 'test-id-1',
          name: 'Original Name',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(originalList);

        final updatedList = ShoppingList(
          id: 'test-id-1',
          name: 'Updated Name',
          description: 'Updated Description',
          color: '#00FF00',
          createdAt: originalList.createdAt,
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        // Act - using new simplified interface
        await storageService.updateList(updatedList);

        // Assert
        final storedLists = await storageService.getAllListsLocallyForTest();
        expect(storedLists.length, equals(1));
        expect(storedLists.first.name, equals('Updated Name'));
        expect(storedLists.first.description, equals('Updated Description'));
        expect(storedLists.first.color, equals('#00FF00'));
      });

      test('should delete list locally for anonymous user', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-id-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Act - using new simplified interface
        final result = await storageService.deleteList('test-id-1');

        // Assert
        expect(result, isTrue);
        final remainingLists = await storageService.getAllListsLocallyForTest();
        expect(remainingLists.length, equals(0));
      });

      test(
        'should manage items in local list for anonymous user and sort correctly',
        () async {
          // Arrange
          final testList = ShoppingList(
            id: 'test-id-1',
            name: 'Test List',
            description: 'Test Description',
            color: '#FF0000',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            members: [],
          );

          await storageService.createList(testList);

          // Create items with different creation times for proper testing
          final now = DateTime.now();
          final testItem1 = ShoppingItem(
            id: 'item-1',
            name: 'First Item',
            quantity: '1',
            isCompleted: false,
            createdAt: now.subtract(const Duration(minutes: 2)),
          );

          final testItem2 = ShoppingItem(
            id: 'item-2',
            name: 'Second Item',
            quantity: '2',
            isCompleted: false,
            createdAt: now.subtract(const Duration(minutes: 1)),
          );

          final testItem3 = ShoppingItem(
            id: 'item-3',
            name: 'Third Item',
            quantity: '3',
            isCompleted: true,
            createdAt: now,
            completedAt: now,
          );

          // Act - using new simplified interface
          await storageService.addItem('test-id-1', testItem1);
          await storageService.addItem('test-id-1', testItem2);
          await storageService.addItem('test-id-1', testItem3);

          // Test item updates
          var updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList, isNotNull);
          expect(updatedList!.items.length, equals(3));

          // Test sorting: incomplete items should be first (newest first),
          // then completed items (most recently completed first)
          expect(
            updatedList.items[0].name,
            equals('Second Item'),
          ); // newest incomplete
          expect(
            updatedList.items[1].name,
            equals('First Item'),
          ); // older incomplete
          expect(updatedList.items[2].name, equals('Third Item')); // completed

          // Test item update using new interface
          await storageService.updateItem(
            'test-id-1',
            'item-1',
            name: 'Updated First Item',
            quantity: '10',
          );

          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          final updatedItem = updatedList!.items.firstWhere(
            (item) => item.id == 'item-1',
          );
          expect(updatedItem.name, equals('Updated First Item'));
          expect(updatedItem.quantity, equals('10'));

          // Test mark item as completed using new interface
          await storageService.updateItem(
            'test-id-1',
            'item-2',
            isCompleted: true,
          );

          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          final completedItem = updatedList!.items.firstWhere(
            (item) => item.id == 'item-2',
          );
          expect(completedItem.isCompleted, isTrue);
          expect(completedItem.completedAt, isNotNull);

          // Test mark item as not completed using new interface
          await storageService.updateItem(
            'test-id-1',
            'item-3',
            isCompleted: false,
          );

          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          final uncompletedItem = updatedList!.items.firstWhere(
            (item) => item.id == 'item-3',
          );
          expect(uncompletedItem.isCompleted, isFalse);
          expect(uncompletedItem.completedAt, isNull);

          // Test delete item using new interface
          await storageService.deleteItem('test-id-1', 'item-1');

          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items.length, equals(2));
          expect(updatedList.items.any((item) => item.id == 'item-1'), isFalse);
        },
      );

      test('should clear completed items from local list', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-id-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);

        final testItem = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        await storageService.addItem('test-id-1', testItem);

        // Verify item was added
        var updatedList = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        expect(updatedList!.items.length, equals(1));

        // Act - using new simplified interface
        final result = await storageService.clearCompleted('test-id-1');

        // Assert
        expect(result, isTrue);
        updatedList = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        expect(updatedList!.items.length, equals(0));
      });

      test('should handle list not found scenarios', () async {
        // Test getting non-existent list
        final result = await storageService.getListByIdLocallyForTest(
          'non-existent-id',
        );
        expect(result, isNull);

        // Test deleting non-existent list
        final deleteResult = await storageService.deleteList('non-existent-id');
        expect(deleteResult, isTrue); // Should handle gracefully

        // Test adding item to non-existent list
        final testItem = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        final addResult = await storageService.addItem(
          'non-existent-id',
          testItem,
        );
        expect(addResult, isFalse); // Should fail gracefully
      });

      test('should handle empty lists correctly', () async {
        // Test getting all lists when none exist
        final lists = await storageService.getAllListsLocallyForTest();
        expect(lists, isEmpty);

        // Test clearing completed items on empty list
        final testList = ShoppingList(
          id: 'test-id-1',
          name: 'Empty List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);

        final result = await storageService.clearCompleted('test-id-1');
        expect(result, isTrue); // Should handle empty list gracefully

        final list = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        expect(list!.items, isEmpty);
      });

      test('should handle item operations on non-existent items', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-id-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);
        final retrievedLists = await storageService.getAllListsLocallyForTest();
        expect(retrievedLists.length, equals(1));

        // Test update non-existent item
        final updateResult = await storageService.updateItem(
          'test-id-1',
          'non-existent-item',
          name: 'Updated Name',
        );
        expect(
          updateResult,
          isFalse,
        ); // Should return false for non-existent item

        // Test delete non-existent item
        final deleteResult = await storageService.deleteItem(
          'test-id-1',
          'non-existent-item',
        );
        expect(
          deleteResult,
          isFalse,
        ); // Should return false for non-existent item
      });

      test(
        'should maintain data consistency after multiple operations',
        () async {
          // This test ensures that multiple operations don't corrupt the data
          final lists = await storageService.getAllListsLocallyForTest();
          expect(lists, isEmpty);

          // Create multiple lists and items
          for (int i = 1; i <= 3; i++) {
            final list = ShoppingList(
              id: 'list-$i',
              name: 'List $i',
              description: 'Description $i',
              color: '#FF000$i',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              items: [],
              members: [],
            );
            await storageService.createList(list);
          }

          // Verify all lists were created
          final createdLists = await storageService.getAllListsLocallyForTest();
          expect(createdLists.length, equals(3));
        },
      );
    });

    group('Stream Interface Tests', () {
      test('should provide reactive list updates via watchLists', () async {
        // Note: This test would need to be more complex to properly test streams
        // For now, we verify the stream can be created
        final stream = storageService.watchLists();
        expect(stream, isNotNull);
      });

      test(
        'should provide reactive individual list updates via watchList',
        () async {
          // Create a test list first
          final testList = ShoppingList(
            id: 'test-stream-id',
            name: 'Stream Test List',
            description: 'Test Description',
            color: '#FF0000',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            members: [],
          );

          await storageService.createList(testList);

          // Get the stream
          final stream = storageService.watchList('test-stream-id');
          expect(stream, isNotNull);
        },
      );
    });

    group('Soft Delete Behavior Tests', () {
      test('should soft delete lists with deletedAt timestamp', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'soft-delete-test',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);

        // Verify list exists before deletion
        final listsBeforeDelete =
            await storageService.getAllListsLocallyForTest();
        expect(listsBeforeDelete.length, equals(1));

        // Act - delete the list
        await storageService.deleteList('soft-delete-test');

        // Assert - list should be hidden from normal queries
        final listsAfterDelete =
            await storageService.getAllListsLocallyForTest();
        expect(listsAfterDelete.length, equals(0));

        // But the list should still exist in raw data with deletedAt timestamp
        final rawList = await storageService.getRawListByIdForTest(
          'soft-delete-test',
        );

        expect(rawList, isNotNull);
        expect(rawList!.deletedAt, isNotNull);
        expect(rawList.name, equals('Test List')); // Data is preserved
      });

      test('should soft delete items with deletedAt timestamp', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'item-soft-delete-test',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);

        final testItem = ShoppingItem(
          id: 'item-to-delete',
          name: 'Test Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await storageService.addItem('item-soft-delete-test', testItem);

        // Verify item exists before deletion
        var listWithItem = await storageService.getListByIdLocallyForTest(
          'item-soft-delete-test',
        );
        expect(listWithItem!.items.length, equals(1));

        // Act - delete the item
        await storageService.deleteItem(
          'item-soft-delete-test',
          'item-to-delete',
        );

        // Assert - item should be hidden from normal queries
        var listAfterDelete = await storageService.getListByIdLocallyForTest(
          'item-soft-delete-test',
        );
        expect(listAfterDelete!.items.length, equals(0)); // No active items

        // But the item should still exist in raw data with deletedAt timestamp
        final rawList = await storageService.getRawListByIdForTest(
          'item-soft-delete-test',
        );

        expect(rawList, isNotNull);
        expect(
          rawList!.items.length,
          equals(1),
        ); // Item still exists in raw data
        expect(rawList.items.first.deletedAt, isNotNull); // Marked as deleted
        expect(
          rawList.items.first.name,
          equals('Test Item'),
        ); // Data is preserved
      });

      test('should soft delete completed items when clearing', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'clear-completed-test',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await storageService.createList(testList);

        final completedItem = ShoppingItem(
          id: 'completed-item',
          name: 'Completed Item',
          quantity: '1',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        final incompleteItem = ShoppingItem(
          id: 'incomplete-item',
          name: 'Incomplete Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await storageService.addItem('clear-completed-test', completedItem);
        await storageService.addItem('clear-completed-test', incompleteItem);

        // Verify both items exist
        var listBefore = await storageService.getListByIdLocallyForTest(
          'clear-completed-test',
        );
        expect(listBefore!.items.length, equals(2));

        // Act - clear completed items
        await storageService.clearCompleted('clear-completed-test');

        // Assert - only incomplete item should remain visible
        var listAfter = await storageService.getListByIdLocallyForTest(
          'clear-completed-test',
        );
        expect(listAfter!.items.length, equals(1));
        expect(listAfter.items.first.name, equals('Incomplete Item'));

        // But both items should still exist in raw data
        final rawList = await storageService.getRawListByIdForTest(
          'clear-completed-test',
        );

        expect(rawList, isNotNull);
        expect(rawList!.items.length, equals(2)); // Both items still exist

        // Find the completed item and verify it's soft deleted
        final rawCompletedItem = rawList.items.firstWhere(
          (item) => item.id == 'completed-item',
        );
        expect(rawCompletedItem.deletedAt, isNotNull);
        expect(
          rawCompletedItem.name,
          equals('Completed Item'),
        ); // Data preserved

        // Incomplete item should not be deleted
        final rawIncompleteItem = rawList.items.firstWhere(
          (item) => item.id == 'incomplete-item',
        );
        expect(rawIncompleteItem.deletedAt, isNull);
      });
    });
  });
}
