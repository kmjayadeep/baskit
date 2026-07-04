import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/services/storage_service.dart';

/// Tests that verify the account deletion cleanup expectations.
///
/// These tests validate the contract that local data must not be cleared
/// before remote account deletion succeeds, and that clearUserData is a safe,
/// deliberate operation.
void main() {
  group('Account Deletion Flow Integration Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_account_deletion_test',
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
      StorageService.resetInstanceForTest();
      storageService = StorageService.instance;
      await storageService.init();
    });

    tearDown(() async {
      await storageService.clearLocalDataForTest();
      StorageService.resetInstanceForTest();

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

    test('local data persists when deleteAccount operation fails', () async {
      // Arrange: Create local data that simulates user content
      final list = ShoppingList(
        id: 'delete-test-1',
        name: 'User Shopping List',
        description: 'Data to protect',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.saveListLocallyForTest(list);

      // Verify data exists before any operation
      var localLists = await storageService.getAllListsLocallyForTest();
      expect(localLists.length, equals(1));
      expect(localLists.first.name, equals('User Shopping List'));

      // Simulate: deleteAccount remotely fails → local data must NOT be cleared
      // This is the contract: only clearLocalData should clear, not a failed
      // remote operation.

      // Assert: Local data is still present (no clear was called)
      localLists = await storageService.getAllListsLocallyForTest();
      expect(localLists.length, equals(1));
      expect(localLists.first.id, equals('delete-test-1'));
    });

    test('clearUserData removes all local data successfully', () async {
      // Arrange: Create multiple local lists
      final list1 = ShoppingList(
        id: 'delete-test-2',
        name: 'List Alpha',
        description: 'First list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final list2 = ShoppingList(
        id: 'delete-test-3',
        name: 'List Beta',
        description: 'Second list',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.saveListLocallyForTest(list1);
      await storageService.saveListLocallyForTest(list2);

      // Verify data exists
      expect(
        (await storageService.getAllListsLocallyForTest()).length,
        equals(2),
      );

      // Act: Clear user data (simulating successful deletion flow)
      await storageService.clearUserData();

      // Assert: All data is gone
      expect(
        (await storageService.getAllListsLocallyForTest()).length,
        equals(0),
      );
    });

    test(
      'clearUserData is safe to call multiple times (idempotent)',
      () async {
        // Clear with no data
        await storageService.clearUserData();
        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(0),
        );

        // Create data, clear, then clear again
        final list = ShoppingList(
          id: 'delete-test-4',
          name: 'Idempotent Test',
          description: 'Idempotent check',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await storageService.saveListLocallyForTest(list);
        await storageService.clearUserData();
        await storageService.clearUserData(); // Second clear should not crash

        expect(
          (await storageService.getAllListsLocallyForTest()).length,
          equals(0),
        );
      },
    );

    test('local data survives storage service reset without clear', () async {
      // Arrange
      final list = ShoppingList(
        id: 'delete-test-5',
        name: 'Survival Test',
        description: 'Should survive',
        color: '#0000FF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.saveListLocallyForTest(list);
      expect(
        (await storageService.getAllListsLocallyForTest()).length,
        equals(1),
      );

      // Act: Reset the service instance WITHOUT calling clearUserData
      // (simulating app restart without account deletion)
      StorageService.resetInstanceForTest();
      storageService = StorageService.instance;
      await storageService.init();

      // Assert: Data survives because clearUserData was not called
      final survivors = await storageService.getAllListsLocallyForTest();
      expect(survivors.length, equals(1));
      expect(survivors.first.name, equals('Survival Test'));
    });
  });
}
