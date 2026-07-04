import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/share_result.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/services/local_storage_service.dart';
import 'package:baskit/services/migration_service.dart';

/// A fake cloud repository that simulates failures for testing migration logic
class _FakeCloudRepository implements ShoppingRepository {
  final List<String> _failOnCreate = [];
  final List<ShoppingList> _createdLists = [];

  @override
  Future<bool> createList(ShoppingList list) async {
    if (_failOnCreate.contains(list.id)) {
      return false; // Simulates createList returning false
    }
    _createdLists.add(list);
    return true;
  }

  @override
  Future<bool> updateList(ShoppingList list) async => true;

  @override
  Future<bool> deleteList(String id) async => true;

  @override
  Stream<List<ShoppingList>> watchLists() => Stream.value([]);

  @override
  Stream<ShoppingList?> watchList(String id) => Stream.value(null);

  @override
  Future<bool> addItem(String listId, item) async => true;

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async => true;

  @override
  Future<bool> deleteItem(String listId, String itemId) async => true;

  @override
  Future<bool> clearCompleted(String listId) async => true;

  @override
  Future<ShareResult> shareList(String listId, String email) async {
    return const ShareResult.success();
  }

  @override
  Future<bool> removeMember(String listId, String userId) async => true;

  @override
  Future<void> sync() async {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  void disposeListStream(String id) {}

  @override
  Future<void> init() async {}

  @override
  void dispose() {}
}

void main() {
  group('Migration Flow Integration Tests', () {
    late LocalStorageService localStorage;
    late _FakeCloudRepository cloudRepository;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_migration_test',
      );
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LocalStorageService.resetInstanceForTest();
      localStorage = LocalStorageService.instance;
      await localStorage.init();
      cloudRepository = _FakeCloudRepository();
    });

    tearDown(() async {
      await localStorage.clearAllDataForTest();
      LocalStorageService.resetInstanceForTest();

      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    tearDownAll(() async {
      try {
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('local data is preserved when migration fails', () async {
      // Arrange: Create two local lists
      final list1 = ShoppingList(
        id: 'mig-list-1',
        name: 'List One',
        description: 'First test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final list2 = ShoppingList(
        id: 'mig-list-2',
        name: 'List Two',
        description: 'Second test list',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localStorage.upsertList(list1);
      await localStorage.upsertList(list2);

      // Make the second list fail on create
      // ignore: invalid_use_of_visible_for_testing_member
      cloudRepository._failOnCreate.add(list2.id);

      // Act: Run migration
      final migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );

      final result = await migrationService.ensureComplete();

      // Assert: Migration should not be complete
      expect(result, isFalse);

      // Assert: Local data should still exist
      final localLists = await localStorage.getAllLists();
      expect(localLists.length, equals(2));

      // Assert: Migration flag should not be set
      final isComplete = await migrationService.isComplete();
      expect(isComplete, isFalse);
    });

    test('migration retry succeeds after previous partial failure', () async {
      // Arrange: Create a local list
      final list = ShoppingList(
        id: 'mig-retry-1',
        name: 'Retry List',
        description: 'List for retry test',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localStorage.upsertList(list);

      // First attempt fails
      // ignore: invalid_use_of_visible_for_testing_member
      cloudRepository._failOnCreate.add(list.id);

      final migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );

      final firstResult = await migrationService.ensureComplete();
      expect(firstResult, isFalse);

      // Assert: Local data still exists after first failure
      var localLists = await localStorage.getAllLists();
      expect(localLists.length, equals(1));

      // Second attempt succeeds (remove the failure)
      cloudRepository._failOnCreate.clear();

      final secondResult = await migrationService.ensureComplete();
      expect(secondResult, isTrue);

      // Assert: Migration flag is set
      final isComplete = await migrationService.isComplete();
      expect(isComplete, isTrue);

      // Assert: The cloud repository received the list
      expect(cloudRepository._createdLists.length, equals(1));
      expect(cloudRepository._createdLists.first.id, equals(list.id));
    });

    test('migration is idempotent (already complete)', () async {
      final migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );

      // Mark migration as already complete
      await migrationService.markComplete();

      // Run ensureComplete again
      final result = await migrationService.ensureComplete();

      // Should return true without creating any lists
      expect(result, isTrue);
      expect(cloudRepository._createdLists.length, equals(0));
    });

    test('migration with empty local data completes successfully', () async {
      final migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );

      final result = await migrationService.ensureComplete();

      expect(result, isTrue);
      expect(cloudRepository._createdLists.length, equals(0));
    });

    test('clearForCurrentUser resets migration flag', () async {
      final migrationService = MigrationService(
        localStorage: localStorage,
        cloudRepository: cloudRepository,
      );

      // Mark as complete
      await migrationService.markComplete();
      expect(await migrationService.isComplete(), isTrue);

      // Clear the flag
      await migrationService.clearForCurrentUser();
      expect(await migrationService.isComplete(), isFalse);
    });
  });
}
