import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/services/storage_service.dart';

void main() {
  group('Local-first flow', () {
    late StorageService storageService;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_integration_test',
      );
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
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

    test('clears local data on logout', () async {
      final list = ShoppingList(
        id: 'local-list',
        name: 'Local List',
        description: 'Offline list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.saveListLocallyForTest(list);
      expect(
        (await storageService.getAllListsLocallyForTest()).length,
        equals(1),
      );

      await storageService.clearUserData();
      expect(
        (await storageService.getAllListsLocallyForTest()).length,
        equals(0),
      );
    });
  });
}
