import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/services/storage_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('StorageService Local-First Tests', () {
    late StorageService storageService;

    setUp(() async {
      // Reset SharedPreferences with empty values
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

        // Act
        final result = await storageService.saveListLocallyForTest(testList);

        // Assert
        expect(result, isTrue);

        // Verify it's stored locally
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

        // Save test data
        for (final list in testLists) {
          await storageService.saveListLocallyForTest(list);
        }

        // Act
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

        await storageService.saveListLocallyForTest(originalList);

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

        // Act
        await storageService.saveListLocallyForTest(updatedList);

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

        await storageService.saveListLocallyForTest(testList);
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Act
        final result = await storageService.deleteListLocallyForTest(
          'test-id-1',
        );

        // Assert
        expect(result, isTrue);
        final remainingLists = await storageService.getAllListsLocallyForTest();
        expect(remainingLists.length, equals(0));
      });

      test('should manage items in local list for anonymous user', () async {
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

        await storageService.saveListLocallyForTest(testList);

        final testItem = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          quantity: '2',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        // Act: Add item
        final addResult = await storageService.addItemToLocalListForTest(
          'test-id-1',
          testItem,
        );

        // Assert: Item added
        expect(addResult, isTrue);
        final updatedList = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        expect(updatedList!.items.length, equals(1));
        expect(updatedList.items.first.name, equals('Test Item'));

        // Act: Update item
        final updateResult = await storageService.updateItemInLocalListForTest(
          'test-id-1',
          'item-1',
          name: 'Updated Item',
          completed: true,
        );

        // Assert: Item updated
        expect(updateResult, isTrue);
        final listWithUpdatedItem = await storageService
            .getListByIdLocallyForTest('test-id-1');
        expect(listWithUpdatedItem!.items.first.name, equals('Updated Item'));
        expect(listWithUpdatedItem.items.first.isCompleted, isTrue);

        // Act: Delete item
        final deleteResult = await storageService
            .deleteItemFromLocalListForTest('test-id-1', 'item-1');

        // Assert: Item deleted
        expect(deleteResult, isTrue);
        final listWithoutItem = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        expect(listWithoutItem!.items.length, equals(0));
      });
    });

    group('Migration Logic Tests', () {
      test('should track migration status per user', () async {
        // Test migration tracking logic

        // Initially no migration should be complete
        expect(
          await storageService.isMigrationCompleteForTest(),
          isTrue,
        ); // Anonymous users don't need migration

        // Test that migration status can be set
        await storageService.markMigrationCompleteForTest();

        // For anonymous users, migration is always considered complete
        expect(await storageService.isMigrationCompleteForTest(), isTrue);
      });

      test('should clear local data after migration', () async {
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

        await storageService.saveListLocallyForTest(testList);
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Act
        await storageService.clearLocalDataForTest();

        // Assert
        final remainingLists = await storageService.getAllListsLocallyForTest();
        expect(remainingLists.length, equals(0));
      });
    });

    group('Data Cleanup Tests', () {
      test('should clear all local data on clearUserData', () async {
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

        await storageService.saveListLocallyForTest(testList);

        // Set some migration status
        await storageService.markMigrationCompleteForTest();

        // Verify data exists
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Act
        await storageService.clearUserData();

        // Assert
        final remainingLists = await storageService.getAllListsLocallyForTest();
        expect(remainingLists.length, equals(0));

        // Migration status should also be cleared (for non-anonymous users)
        // Note: For anonymous users, migration is always considered complete
      });

      test('should handle clearAllLists for anonymous users', () async {
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

        await storageService.saveListLocallyForTest(testList);
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(1),
        );

        // Act - this should work for anonymous users
        final result = await storageService.clearAllLists();

        // Assert
        expect(result, isTrue);
        final remainingLists = await storageService.getAllListsLocallyForTest();
        expect(remainingLists.length, equals(0));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty local storage gracefully', () async {
        // Act
        final lists = await storageService.getAllListsLocallyForTest();

        // Assert
        expect(lists, isEmpty);
      });

      test('should handle getting non-existent list', () async {
        // Act
        final list = await storageService.getListByIdLocallyForTest(
          'non-existent',
        );

        // Assert
        expect(list, isNull);
      });

      test('should handle updating non-existent list', () async {
        // Act
        final result = await storageService.updateItemInLocalListForTest(
          'non-existent-list',
          'non-existent-item',
          name: 'Test',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should handle deleting from non-existent list', () async {
        // Act
        final result = await storageService.deleteItemFromLocalListForTest(
          'non-existent-list',
          'non-existent-item',
        );

        // Assert
        expect(result, isFalse);
      });

      test('should handle adding item to non-existent list', () async {
        // Arrange
        final testItem = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await storageService.addItemToLocalListForTest(
          'non-existent-list',
          testItem,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('JSON Serialization Tests', () {
      test('should handle list serialization and deserialization', () async {
        // Arrange
        final originalList = ShoppingList(
          id: 'test-id-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Test Item',
              quantity: '2',
              isCompleted: false,
              createdAt: DateTime.now(),
            ),
          ],
          members: ['user1@example.com'],
        );

        // Act
        await storageService.saveListLocallyForTest(originalList);
        final retrievedLists = await storageService.getAllListsLocallyForTest();

        // Assert
        expect(retrievedLists.length, equals(1));
        final retrievedList = retrievedLists.first;

        expect(retrievedList.id, equals(originalList.id));
        expect(retrievedList.name, equals(originalList.name));
        expect(retrievedList.description, equals(originalList.description));
        expect(retrievedList.color, equals(originalList.color));
        expect(retrievedList.items.length, equals(1));
        expect(retrievedList.items.first.name, equals('Test Item'));
        expect(retrievedList.members.length, equals(1));
        expect(retrievedList.members.first, equals('user1@example.com'));
      });

      test('should handle corrupted JSON gracefully', () async {
        // Arrange - manually set corrupted JSON
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('shopping_lists', 'invalid json {');

        // Act
        final lists = await storageService.getAllListsLocallyForTest();

        // Assert
        expect(lists, isEmpty);
      });
    });
  });
}
