import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:baskit/repositories/local_storage_repository.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('LocalStorageRepository Tests', () {
    late LocalStorageRepository localStorageRepository;
    late Directory tempDir;

    setUpAll(() async {
      // Initialize Hive for testing with temporary directory
      tempDir = Directory.systemTemp.createTempSync('hive_local_storage_test');
      Hive.init(tempDir.path);

      // Register type adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() async {
      // Reset the LocalStorageRepository singleton
      LocalStorageRepository.resetInstanceForTest();

      // Get fresh instance
      localStorageRepository = LocalStorageRepository.instance;

      // Initialize the service
      await localStorageRepository.init();
    });

    tearDown(() async {
      // Clear all data first
      try {
        await localStorageRepository.clearAllDataForTest();
      } catch (e) {
        // Ignore errors if service is already disposed
      }

      // Clean up the service
      try {
        localStorageRepository.dispose();
      } catch (e) {
        // Ignore errors if already disposed
      }

      // Close and delete Hive boxes for clean test state
      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (e) {
        // Box might not exist, that's okay
      }

      // Reset instance
      LocalStorageRepository.resetInstanceForTest();
    });

    tearDownAll(() async {
      // Clean up Hive completely
      try {
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors in tests
      }

      // Clean up temp directory
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(localStorageRepository, isNotNull);
        final lists = await localStorageRepository.getAllListsForTest();
        expect(lists, isNotNull);
      });

      test('should handle multiple init calls gracefully', () async {
        await localStorageRepository.init();
        await localStorageRepository.init(); // Should not throw
        expect(localStorageRepository, isNotNull);
      });
    });

    group('List CRUD Operations', () {
      test('should create a new list successfully', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        // Act
        final result = await localStorageRepository.upsertList(testList);

        // Assert
        expect(result, isTrue);
        final storedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(storedList, isNotNull);
        expect(storedList!.name, equals('Test List'));
        expect(storedList.description, equals('Test Description'));
        expect(storedList.color, equals('#FF0000'));
      });

      test('should update an existing list successfully', () async {
        // Arrange
        final originalList = ShoppingList(
          id: 'test-list-1',
          name: 'Original Name',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(originalList);

        final updatedList = originalList.copyWith(
          name: 'Updated Name',
          description: 'Updated Description',
          color: '#00FF00',
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await localStorageRepository.upsertList(updatedList);

        // Assert
        expect(result, isTrue);
        final storedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(storedList, isNotNull);
        expect(storedList!.name, equals('Updated Name'));
        expect(storedList.description, equals('Updated Description'));
        expect(storedList.color, equals('#00FF00'));
      });

      test('should delete a list successfully', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(testList);
        expect(
          await localStorageRepository.getListByIdForTest('test-list-1'),
          isNotNull,
        );

        // Act
        final result = await localStorageRepository.deleteList('test-list-1');

        // Assert
        expect(result, isTrue);
        final deletedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(deletedList, isNull);
      });

      test('should handle deleting non-existent list gracefully', () async {
        // Act
        final result = await localStorageRepository.deleteList(
          'non-existent-id',
        );

        // Assert - should return true even if list doesn't exist
        expect(result, isTrue);
      });

      test('should get all lists sorted by updatedAt descending', () async {
        // Arrange
        final now = DateTime.now();
        final list1 = ShoppingList(
          id: 'test-list-1',
          name: 'First List',
          description: 'Description 1',
          color: '#FF0000',
          createdAt: now.subtract(const Duration(minutes: 3)),
          updatedAt: now.subtract(const Duration(minutes: 2)),
          items: [],
          members: [],
        );

        final list2 = ShoppingList(
          id: 'test-list-2',
          name: 'Second List',
          description: 'Description 2',
          color: '#00FF00',
          createdAt: now.subtract(const Duration(minutes: 2)),
          updatedAt: now.subtract(const Duration(minutes: 1)),
          items: [],
          members: [],
        );

        final list3 = ShoppingList(
          id: 'test-list-3',
          name: 'Third List',
          description: 'Description 3',
          color: '#0000FF',
          createdAt: now.subtract(const Duration(minutes: 1)),
          updatedAt: now,
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(list1);
        await localStorageRepository.upsertList(list2);
        await localStorageRepository.upsertList(list3);

        // Act
        final lists = await localStorageRepository.getAllListsForTest();

        // Assert
        expect(lists.length, equals(3));
        expect(lists[0].name, equals('Third List')); // Most recently updated
        expect(lists[1].name, equals('Second List'));
        expect(lists[2].name, equals('First List'));
      });

      test('should return empty list when no lists exist', () async {
        // Act
        final lists = await localStorageRepository.getAllListsForTest();

        // Assert
        expect(lists, isEmpty);
      });

      test('should return null for non-existent list by ID', () async {
        // Act
        final list = await localStorageRepository.getListByIdForTest(
          'non-existent-id',
        );

        // Assert
        expect(list, isNull);
      });
    });

    group('Item CRUD Operations', () {
      late ShoppingList testList;

      setUp(() async {
        testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );
        await localStorageRepository.upsertList(testList);
      });

      test('should add an item to a list successfully', () async {
        // Arrange
        final testItem = ShoppingItem(
          id: 'test-item-1',
          name: 'Test Item',
          quantity: '2',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        // Act
        final result = await localStorageRepository.addItem(
          'test-list-1',
          testItem,
        );

        // Assert
        expect(result, isTrue);
        final updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList, isNotNull);
        expect(updatedList!.items.length, equals(1));
        expect(updatedList.items.first.name, equals('Test Item'));
        expect(updatedList.items.first.quantity, equals('2'));
      });

      test('should update an item successfully', () async {
        // Arrange
        final testItem = ShoppingItem(
          id: 'test-item-1',
          name: 'Original Name',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await localStorageRepository.addItem('test-list-1', testItem);

        // Act
        final result = await localStorageRepository.updateItem(
          'test-list-1',
          'test-item-1',
          name: 'Updated Name',
          quantity: '5',
          isCompleted: true,
        );

        // Assert
        expect(result, isTrue);
        final updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList, isNotNull);

        final updatedItem = updatedList!.items.firstWhere(
          (item) => item.id == 'test-item-1',
        );
        expect(updatedItem.name, equals('Updated Name'));
        expect(updatedItem.quantity, equals('5'));
        expect(updatedItem.isCompleted, isTrue);
        expect(updatedItem.completedAt, isNotNull);
      });

      test('should mark item as incomplete and clear completedAt', () async {
        // Arrange
        final testItem = ShoppingItem(
          id: 'test-item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        await localStorageRepository.addItem('test-list-1', testItem);

        // Act
        final result = await localStorageRepository.updateItem(
          'test-list-1',
          'test-item-1',
          isCompleted: false,
        );

        // Assert
        expect(result, isTrue);
        final updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        final updatedItem = updatedList!.items.firstWhere(
          (item) => item.id == 'test-item-1',
        );
        expect(updatedItem.isCompleted, isFalse);
        expect(updatedItem.completedAt, isNull);
      });

      test('should delete an item successfully', () async {
        // Arrange
        final testItem = ShoppingItem(
          id: 'test-item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        await localStorageRepository.addItem('test-list-1', testItem);

        var updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList!.items.length, equals(1));

        // Act
        final result = await localStorageRepository.deleteItem(
          'test-list-1',
          'test-item-1',
        );

        // Assert
        expect(result, isTrue);
        updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList!.items.length, equals(0));
      });

      test('should clear all completed items from a list', () async {
        // Arrange
        final item1 = ShoppingItem(
          id: 'item-1',
          name: 'Incomplete Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        final item2 = ShoppingItem(
          id: 'item-2',
          name: 'Completed Item 1',
          quantity: '2',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        final item3 = ShoppingItem(
          id: 'item-3',
          name: 'Completed Item 2',
          quantity: '3',
          isCompleted: true,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        await localStorageRepository.addItem('test-list-1', item1);
        await localStorageRepository.addItem('test-list-1', item2);
        await localStorageRepository.addItem('test-list-1', item3);

        var updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList!.items.length, equals(3));

        // Act
        final result = await localStorageRepository.clearCompleted(
          'test-list-1',
        );

        // Assert
        expect(result, isTrue);
        updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );
        expect(updatedList!.items.length, equals(1));
        expect(updatedList.items.first.name, equals('Incomplete Item'));
      });

      test('should handle item operations on non-existent list', () async {
        final testItem = ShoppingItem(
          id: 'test-item-1',
          name: 'Test Item',
          quantity: '1',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        // Try to add item to non-existent list
        var result = await localStorageRepository.addItem(
          'non-existent-list',
          testItem,
        );
        expect(result, isFalse);

        // Try to update item in non-existent list
        result = await localStorageRepository.updateItem(
          'non-existent-list',
          'test-item-1',
          name: 'Updated',
        );
        expect(result, isFalse);

        // Try to delete item from non-existent list
        result = await localStorageRepository.deleteItem(
          'non-existent-list',
          'test-item-1',
        );
        expect(result, isFalse);
      });

      test('should handle operations on non-existent items', () async {
        // Try to update non-existent item
        var result = await localStorageRepository.updateItem(
          'test-list-1',
          'non-existent-item',
          name: 'Updated',
        );
        expect(result, isFalse);

        // Try to delete non-existent item
        result = await localStorageRepository.deleteItem(
          'test-list-1',
          'non-existent-item',
        );
        expect(result, isFalse);
      });
    });

    group('Stream Functionality', () {
      test('should provide reactive updates via watchLists', () async {
        final streamValues = <List<ShoppingList>>[];
        late StreamSubscription subscription;

        // Act
        subscription = localStorageRepository.watchLists().listen((lists) {
          streamValues.add(lists);
        });

        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Allow initial emission

        // Add a list
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(testList);
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Allow stream emission

        // Assert
        expect(
          streamValues.length,
          greaterThanOrEqualTo(2),
        ); // Initial empty + after adding
        expect(streamValues.last.length, equals(1));
        expect(streamValues.last.first.name, equals('Test List'));

        await subscription.cancel();
      });

      test('should provide reactive updates via watchList', () async {
        final streamValues = <ShoppingList?>[];
        late StreamSubscription subscription;

        // Create a list first
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(testList);

        // Act
        subscription = localStorageRepository.watchList('test-list-1').listen((
          list,
        ) {
          streamValues.add(list);
        });

        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Allow initial emission

        // Update the list
        final updatedList = testList.copyWith(
          name: 'Updated List',
          updatedAt: DateTime.now(),
        );
        await localStorageRepository.upsertList(updatedList);
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Allow stream emission

        // Assert
        expect(
          streamValues.length,
          greaterThanOrEqualTo(2),
        ); // Initial + after update
        expect(streamValues.last?.name, equals('Updated List'));

        await subscription.cancel();
      });

      test('should handle watchList for non-existent list', () async {
        final streamValues = <ShoppingList?>[];
        late StreamSubscription subscription;

        // Act
        subscription = localStorageRepository
            .watchList('non-existent-list')
            .listen((list) {
              streamValues.add(list);
            });

        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Allow initial emission

        // Assert
        expect(streamValues.length, greaterThanOrEqualTo(1));
        expect(streamValues.last, isNull);

        await subscription.cancel();
      });

      test('should clean up individual list streams', () async {
        // Create a test list first so the stream has something to watch
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );
        await localStorageRepository.upsertList(testList);

        // Create a stream
        final subscription = localStorageRepository
            .watchList('test-list-1')
            .listen((_) {});

        // Allow some time for the stream to initialize
        await Future.delayed(const Duration(milliseconds: 10));

        // Cancel subscription first
        await subscription.cancel();

        // Then clean up the stream
        localStorageRepository.disposeListStream('test-list-1');

        // This test mainly ensures no exceptions are thrown
        expect(true, isTrue);
      });
    });

    group('Sorting Functionality', () {
      late ShoppingList testList;

      setUp(() async {
        testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );
        await localStorageRepository.upsertList(testList);
      });

      test(
        'should sort items correctly: incomplete first, completed last',
        () async {
          // Arrange - Add items with different states and times
          final now = DateTime.now();

          final incompleteItem1 = ShoppingItem(
            id: 'item-1',
            name: 'Incomplete Old',
            quantity: '1',
            isCompleted: false,
            createdAt: now.subtract(const Duration(minutes: 2)),
          );

          final incompleteItem2 = ShoppingItem(
            id: 'item-2',
            name: 'Incomplete New',
            quantity: '2',
            isCompleted: false,
            createdAt: now.subtract(const Duration(minutes: 1)),
          );

          final completedItem1 = ShoppingItem(
            id: 'item-3',
            name: 'Completed Old',
            quantity: '3',
            isCompleted: true,
            createdAt: now.subtract(const Duration(minutes: 3)),
            completedAt: now.subtract(const Duration(minutes: 2)),
          );

          final completedItem2 = ShoppingItem(
            id: 'item-4',
            name: 'Completed New',
            quantity: '4',
            isCompleted: true,
            createdAt: now.subtract(const Duration(minutes: 4)),
            completedAt: now.subtract(const Duration(minutes: 1)),
          );

          await localStorageRepository.addItem('test-list-1', incompleteItem1);
          await localStorageRepository.addItem('test-list-1', completedItem1);
          await localStorageRepository.addItem('test-list-1', incompleteItem2);
          await localStorageRepository.addItem('test-list-1', completedItem2);

          // Act
          final updatedList = await localStorageRepository.getListByIdForTest(
            'test-list-1',
          );

          // Assert
          expect(updatedList!.items.length, equals(4));

          // First two should be incomplete items, sorted by creation date (newest first)
          expect(updatedList.items[0].name, equals('Incomplete New'));
          expect(updatedList.items[1].name, equals('Incomplete Old'));

          // Last two should be completed items, sorted by completion date (most recent first)
          expect(updatedList.items[2].name, equals('Completed New'));
          expect(updatedList.items[3].name, equals('Completed Old'));
        },
      );

      test('should handle items with null completedAt correctly', () async {
        // Arrange
        final now = DateTime.now();

        final completedItemWithDate = ShoppingItem(
          id: 'item-1',
          name: 'Completed With Date',
          quantity: '1',
          isCompleted: true,
          createdAt: now.subtract(const Duration(minutes: 3)),
          completedAt: now.subtract(const Duration(minutes: 2)),
        );

        final completedItemWithoutDate = ShoppingItem(
          id: 'item-2',
          name: 'Completed Without Date',
          quantity: '2',
          isCompleted: true,
          createdAt: now.subtract(const Duration(minutes: 1)),
          // completedAt is null
        );

        await localStorageRepository.addItem(
          'test-list-1',
          completedItemWithDate,
        );
        await localStorageRepository.addItem(
          'test-list-1',
          completedItemWithoutDate,
        );

        // Act
        final updatedList = await localStorageRepository.getListByIdForTest(
          'test-list-1',
        );

        // Assert
        expect(updatedList!.items.length, equals(2));

        // completedItemWithoutDate falls back to createdAt (now - 1 minute)
        // completedItemWithDate uses completedAt (now - 2 minutes)
        // Since now - 1 minute > now - 2 minutes, completedItemWithoutDate should come first
        expect(updatedList.items[0].name, equals('Completed Without Date'));
        expect(updatedList.items[1].name, equals('Completed With Date'));
      });
    });

    group('Utility Methods', () {
      test('should clear all data successfully', () async {
        // Arrange - Add some test data
        final testList1 = ShoppingList(
          id: 'test-list-1',
          name: 'Test List 1',
          description: 'Description 1',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        final testList2 = ShoppingList(
          id: 'test-list-2',
          name: 'Test List 2',
          description: 'Description 2',
          color: '#00FF00',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        await localStorageRepository.upsertList(testList1);
        await localStorageRepository.upsertList(testList2);

        var lists = await localStorageRepository.getAllListsForTest();
        expect(lists.length, equals(2));

        // Act
        await localStorageRepository.clearAllDataForTest();

        // Assert
        lists = await localStorageRepository.getAllListsForTest();
        expect(lists, isEmpty);
      });

      test('should refresh streams manually', () async {
        // This test mainly ensures no exceptions are thrown
        localStorageRepository.refreshStreams();
        expect(true, isTrue);
      });

      test('should dispose resources properly', () async {
        // This test mainly ensures no exceptions are thrown
        localStorageRepository.dispose();
        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle concurrent operations gracefully', () async {
        // Arrange
        final testList = ShoppingList(
          id: 'test-list-1',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
          members: [],
        );

        // Act - Perform multiple operations concurrently
        final futures = <Future>[
          localStorageRepository.upsertList(testList),
          localStorageRepository.upsertList(
            testList.copyWith(name: 'Updated Name'),
          ),
          localStorageRepository.getAllListsForTest(),
          localStorageRepository.getListByIdForTest('test-list-1'),
        ];

        final results = await Future.wait(futures);

        // Assert - All operations should complete successfully
        expect(results[0], isTrue); // upsertList
        expect(results[1], isTrue); // upsertList
        expect(results[2], isA<List<ShoppingList>>()); // getAllLists
        // The getListById might return null or the list depending on timing
      });

      test(
        'should handle rapid stream subscriptions and cancellations',
        () async {
          // Create and cancel multiple subscriptions rapidly
          final subscriptions = <StreamSubscription>[];

          for (int i = 0; i < 5; i++) {
            final subscription = localStorageRepository
                .watchList('test-list-$i')
                .listen((_) {});
            subscriptions.add(subscription);
          }

          // Cancel all subscriptions
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }

          // Clean up streams
          for (int i = 0; i < 5; i++) {
            localStorageRepository.disposeListStream('test-list-$i');
          }

          // This test mainly ensures no exceptions are thrown
          expect(true, isTrue);
        },
      );
    });
  });
}
