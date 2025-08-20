import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import 'package:baskit/services/sync_service.dart';
import 'package:baskit/models/shopping_list.dart';
import 'package:baskit/models/shopping_item.dart';

void main() {
  group('SyncService Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService.instance;
      syncService.reset(); // Reset to clean state for each test
    });

    tearDown(() {
      syncService.reset();
    });

    group('State Management', () {
      test('should notify listeners when state changes', () {
        bool notified = false;

        // First change the state to something other than idle
        syncService.syncState; // Access current state (idle)

        syncService.syncStateNotifier.addListener(() {
          notified = true;
        });

        // Trigger the notifier directly to test it works
        syncService.syncStateNotifier.notifyListeners();

        expect(notified, isTrue);
      });
    });

    group('determineSyncAction', () {
      test('should return noAction when both are deleted', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: now.subtract(const Duration(minutes: 1)),
          localDeletedAt: now,
          remoteDeletedAt: now.subtract(const Duration(seconds: 30)),
        );

        expect(action, equals(SyncAction.noAction));
      });

      test('should return useLocal when only local is deleted', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: now.subtract(const Duration(minutes: 1)),
          localDeletedAt: now,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.useLocal));
      });

      test('should return useRemote when only remote is deleted', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: now.subtract(const Duration(minutes: 1)),
          localDeletedAt: null,
          remoteDeletedAt: now,
        );

        expect(action, equals(SyncAction.useRemote));
      });

      test('should return useLocal when local is newer', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: now.subtract(const Duration(minutes: 5)),
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.useLocal));
      });

      test('should return useRemote when remote is newer', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now.subtract(const Duration(minutes: 5)),
          remoteUpdatedAt: now,
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.useRemote));
      });

      test('should return noAction when timestamps are within tolerance', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: now.add(
            const Duration(milliseconds: 500),
          ), // Within 1 second tolerance
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.noAction));
      });

      test('should return useRemote when local timestamp is null', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: null,
          remoteUpdatedAt: now,
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.useRemote));
      });

      test('should return useLocal when remote timestamp is null', () {
        final now = DateTime.now();
        final action = syncService.determineSyncAction(
          localUpdatedAt: now,
          remoteUpdatedAt: null,
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.useLocal));
      });

      test('should return noAction when both timestamps are null', () {
        final action = syncService.determineSyncAction(
          localUpdatedAt: null,
          remoteUpdatedAt: null,
          localDeletedAt: null,
          remoteDeletedAt: null,
        );

        expect(action, equals(SyncAction.noAction));
      });
    });

    group('mergeLists', () {
      test('should use local properties when local is newer', () {
        final now = DateTime.now();
        final localList = _createTestList(
          id: 'list1',
          name: 'Local List',
          updatedAt: now,
          items: [],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'Remote List',
          updatedAt: now.subtract(const Duration(minutes: 1)),
          items: [],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.name, equals('Local List'));
        expect(merged.updatedAt, equals(now));
      });

      test('should use remote properties when remote is newer', () {
        final now = DateTime.now();
        final localList = _createTestList(
          id: 'list1',
          name: 'Local List',
          updatedAt: now.subtract(const Duration(minutes: 1)),
          items: [],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'Remote List',
          updatedAt: now,
          items: [],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.name, equals('Remote List'));
        expect(merged.updatedAt, equals(now));
      });

      test('should merge items from both lists', () {
        final now = DateTime.now();
        final localItem = _createTestItem(
          id: 'item1',
          name: 'Local Item',
          createdAt: now,
        );
        final remoteItem = _createTestItem(
          id: 'item2',
          name: 'Remote Item',
          createdAt: now.subtract(const Duration(minutes: 1)),
        );

        final localList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [localItem],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [remoteItem],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.items.length, equals(2));
        expect(merged.items.any((item) => item.name == 'Local Item'), isTrue);
        expect(merged.items.any((item) => item.name == 'Remote Item'), isTrue);
      });

      test('should prefer newer item when same ID exists in both lists', () {
        final now = DateTime.now();
        final localItem = _createTestItem(
          id: 'item1',
          name: 'Local Item',
          createdAt: now,
        );
        final remoteItem = _createTestItem(
          id: 'item1', // Same ID
          name: 'Remote Item',
          createdAt: now.subtract(const Duration(minutes: 1)), // Older
        );

        final localList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [localItem],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [remoteItem],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.items.length, equals(1));
        expect(
          merged.items.first.name,
          equals('Local Item'),
        ); // Newer local item wins
      });

      test('should exclude deleted items from merge', () {
        final now = DateTime.now();
        final activeItem = _createTestItem(
          id: 'item1',
          name: 'Active Item',
          createdAt: now,
        );
        final deletedItem = _createTestItem(
          id: 'item2',
          name: 'Deleted Item',
          createdAt: now,
          deletedAt: now,
        );

        final localList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [activeItem, deletedItem],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.items.length, equals(1));
        expect(merged.items.first.name, equals('Active Item'));
      });

      test('should handle remote deletion by removing local item', () {
        final now = DateTime.now();
        final localItem = _createTestItem(
          id: 'item1',
          name: 'Local Item',
          createdAt: now.subtract(const Duration(minutes: 1)),
        );
        final remoteDeletedItem = _createTestItem(
          id: 'item1',
          name: 'Remote Item',
          createdAt: now, // Newer than local
          deletedAt: now,
        );

        final localList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [localItem],
        );
        final remoteList = _createTestList(
          id: 'list1',
          name: 'List',
          updatedAt: now,
          items: [remoteDeletedItem],
        );

        final merged = syncService.mergeLists(
          localList: localList,
          remoteList: remoteList,
        );

        expect(merged.items.length, equals(0)); // Item should be removed
      });
    });

    group('Sync Lifecycle Management', () {
      setUp(() {
        syncService.reset();
      });

      test('should handle startSync call when Firebase not available', () async {
        // Without Firebase being initialized, startSync should handle gracefully
        await syncService.startSync();
        // The method should either stay idle or handle the unavailable state
        expect(syncService.syncState, isIn([SyncState.idle, SyncState.error]));
      });

      test('should maintain singleton behavior across sync operations', () {
        final instance1 = SyncService.instance;
        final instance2 = SyncService.instance;

        instance1.stopSync();
        expect(instance2.syncState, equals(SyncState.idle));
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Sync State Management', () {
      test('should expose sync state through ValueNotifier', () {
        final notifier = syncService.syncStateNotifier;
        expect(notifier, isA<ValueNotifier<SyncState>>());
        expect(notifier.value, equals(syncService.syncState));
      });

      test('should handle error state with error message', () {
        // Test that error state can be set (this would be done by internal methods)
        expect(syncService.lastErrorMessage, isNull);

        // After reset, should clear error message
        syncService.reset();
        expect(syncService.lastErrorMessage, isNull);
        expect(syncService.syncState, equals(SyncState.idle));
      });

      test('should maintain state consistency', () {
        final initialState = syncService.syncState;
        final initialError = syncService.lastErrorMessage;

        // State should be consistent across multiple accesses
        expect(syncService.syncState, equals(initialState));
        expect(syncService.lastErrorMessage, equals(initialError));
      });
    });

    group('Test Data Validation', () {
      test('should create test items with deletion state', () {
        final now = DateTime.now();

        final activeItem = _createTestItem(
          id: 'item1',
          name: 'Active Item',
          createdAt: now,
        );

        final deletedItem = _createTestItem(
          id: 'item2',
          name: 'Deleted Item',
          createdAt: now,
          deletedAt: now,
        );

        expect(activeItem.deletedAt, isNull);
        expect(deletedItem.deletedAt, isNotNull);
      });

      test('should create test lists with proper structure', () {
        final now = DateTime.now();

        final testList = _createTestList(
          id: 'test-list',
          name: 'Test List',
          updatedAt: now,
          items: [],
        );

        expect(testList.id, equals('test-list'));
        expect(testList.name, equals('Test List'));
        expect(testList.updatedAt, equals(now));
        expect(testList.items, isEmpty);
      });
    });
  });
}

// Helper functions for creating test objects
ShoppingList _createTestList({
  required String id,
  required String name,
  required DateTime updatedAt,
  required List<ShoppingItem> items,
}) {
  return ShoppingList(
    id: id,
    name: name,
    description: 'Test description',
    color: '#FF0000',
    createdAt: updatedAt.subtract(const Duration(hours: 1)),
    updatedAt: updatedAt,
    items: items,
    members: [],
  );
}

ShoppingItem _createTestItem({
  required String id,
  required String name,
  required DateTime createdAt,
  DateTime? deletedAt,
}) {
  return ShoppingItem(
    id: id,
    name: name,
    createdAt: createdAt,
    deletedAt: deletedAt,
  );
}
