import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/storage_shopping_repository.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:baskit/services/storage_service.dart';
import 'package:baskit/view_models/auth_view_model.dart';

class TestUser extends Fake implements User {
  TestUser(this.userId);

  final String userId;

  @override
  String get uid => userId;
}

class FakeAuthViewModel extends AuthViewModel {
  FakeAuthViewModel(this.authState);

  final AuthState authState;

  @override
  AuthState build() => authState;
}

void main() {
  group('Leave List Flow Integration Tests', () {
    late StorageService storageService;
    late StorageShoppingRepository repository;

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_leave_list_test',
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

    test('member can leave a shared list', () async {
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
        description: 'Integration test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner, member],
      );

      await storageService.createList(list);

      final user = TestUser(member.userId);
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Member',
        email: 'member@test.com',
        user: user,
      );

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(list.id).notifier,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final result = await viewModel.leaveList();
      expect(result, isTrue);

      final storedList = await storageService.getListByIdLocallyForTest(
        list.id,
      );
      expect(storedList, isNotNull);
      expect(storedList!.members.length, equals(1));
      expect(storedList.members.first.userId, equals(owner.userId));
    });

    test('owner cannot leave their own list', () async {
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
        description: 'Integration test owner list',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner],
      );

      await storageService.createList(list);

      final user = TestUser(owner.userId);
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
      );

      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(list.id).notifier,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final result = await viewModel.leaveList();
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
