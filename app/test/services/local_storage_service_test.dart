import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/services/local_storage_service.dart';

void main() {
  group('LocalStorageService', () {
    late LocalStorageService service;
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('hive_local_storage_test');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
    });

    setUp(() async {
      LocalStorageService.resetInstanceForTest();
      service = LocalStorageService.instance;
      await service.init();
    });

    tearDown(() async {
      await service.clearAllDataForTest();
      service.dispose();

      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (e) {
        // Ignore cleanup errors
      }

      LocalStorageService.resetInstanceForTest();
    });

    tearDownAll(() async {
      try {
        await Hive.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors
      }

      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('upserts and retrieves a list', () async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        description: 'Description',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await service.upsertList(list);
      expect(result, isTrue);

      final stored = await service.getListByIdForTest('list-1');
      expect(stored, isNotNull);
      expect(stored!.name, equals('Test List'));
    });

    test('adds, updates, and deletes items', () async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Items List',
        description: 'Description',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.upsertList(list);

      final item = ShoppingItem(
        id: 'item-1',
        name: 'Milk',
        quantity: '1',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      expect(await service.addItem('list-1', item), isTrue);

      expect(
        await service.updateItem('list-1', 'item-1', completed: true),
        isTrue,
      );

      final updated = await service.getListByIdForTest('list-1');
      expect(updated!.items.first.isCompleted, isTrue);

      expect(await service.deleteItem('list-1', 'item-1'), isTrue);
      final cleared = await service.getListByIdForTest('list-1');
      expect(cleared!.items, isEmpty);
    });

    test('watchList emits updates', () async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Stream List',
        description: 'Description',
        color: '#123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updates = <ShoppingList?>[];
      final subscription = service.watchList('list-1').listen(updates.add);

      await service.upsertList(list);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(updates.any((value) => value?.id == 'list-1'), isTrue);
      await subscription.cancel();
    });
  });
}
