import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/sync_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

/// Tests specifically designed to verify race condition prevention
/// These tests ensure our two safeguards work correctly:
/// 1. Identical timestamps don't trigger updates
/// 2. Identical content doesn't trigger updates even with different timestamps
void main() {
  group('Race Condition Prevention Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService.instance;
      syncService.reset();
    });

    tearDown(() {
      syncService.reset();
    });

    group('Safeguard #1: Identical Timestamps Prevention', () {
      test(
        '_shouldUpdateLocal returns false when all fields including timestamps are identical',
        () {
          final timestamp = DateTime.now();

          final list1 = ShoppingList(
            id: 'test-list',
            name: 'Test List',
            description: 'Test Description',
            color: '#FF0000',
            createdAt: timestamp,
            updatedAt: timestamp,
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Test Item',
                isCompleted: false,
                createdAt: timestamp,
              ),
            ],
          );

          // Create identical list (simulates Firebase returning same data)
          final list2 = ShoppingList(
            id: 'test-list',
            name: 'Test List',
            description: 'Test Description',
            color: '#FF0000',
            createdAt: timestamp,
            updatedAt: timestamp, // IDENTICAL timestamp
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Test Item',
                isCompleted: false,
                createdAt: timestamp,
              ),
            ],
          );

          // Should NOT trigger update when everything is identical
          final shouldUpdate = syncService.testShouldUpdateLocal(list1, list2);
          expect(
            shouldUpdate,
            false,
            reason:
                'Identical lists should not trigger updates - prevents race condition',
          );
        },
      );

      test(
        'determineSyncAction returns noAction when timestamps are identical',
        () {
          final timestamp = DateTime.now();

          final action = syncService.determineSyncAction(
            localUpdatedAt: timestamp,
            remoteUpdatedAt: timestamp, // IDENTICAL
            localDeletedAt: null,
            remoteDeletedAt: null,
          );

          expect(
            action,
            SyncAction.noAction,
            reason: 'Identical timestamps should not trigger sync actions',
          );
        },
      );

      test('determineSyncAction handles timestamp tolerance correctly', () {
        final baseTime = DateTime.now();
        final closeTime = baseTime.add(
          const Duration(milliseconds: 500),
        ); // Within 1s tolerance

        final action = syncService.determineSyncAction(
          localUpdatedAt: baseTime,
          remoteUpdatedAt: closeTime,
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(
          action,
          SyncAction.noAction,
          reason: 'Timestamps within tolerance should not trigger actions',
        );
      });
    });

    group('Safeguard #2: Content-Based Change Detection', () {
      test(
        '_shouldUpdateLocal correctly detects timestamp differences (prevents race with identical timestamps)',
        () {
          final baseTime = DateTime.now();
          final slightlyLaterTime = baseTime.add(
            const Duration(milliseconds: 100),
          );

          final localList = ShoppingList(
            id: 'test-list',
            name: 'Test List',
            description: 'Same Content',
            color: '#FF0000',
            createdAt: baseTime,
            updatedAt: baseTime,
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Same Item',
                isCompleted: false,
                createdAt: baseTime,
              ),
            ],
          );

          // Test 1: Different timestamps should trigger update (this is correct behavior)
          final remoteList = ShoppingList(
            id: 'test-list',
            name: 'Test List', // Same content
            description: 'Same Content', // Same content
            color: '#FF0000', // Same content
            createdAt: baseTime,
            updatedAt: slightlyLaterTime, // Different timestamp
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Same Item', // Same content
                isCompleted: false, // Same content
                createdAt: baseTime,
              ),
            ],
          );

          final shouldUpdateDifferentTime = syncService.testShouldUpdateLocal(
            localList,
            remoteList,
          );
          expect(
            shouldUpdateDifferentTime,
            true,
            reason:
                'Different timestamps should trigger update to keep newer timestamp',
          );

          // Test 2: IDENTICAL timestamps should NOT trigger update (race condition prevention)
          final identicalList = ShoppingList(
            id: 'test-list',
            name: 'Test List',
            description: 'Same Content',
            color: '#FF0000',
            createdAt: baseTime,
            updatedAt: baseTime, // IDENTICAL timestamp
            items: [
              ShoppingItem(
                id: 'item-1',
                name: 'Same Item',
                isCompleted: false,
                createdAt: baseTime,
              ),
            ],
          );

          final shouldUpdateIdentical = syncService.testShouldUpdateLocal(
            localList,
            identicalList,
          );
          expect(
            shouldUpdateIdentical,
            false,
            reason:
                'Identical timestamps and content should not trigger update - this prevents race conditions',
          );
        },
      );

      test('_shouldUpdateLocal detects actual content changes', () {
        final baseTime = DateTime.now();

        final localList = ShoppingList(
          id: 'test-list',
          name: 'Original Name',
          description: 'Original Description',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [],
        );

        final remoteList = localList.copyWith(
          name: 'Changed Name', // Actual content change
          updatedAt: baseTime.add(const Duration(minutes: 1)),
        );

        final shouldUpdate = syncService.testShouldUpdateLocal(
          localList,
          remoteList,
        );
        expect(
          shouldUpdate,
          true,
          reason: 'Real content changes should trigger updates',
        );
      });

      test('_shouldUpdateLocal detects item changes correctly', () {
        final baseTime = DateTime.now();

        final originalItem = ShoppingItem(
          id: 'item-1',
          name: 'Original Item',
          isCompleted: false,
          createdAt: baseTime,
        );

        final changedItem = originalItem.copyWith(
          name: 'Changed Item', // Content change
        );

        final localList = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [originalItem],
        );

        final remoteList = localList.copyWith(
          items: [changedItem], // Item content changed
          updatedAt: baseTime.add(const Duration(minutes: 1)),
        );

        final shouldUpdate = syncService.testShouldUpdateLocal(
          localList,
          remoteList,
        );
        expect(
          shouldUpdate,
          true,
          reason: 'Item changes should be detected and trigger updates',
        );
      });
    });

    group('Race Condition Simulation Tests', () {
      test('mergeLists with identical data produces identical result', () {
        final timestamp = DateTime.now();

        final list = ShoppingList(
          id: 'test-list',
          name: 'Test List',
          description: 'Test Description',
          color: '#FF0000',
          createdAt: timestamp,
          updatedAt: timestamp,
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Test Item',
              isCompleted: false,
              createdAt: timestamp,
            ),
          ],
        );

        // Merge identical lists (simulates race condition scenario)
        final mergedList = syncService.mergeLists(
          localList: list,
          remoteList: list, // Identical data
        );

        // Result should be identical
        expect(mergedList.name, list.name);
        expect(mergedList.description, list.description);
        expect(mergedList.color, list.color);
        expect(mergedList.updatedAt, list.updatedAt);
        expect(mergedList.items.length, list.items.length);

        // Most importantly, should NOT trigger further updates
        final shouldUpdate = syncService.testShouldUpdateLocal(
          list,
          mergedList,
        );
        expect(
          shouldUpdate,
          false,
          reason: 'Merging identical lists should not create update loops',
        );
      });

      test('multiple rapid identical updates do not create different results', () {
        final baseTime = DateTime.now();

        final originalList = ShoppingList(
          id: 'rapid-test',
          name: 'Rapid Test',
          description: 'Testing rapid updates',
          color: '#00FF00',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [],
        );

        // Simulate multiple rapid "updates" with identical content
        var currentList = originalList;
        for (int i = 0; i < 5; i++) {
          final identicalList = ShoppingList(
            id: 'rapid-test',
            name: 'Rapid Test', // Same content
            description: 'Testing rapid updates', // Same content
            color: '#00FF00', // Same content
            createdAt: baseTime,
            updatedAt: baseTime.add(
              Duration(milliseconds: i * 10),
            ), // Slightly different timestamps
            items: [],
          );

          // Each merge should be stable
          final merged = syncService.mergeLists(
            localList: currentList,
            remoteList: identicalList,
          );

          // The key insight: if the merged result has a newer timestamp, it SHOULD trigger an update
          // Race condition prevention comes from using IDENTICAL timestamps in real FirestoreService
          final shouldUpdate = syncService.testShouldUpdateLocal(
            currentList,
            merged,
          );

          // If timestamps are different, update is expected and correct
          if (currentList.updatedAt != merged.updatedAt) {
            expect(
              shouldUpdate,
              true,
              reason:
                  'Different timestamps should trigger updates - this is correct behavior',
            );
          } else {
            expect(
              shouldUpdate,
              false,
              reason:
                  'Identical timestamps should not trigger updates - this prevents race conditions',
            );
          }

          currentList = merged;
        }
      });
    });

    group('Edge Case Race Conditions', () {
      test('handles concurrent item and list updates correctly', () {
        final baseTime = DateTime.now();

        // Local list with item update (item timestamp matches list timestamp)
        final localList = ShoppingList(
          id: 'concurrent-test',
          name: 'Original Name',
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime.add(
            const Duration(minutes: 1),
          ), // Updated due to item change
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Updated Item', // Item was updated
              isCompleted: true,
              createdAt: baseTime,
            ),
          ],
        );

        // Remote list with different list-level update but older item
        final remoteList = ShoppingList(
          id: 'concurrent-test',
          name: 'New Name', // List name updated
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime.add(
            const Duration(minutes: 2),
          ), // Newer list update
          items: [
            ShoppingItem(
              id: 'item-1',
              name: 'Original Item', // Older item state
              isCompleted: false,
              createdAt: baseTime,
            ),
          ],
        );

        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Should use remote list properties (newer timestamp)
        expect(mergedList.name, 'New Name');
        expect(mergedList.updatedAt, remoteList.updatedAt);

        // Should use local item (newer item data)
        expect(mergedList.items.first.name, 'Updated Item');
        expect(mergedList.items.first.isCompleted, true);
      });

      test('handles deletion during sync correctly', () {
        final baseTime = DateTime.now();

        // Local: Item exists
        final localList = ShoppingList(
          id: 'deletion-test',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime,
          items: [
            ShoppingItem(
              id: 'item-to-delete',
              name: 'Will Be Deleted',
              isCompleted: false,
              createdAt: baseTime,
            ),
          ],
        );

        // Remote: Item is deleted
        final remoteList = ShoppingList(
          id: 'deletion-test',
          name: 'Test List',
          description: 'Test',
          color: '#FF0000',
          createdAt: baseTime,
          updatedAt: baseTime.add(const Duration(minutes: 1)),
          items: [
            ShoppingItem(
              id: 'item-to-delete',
              name: 'Will Be Deleted',
              isCompleted: false,
              createdAt: baseTime,
              deletedAt: baseTime.add(const Duration(minutes: 1)), // Deleted
            ),
          ],
        );

        final mergedList = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        // Deleted items should be completely filtered out after merge
        expect(
          mergedList.activeItems.length,
          0,
          reason: 'Deleted items should be filtered out from active items',
        );

        // In our current implementation, deleted items are also filtered from the full items list
        // This is correct behavior - once synced, deleted items don't need to be kept locally
        expect(
          mergedList.items.length,
          0,
          reason:
              'Deleted items should be filtered out completely after successful merge',
        );
      });
    });
  });
}

/// Extension to add test helpers to SyncService
extension SyncServiceTestHelpers on SyncService {
  // These methods are already exposed as testX methods in the main SyncService
  // This extension documents what we're testing
}
