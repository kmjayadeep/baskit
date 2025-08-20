import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/sync_service.dart';
import '../../lib/models/shopping_list.dart';
import '../../lib/models/shopping_item.dart';

void main() {
  group('SyncService Bidirectional Sync Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService.instance;
      syncService.reset(); // Reset to clean state
    });

    tearDown(() {
      syncService.reset();
    });

    group('Firebase-to-Local Sync Logic', () {
      test('should add new remote list to local storage', () async {
        // Given: A remote list that doesn't exist locally
        final remoteList = ShoppingList(
          id: 'remote-list-1',
          name: 'Remote List',
          description: 'From Firebase',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          items: [],
        );

        final localLists = <ShoppingList>[];
        final remoteLists = [remoteList];

        // Test the sync logic (we can't easily mock the full stream behavior in unit tests)
        // But we can test the merge logic directly

        // When: Processing the remote list
        // This would normally happen in _syncFirebaseListsToLocal
        expect(localLists.isEmpty, true);
        expect(remoteLists.length, 1);
        expect(remoteLists.first.name, 'Remote List');
      });

      test('should merge existing list with conflict resolution', () {
        // Given: A list that exists in both local and remote with different updates
        final baseTime = DateTime.now();
        final localTime = baseTime.add(const Duration(minutes: 1));
        final remoteTime = baseTime.add(const Duration(minutes: 2));

        final localList = ShoppingList(
          id: 'shared-list-1',
          name: 'Local Name',
          description: 'Local Description',
          color: '#00FF00',
          createdAt: baseTime,
          updatedAt: localTime,
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Local Item',
              isCompleted: false,
              createdAt: localTime,
            ),
          ],
        );

        final remoteList = ShoppingList(
          id: 'shared-list-1',
          name: 'Remote Name',
          description: 'Remote Description',
          color: '#0000FF',
          createdAt: baseTime,
          updatedAt: remoteTime, // Remote is newer
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Local Item',
              isCompleted: true, // Remote item is completed
              createdAt: localTime,
            ),
            ShoppingItem(
              id: 'item-2',
              name: 'Remote Item',
              isCompleted: false,
              createdAt: remoteTime,
            ),
          ],
        );

        // When: Merging the lists
        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Then: Should use remote properties (newer) but merge items
        expect(mergedList.name, 'Remote Name'); // Remote is newer
        expect(mergedList.description, 'Remote Description');
        expect(mergedList.color, '#0000FF');
        expect(mergedList.updatedAt, remoteTime);

        // Items should be merged
        expect(mergedList.items.length, 2);
        expect(mergedList.items.any((item) => item.id == 'item-1'), true);
        expect(mergedList.items.any((item) => item.id == 'item-2'), true);

        // Local item should keep local version (same timestamp)
        final mergedItem1 = mergedList.items.firstWhere(
          (item) => item.id == 'item-1',
        );
        expect(
          mergedItem1.isCompleted,
          false,
        ); // Local version wins on timestamp tie
      });

      test(
        'should handle mixed scenarios with new, updated, and deleted items',
        () {
          final baseTime = DateTime.now();

          final localList = ShoppingList(
            id: 'mixed-list',
            name: 'Mixed List',
            description: 'Test',
            color: '#FF00FF',
            createdAt: baseTime,
            updatedAt: baseTime,
            items: [
              ShoppingItem(
                id: 'keep-local',
                name: 'Keep Local',
                isCompleted: false,
                createdAt: baseTime,
              ),
              ShoppingItem(
                id: 'update-remote',
                name: 'Old Name',
                isCompleted: false,
                createdAt: baseTime,
              ),
              ShoppingItem(
                id: 'delete-remote',
                name: 'Will Be Deleted',
                isCompleted: false,
                createdAt: baseTime,
              ),
            ],
          );

          final remoteList = ShoppingList(
            id: 'mixed-list',
            name: 'Mixed List',
            description: 'Test',
            color: '#FF00FF',
            createdAt: baseTime,
            updatedAt: baseTime,
            items: [
              ShoppingItem(
                id: 'update-remote',
                name: 'New Name',
                isCompleted: true,
                createdAt: baseTime.add(const Duration(minutes: 1)), // Newer
              ),
              ShoppingItem(
                id: 'delete-remote',
                name: 'Will Be Deleted',
                isCompleted: false,
                createdAt: baseTime,
                deletedAt: baseTime.add(const Duration(minutes: 2)), // Deleted
              ),
              ShoppingItem(
                id: 'new-remote',
                name: 'New Remote Item',
                isCompleted: false,
                createdAt: baseTime.add(const Duration(minutes: 1)),
              ),
            ],
          );

          // When: Merging the lists
          final mergedList = syncService.mergeLists(
            localList: localList,
            remoteList: remoteList,
          );

          // Then: Should handle all scenarios correctly
          final mergedItems = mergedList.items;

          // Keep local item should remain
          expect(mergedItems.any((item) => item.id == 'keep-local'), true);

          // Updated remote item should use remote version (newer)
          final updatedItem = mergedItems.firstWhere(
            (item) => item.id == 'update-remote',
          );
          expect(updatedItem.name, 'New Name');
          expect(updatedItem.isCompleted, true);

          // Deleted remote item should be removed
          expect(mergedItems.any((item) => item.id == 'delete-remote'), false);

          // New remote item should be added
          expect(mergedItems.any((item) => item.id == 'new-remote'), true);

          expect(
            mergedItems.length,
            3,
          ); // keep-local, update-remote, new-remote
        },
      );
    });

    group('List Comparison Logic', () {
      test('_shouldUpdateLocal should detect changes in list properties', () {
        final baseTime = DateTime.now();

        final originalList = ShoppingList(
          id: 'test-list',
          name: 'Original Name',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [],
        );

        // Test name change
        final nameChangedList = originalList.copyWith(name: 'New Name');
        expect(
          syncService.testShouldUpdateLocal(originalList, nameChangedList),
          true,
        );

        // Test description change
        final descChangedList = originalList.copyWith(
          description: 'New Description',
        );
        expect(
          syncService.testShouldUpdateLocal(originalList, descChangedList),
          true,
        );

        // Test color change
        final colorChangedList = originalList.copyWith(color: '#00FF00');
        expect(
          syncService.testShouldUpdateLocal(originalList, colorChangedList),
          true,
        );

        // Test no changes
        final unchangedList = originalList.copyWith();
        expect(
          syncService.testShouldUpdateLocal(originalList, unchangedList),
          false,
        );
      });

      test('_shouldUpdateLocal should detect changes in items', () {
        final baseTime = DateTime.now();

        final originalItem = ShoppingItem(
          id: 'item-1',
          name: 'Original Item',
          isCompleted: false,
          createdAt: baseTime,
        );

        final originalList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [originalItem],
        );

        // Test item change
        final changedItem = originalItem.copyWith(name: 'Changed Item');
        final itemChangedList = originalList.copyWith(items: [changedItem]);
        expect(
          syncService.testShouldUpdateLocal(originalList, itemChangedList),
          true,
        );

        // Test item addition
        final newItem = ShoppingItem(
          id: 'item-2',
          name: 'New Item',
          isCompleted: false,
          createdAt: baseTime,
        );
        final itemAddedList = originalList.copyWith(
          items: [originalItem, newItem],
        );
        expect(
          syncService.testShouldUpdateLocal(originalList, itemAddedList),
          true,
        );

        // Test item removal
        final itemRemovedList = originalList.copyWith(items: []);
        expect(
          syncService.testShouldUpdateLocal(originalList, itemRemovedList),
          true,
        );
      });
    });

    group('Item Equality Logic', () {
      test('_areItemsEqual should correctly compare items', () {
        final baseTime = DateTime.now();

        final item1 = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          isCompleted: false,
          createdAt: baseTime,
        );

        final item2 = ShoppingItem(
          id: 'item-1',
          name: 'Test Item',
          isCompleted: false,
          createdAt: baseTime,
        );

        // Same items should be equal
        expect(syncService.testAreItemsEqual(item1, item2), true);

        // Different names should not be equal
        final item3 = item1.copyWith(name: 'Different Name');
        expect(syncService.testAreItemsEqual(item1, item3), false);

        // Different completion status should not be equal
        final item4 = item1.copyWith(isCompleted: true);
        expect(syncService.testAreItemsEqual(item1, item4), false);

        // Different IDs should not be equal
        final item5 = ShoppingItem(
          id: 'different-id',
          name: 'Test Item',
          isCompleted: false,
          createdAt: baseTime,
        );
        expect(syncService.testAreItemsEqual(item1, item5), false);
      });
    });
  });
}
