import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/storage_shopping_repository.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:baskit/services/local_storage_service.dart';
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
  group('Have at Home lifecycle (integration)', () {
    late StorageShoppingRepository repository;
    const listId = 'have-at-home-list';

    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync(
        'hive_have_at_home_test',
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
      StorageShoppingRepository.resetOverridesForTest();
      await LocalStorageService.resetInstanceForTest();
      repository = StorageShoppingRepository.instance();
      await repository.init();
    });

    tearDown(() async {
      await repository.clearLocalDataForTest();
      await repository.dispose();
      StorageShoppingRepository.resetOverridesForTest();
      await LocalStorageService.resetInstanceForTest();

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

    ProviderContainer buildContainer() {
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: TestUser('owner-1'),
      );
      return ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
    }

    ShoppingList buildList() {
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
      return ShoppingList(
        id: listId,
        name: 'Groceries',
        description: 'Integration test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner],
        items: <ShoppingItem>[],
      );
    }

    Future<void> setupList(ProviderContainer container) async {
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await repository.createList(buildList());
      viewModel.retryLoad();
      // Let the subscription settle.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    Future<ShoppingItem> watchFirstItem() async {
      final list = await repository.watchList(listId).first;
      return list!.items.first;
    }

    test('add a have-at-home item, finish it, move it back', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await setupList(container);

      // Add a have-at-home item.
      final addResult = await container.read(
        listDetailViewModelProvider(listId).notifier,
      ).addItemToHaveAtHome('Coffee', '1kg');
      expect(addResult.isSuccess, isTrue);

      // The item exists with a haveAtHome type.
      final item = await watchFirstItem();
      expect(item.listItemType, ItemType.haveAtHome);

      // Finish it -> becomes a run-out item with a completedAt timestamp.
      final finishResult = await container.read(
        listDetailViewModelProvider(listId).notifier,
      ).finishHaveAtHomeItem(item);
      expect(finishResult.isSuccess, isTrue);

      final finished = await watchFirstItem();
      expect(finished.listItemType, ItemType.runOut);
      expect(finished.completedAt, isNotNull);

      // Move it back -> back to haveAtHome with completedAt cleared.
      final moveBackResult = await container.read(
        listDetailViewModelProvider(listId).notifier,
      ).markBackToHaveAtHome(finished);
      expect(moveBackResult.isSuccess, isTrue);

      final moved = await watchFirstItem();
      expect(moved.listItemType, ItemType.haveAtHome);
      expect(moved.completedAt, isNull);
    });

    test('toggleItemCompletion rejects have-at-home items', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      await setupList(container);

      final item = ShoppingItem(
        id: 'have-1',
        name: 'Coffee',
        createdAt: DateTime.now(),
        listItemType: ItemType.haveAtHome,
      );
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      final result = await viewModel.toggleItemCompletion(item);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Finished or Move back'));
    });
  });
}
