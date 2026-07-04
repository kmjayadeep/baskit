import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/repositories/firestore_shopping_repository.dart';
import 'package:baskit/services/firestore_service.dart';
import 'package:baskit/services/storage_service.dart';

void main() {
  group('StorageService (local routing)', () {
    late StorageService storageService;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync('hive_storage_test');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(MemberRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ListMemberAdapter());
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

    test('creates lists locally for anonymous users', () async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        description: 'Description',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await storageService.createList(list);
      expect(result, isTrue);

      final stored = await storageService.getListByIdLocallyForTest('list-1');
      expect(stored, isNotNull);
    });

    test('manages items and clears completed', () async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Items List',
        description: 'Description',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await storageService.createList(list);

      final item = ShoppingItem(
        id: 'item-1',
        name: 'Eggs',
        isCompleted: true,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await storageService.addItem('list-1', item);
      expect(await storageService.clearCompleted('list-1'), isTrue);

      final stored = await storageService.getListByIdLocallyForTest('list-1');
      expect(stored!.items, isEmpty);
    });

    test('removes members from local lists', () async {
      final owner = ListMember(
        userId: 'owner-1',
        displayName: 'Owner',
        email: 'owner@test.com',
        role: MemberRole.owner,
        joinedAt: DateTime.now(),
        permissions: const {
          'read': true,
          'write': true,
          'delete': true,
          'share': true,
        },
      );
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );

      final list = ShoppingList(
        id: 'list-1',
        name: 'Shared List',
        description: 'Description',
        color: '#123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner, member],
      );

      await storageService.createList(list);

      expect(
        await storageService.removeMember('list-1', member.userId),
        isTrue,
      );

      final stored = await storageService.getListByIdLocallyForTest('list-1');
      expect(stored!.members.length, equals(1));
      expect(stored.members.first.userId, equals(owner.userId));
    });
  });

  group('StorageService (cloud routing overrides)', () {
    late StorageService storageService;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync('hive_storage_cloud');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ShoppingListAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ShoppingItemAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(MemberRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ListMemberAdapter());
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetInstanceForTest();
      FirestoreShoppingRepository.resetOverridesForTest();
      StorageService.setUseLocalOverrideForTest(false);
      storageService = StorageService.instance;
      await storageService.init();
    });

    tearDown(() async {
      await storageService.clearLocalDataForTest();
      FirestoreShoppingRepository.resetOverridesForTest();
      StorageService.resetInstanceForTest();

      try {
        if (Hive.isBoxOpen('shopping_lists')) {
          await Hive.box('shopping_lists').clear();
          await Hive.box('shopping_lists').close();
        }
      } catch (_) {}
    });

    ShoppingList buildList(String id, String name) {
      return ShoppingList(
        id: id,
        name: name,
        description: 'desc',
        color: '#123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test(
      'keeps migration pending and local data intact on partial failure',
      () async {
        await storageService.saveListLocallyForTest(
          buildList('local-1', 'One'),
        );
        await storageService.saveListLocallyForTest(
          buildList('local-2', 'Two'),
        );

        FirestoreShoppingRepository.setCreateListOverrideForTest((list) async {
          return list.id != 'local-2';
        });

        final success = await storageService.createList(
          buildList('cloud-1', 'Cloud New'),
        );
        expect(success, isTrue);

        expect(await storageService.isMigrationCompleteForTest(), isFalse);
        final stillLocal = await storageService.getAllListsLocallyForTest();
        expect(
          stillLocal.map((list) => list.id),
          containsAll(['local-1', 'local-2']),
        );

        FirestoreShoppingRepository.setCreateListOverrideForTest(
          (_) async => true,
        );

        final retrySuccess = await storageService.createList(
          buildList('cloud-2', 'Cloud Retry'),
        );
        expect(retrySuccess, isTrue);
        expect(await storageService.isMigrationCompleteForTest(), isTrue);

        final clearedLocal = await storageService.getAllListsLocallyForTest();
        expect(clearedLocal, isEmpty);
      },
    );

    test('propagates Firestore update and delete boolean results', () async {
      final list = buildList('cloud-1', 'Cloud');

      FirestoreShoppingRepository.setUpdateListOverrideForTest(
        (_) async => false,
      );
      expect(await storageService.updateList(list), isFalse);

      FirestoreShoppingRepository.setUpdateListOverrideForTest(
        (_) async => true,
      );
      expect(await storageService.updateList(list), isTrue);

      FirestoreShoppingRepository.setDeleteListOverrideForTest(
        (_) async => false,
      );
      expect(await storageService.deleteList('cloud-1'), isFalse);

      FirestoreShoppingRepository.setDeleteListOverrideForTest(
        (_) async => true,
      );
      expect(await storageService.deleteList('cloud-1'), isTrue);
    });

    test('preserves actionable share errors from Firestore repository', () async {
      const email = 'missing@example.com';

      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        targetEmail,
      ) async {
        throw UserNotFoundException(email);
      });
      final notFound = await storageService.shareList('list-1', email);
      expect(notFound.success, isFalse);
      expect(notFound.errorMessage, contains('not found'));
      expect(notFound.errorMessage, contains(email));

      FirestoreShoppingRepository.setShareListOverrideForTest((
        listId,
        targetEmail,
      ) async {
        throw UserAlreadyMemberException('Existing User');
      });
      final alreadyMember = await storageService.shareList('list-1', email);
      expect(alreadyMember.success, isFalse);
      expect(alreadyMember.errorMessage, contains('already a member'));
    });
  });
}
