import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/repositories/storage_shopping_repository.dart';
import 'package:baskit/services/storage_service.dart';

void main() {
  group('StorageShoppingRepository Member Tests', () {
    late StorageService storageService;
    late StorageShoppingRepository repository;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_repository_test',
      );
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
      repository = StorageShoppingRepository(storageService);
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

    test('removes a non-owner member from a list', () async {
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
        description: 'Test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner, member],
      );

      final created = await storageService.createList(list);
      expect(created, isTrue);

      final result = await repository.removeMember(list.id, member.userId);
      expect(result, isTrue);

      final storedList = await storageService.getListByIdLocallyForTest(
        list.id,
      );
      expect(storedList, isNotNull);
      expect(storedList!.members.length, equals(1));
      expect(storedList.members.first.userId, equals(owner.userId));
    });

    test('does not remove the owner from a list', () async {
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
      final list = ShoppingList(
        id: 'list-2',
        name: 'Owner List',
        description: 'Owner-only',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner],
      );

      await storageService.createList(list);

      final result = await repository.removeMember(list.id, owner.userId);
      expect(result, isFalse);

      final storedList = await storageService.getListByIdLocallyForTest(
        list.id,
      );
      expect(storedList, isNotNull);
      expect(storedList!.members.length, equals(1));
      expect(storedList.members.first.userId, equals(owner.userId));
    });
  });
}
