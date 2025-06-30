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

          await storageService.saveListLocallyForTest(testList);

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
            name: 'Third Item (newest)',
            quantity: '3',
            isCompleted: false,
            createdAt: now,
          );

          // Act: Add items
          await storageService.addItemToLocalListForTest(
            'test-id-1',
            testItem1,
          );
          await storageService.addItemToLocalListForTest(
            'test-id-1',
            testItem2,
          );
          await storageService.addItemToLocalListForTest(
            'test-id-1',
            testItem3,
          );

          // Assert: Items added and sorted correctly (newest first for incomplete items)
          var updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items.length, equals(3));
          expect(updatedList.items[0].name, equals('Third Item (newest)'));
          expect(updatedList.items[1].name, equals('Second Item'));
          expect(updatedList.items[2].name, equals('First Item'));

          // Act: Mark the first (oldest) item as completed
          await storageService.updateItemInLocalListForTest(
            'test-id-1',
            'item-1',
            completed: true,
          );

          // Assert: Completed item moved to bottom
          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items.length, equals(3));
          // Check that incomplete items are still at top (newest first)
          expect(updatedList.items[0].name, equals('Third Item (newest)'));
          expect(updatedList.items[0].isCompleted, isFalse);
          expect(updatedList.items[1].name, equals('Second Item'));
          expect(updatedList.items[1].isCompleted, isFalse);
          // Check that completed item is at bottom
          expect(updatedList.items[2].name, equals('First Item'));
          expect(updatedList.items[2].isCompleted, isTrue);
          expect(updatedList.items[2].completedAt, isNotNull);

          // Act: Mark another item as completed with a later completion time
          await Future.delayed(
            const Duration(milliseconds: 10),
          ); // Ensure different completion time
          await storageService.updateItemInLocalListForTest(
            'test-id-1',
            'item-2',
            completed: true,
          );

          // Assert: Most recently completed item is first among completed items
          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items.length, equals(3));
          // Incomplete item at top
          expect(updatedList.items[0].name, equals('Third Item (newest)'));
          expect(updatedList.items[0].isCompleted, isFalse);
          // Most recently completed item first among completed items
          expect(updatedList.items[1].name, equals('Second Item'));
          expect(updatedList.items[1].isCompleted, isTrue);
          // Earlier completed item last
          expect(updatedList.items[2].name, equals('First Item'));
          expect(updatedList.items[2].isCompleted, isTrue);

          // Act: Update item name/quantity
          await storageService.updateItemInLocalListForTest(
            'test-id-1',
            'item-3',
            name: 'Updated Third Item',
            quantity: '5',
          );

          // Assert: Item updated but ordering maintained
          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items[0].name, equals('Updated Third Item'));
          expect(updatedList.items[0].quantity, equals('5'));
          expect(updatedList.items[0].isCompleted, isFalse);

          // Act: Delete an item
          await storageService.deleteItemFromLocalListForTest(
            'test-id-1',
            'item-1',
          );

          // Assert: Item deleted and sorting maintained
          updatedList = await storageService.getListByIdLocallyForTest(
            'test-id-1',
          );
          expect(updatedList!.items.length, equals(2));
          expect(updatedList.items[0].name, equals('Updated Third Item'));
          expect(updatedList.items[0].isCompleted, isFalse);
          expect(updatedList.items[1].name, equals('Second Item'));
          expect(updatedList.items[1].isCompleted, isTrue);
        },
      );

      test('should handle item completion timestamps correctly', () async {
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
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await storageService.addItemToLocalListForTest('test-id-1', testItem);

        // Act: Mark item as completed
        await storageService.updateItemInLocalListForTest(
          'test-id-1',
          'item-1',
          completed: true,
        );

        // Assert: Item has completedAt timestamp
        var updatedList = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        final completedItem = updatedList!.items.first;
        expect(completedItem.isCompleted, isTrue);
        expect(completedItem.completedAt, isNotNull);
        expect(
          completedItem.completedAt!.isAfter(completedItem.createdAt),
          isTrue,
        );

        // Act: Mark item as incomplete
        await storageService.updateItemInLocalListForTest(
          'test-id-1',
          'item-1',
          completed: false,
        );

        // Assert: Item no longer has completedAt timestamp
        updatedList = await storageService.getListByIdLocallyForTest(
          'test-id-1',
        );
        final incompletedItem = updatedList!.items.first;
        expect(incompletedItem.isCompleted, isFalse);
        expect(incompletedItem.completedAt, isNull);
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
