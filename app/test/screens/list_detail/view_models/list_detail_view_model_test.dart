import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/share_result.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:baskit/view_models/auth_view_model.dart';

class FakeShoppingRepository implements ShoppingRepository {
  FakeShoppingRepository(this.listStream);

  final Stream<ShoppingList?> listStream;
  int watchListCalls = 0;
  int disposeListStreamCalls = 0;
  bool removeMemberResult = true;
  ShareResult shareResult = ShareResult.success();
  int removeMemberCalls = 0;
  int shareListCalls = 0;
  String? lastRemovedListId;
  String? lastRemovedUserId;
  String? lastSharedListId;
  String? lastSharedEmail;

  // Configurable results for new operations
  bool updateItemResult = true;
  bool addItemResult = true;
  bool clearCompletedResult = true;
  bool deleteListResult = true;
  int updateItemCalls = 0;
  int addItemCalls = 0;
  int clearCompletedCalls = 0;
  List<ShoppingItem> lastAddedItems = [];
  bool? lastCompletedValue;
  String? lastQuantity;
  bool lastClearQuantity = false;
  dynamic lastListItemTypeValue;
  DateTime? lastCompletedAtValue;
  bool lastClearCompletedAtValue = false;

  @override
  Stream<ShoppingList?> watchList(String id) {
    watchListCalls += 1;
    return listStream;
  }

  @override
  Future<bool> removeMember(String listId, String userId) async {
    removeMemberCalls += 1;
    lastRemovedListId = listId;
    lastRemovedUserId = userId;
    return removeMemberResult;
  }

  @override
  void disposeListStream(String id) {
    disposeListStreamCalls += 1;
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    addItemCalls += 1;
    lastAddedItems.add(item);
    return Future.value(addItemResult);
  }

  @override
  Future<bool> clearCompleted(String listId) {
    clearCompletedCalls += 1;
    return Future.value(clearCompletedResult);
  }

  @override
  Future<bool> createList(ShoppingList list) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteList(String id) async => deleteListResult;

  @override
  Future<void> dispose() async {}

  @override
  Future<DateTime?> getLastSyncTime() {
    throw UnimplementedError();
  }

  @override
  Future<void> init() {
    throw UnimplementedError();
  }

  @override
  Future<ShareResult> shareList(String listId, String email) {
    shareListCalls += 1;
    lastSharedListId = listId;
    lastSharedEmail = email;
    return Future.value(shareResult);
  }

  @override
  Future<void> sync() {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    dynamic listItemType,
    bool clearQuantity = false,
  }) {
    updateItemCalls += 1;
    lastCompletedValue = completed;
    lastQuantity = quantity;
    lastClearQuantity = clearQuantity;
    lastListItemTypeValue = listItemType;
    lastCompletedAtValue = completedAt;
    lastClearCompletedAtValue = clearCompletedAt;
    return Future.value(updateItemResult);
  }

  @override
  Future<bool> updateList(ShoppingList list) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ShoppingList>> watchLists() {
    throw UnimplementedError();
  }
}

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

class MutableFakeAuthViewModel extends AuthViewModel {
  MutableFakeAuthViewModel(this.initialAuthState);

  final AuthState initialAuthState;

  @override
  AuthState build() => initialAuthState;

  void setAuthState(AuthState authState) {
    state = authState;
  }
}

void main() {
  group('ListDetailViewModel lifecycle', () {
    const listId = 'list-lifecycle';
    late StreamController<ShoppingList?> listController;
    late FakeShoppingRepository repository;
    late TestUser user;
    late AuthState authState;
    late int activeListeners;

    setUp(() {
      activeListeners = 0;
      listController = StreamController<ShoppingList?>.broadcast(
        onListen: () => activeListeners += 1,
        onCancel: () => activeListeners -= 1,
      );
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
      authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Member',
        email: 'member@test.com',
        user: user,
      );
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer() {
      return ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
    }

    test('cancels watchList subscription on dispose', () async {
      final container = buildContainer();
      container.read(listDetailViewModelProvider(listId));

      await Future<void>.delayed(Duration.zero);
      expect(repository.watchListCalls, equals(1));
      expect(activeListeners, equals(1));

      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(activeListeners, equals(0));
      expect(repository.disposeListStreamCalls, equals(1));
    });

    test(
      'keeps single active watchList subscription across rebuilds',
      () async {
        final container = buildContainer();

        container.read(listDetailViewModelProvider(listId));
        await Future<void>.delayed(Duration.zero);
        expect(repository.watchListCalls, equals(1));
        expect(activeListeners, equals(1));

        container.invalidate(listDetailViewModelProvider(listId));
        container.read(listDetailViewModelProvider(listId));
        await Future<void>.delayed(Duration.zero);

        expect(repository.watchListCalls, equals(2));
        expect(activeListeners, equals(1));

        container.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(activeListeners, equals(0));
      },
    );

    test('retryLoad resets loading state and recreates list stream', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await Future<void>.delayed(Duration.zero);
      listController.addError(Exception('temporary failure'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchListCalls, equals(1));
      expect(
        container.read(listDetailViewModelProvider(listId)).hasLoadError,
        isTrue,
      );

      viewModel.retryLoad();
      expect(
        container.read(listDetailViewModelProvider(listId)).isLoading,
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchListCalls, equals(2));
      expect(activeListeners, equals(1));

      final list = ShoppingList(
        id: listId,
        name: 'Recovered List',
        description: 'Recovered after retry',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: user.userId,
      );
      listController.add(list);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(listDetailViewModelProvider(listId));
      expect(state.list, equals(list));
      expect(state.error, isNull);
    });

    test('auth user changes recreate list stream', () async {
      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => MutableFakeAuthViewModel(authState),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen<ListDetailState>(
        listDetailViewModelProvider(listId),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchListCalls, equals(1));
      expect(activeListeners, equals(1));

      final authViewModel =
          container.read(authViewModelProvider.notifier)
              as MutableFakeAuthViewModel;
      authViewModel.setAuthState(
        AuthState(
          isGoogleUser: false,
          isAnonymous: false,
          isAuthenticated: true,
          isFirebaseAvailable: false,
          displayName: 'Other Member',
          email: 'other@test.com',
          user: TestUser('member-2'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.watchListCalls, equals(2));
      expect(activeListeners, equals(1));
      expect(
        container.read(listDetailViewModelProvider(listId)).isLoading,
        isTrue,
      );
    });
  });

  group('ListDetailViewModel Leave List Tests', () {
    const listId = 'list-123';
    late FakeShoppingRepository repository;
    late StreamController<ShoppingList?> listController;
    late TestUser user;

    setUp(() {
      listController = StreamController<ShoppingList?>.broadcast();
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer({required AuthState authState}) {
      return ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
    }

    ShoppingList buildList({
      required String ownerId,
      required List<ListMember> members,
    }) {
      return ShoppingList(
        id: listId,
        name: 'Shared List',
        description: 'Test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: ownerId,
        members: members,
      );
    }

    Future<void> emitList(ShoppingList list) async {
      listController.add(list);
      await Future<void>.delayed(Duration.zero);
    }

    test('leaveList removes current user when not owner', () async {
      final currentMember = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
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

      final list = buildList(
        ownerId: owner.userId,
        members: [owner, currentMember],
      );
      repository.removeMemberResult = true;

      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Member',
        email: 'member@test.com',
        user: user,
      );

      final container = buildContainer(authState: authState);
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.leaveList();
      expect(result.isSuccess, isTrue);
      expect(repository.removeMemberCalls, equals(1));
      expect(repository.lastRemovedListId, listId);
      expect(repository.lastRemovedUserId, currentMember.userId);
    });

    test('leaveList fails when current user is the owner', () async {
      final owner = ListMember(
        userId: 'member-1',
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

      final list = buildList(ownerId: owner.userId, members: [owner]);

      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
      );

      final container = buildContainer(authState: authState);
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.leaveList();
      expect(result.isSuccess, isFalse);
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        'List owners cannot leave their own list',
      );
      expect(repository.removeMemberCalls, equals(0));
    });

    test('removeMember denies non-owner removing others', () async {
      final currentMember = ListMember(
        userId: 'member-1',
        displayName: 'Member',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
      final otherMember = ListMember(
        userId: 'member-2',
        displayName: 'Other',
        email: 'other@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
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

      final list = buildList(
        ownerId: owner.userId,
        members: [owner, currentMember, otherMember],
      );

      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Member',
        email: 'member@test.com',
        user: user,
      );

      final container = buildContainer(authState: authState);
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.removeMember(otherMember.userId);
      expect(result.isSuccess, isFalse);
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        'Only the list owner can manage members',
      );
      expect(repository.removeMemberCalls, equals(0));
    });

    test('removeMember allows owner to remove members', () async {
      final owner = ListMember(
        userId: 'member-1',
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
      final otherMember = ListMember(
        userId: 'member-2',
        displayName: 'Other',
        email: 'other@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );

      final list = buildList(
        ownerId: owner.userId,
        members: [owner, otherMember],
      );
      repository.removeMemberResult = true;

      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
      );

      final container = buildContainer(authState: authState);
      addTearDown(container.dispose);

      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.removeMember(otherMember.userId);
      expect(result.isSuccess, isTrue);
      expect(repository.removeMemberCalls, equals(1));
      expect(repository.lastRemovedListId, listId);
      expect(repository.lastRemovedUserId, otherMember.userId);
    });

    test(
      'shareList surfaces specific not-found message from repository',
      () async {
        final owner = ListMember(
          userId: 'member-1',
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
        final list = buildList(ownerId: owner.userId, members: [owner]);
        repository.shareResult = ShareResult.error(
          'User with email missing@test.com not found.\n\nMake sure they have signed up for the app first, then try sharing again.',
        );

        final authState = AuthState(
          isGoogleUser: false,
          isAnonymous: false,
          isAuthenticated: true,
          isFirebaseAvailable: false,
          displayName: 'Owner',
          email: 'owner@test.com',
          user: user,
        );

        final container = buildContainer(authState: authState);
        addTearDown(container.dispose);
        final viewModel = container.read(
          listDetailViewModelProvider(listId).notifier,
        );

        await emitList(list);

        final success = await viewModel.shareList('missing@test.com');
        final error = container.read(listDetailViewModelProvider(listId)).error;

        expect(success.isSuccess, isFalse);
        expect(repository.shareListCalls, equals(1));
        expect(repository.lastSharedListId, listId);
        expect(repository.lastSharedEmail, 'missing@test.com');
        expect(error, contains('User with email missing@test.com not found.'));
      },
    );

    test(
      'shareList surfaces specific already-member message from repository',
      () async {
        final owner = ListMember(
          userId: 'member-1',
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
        final list = buildList(ownerId: owner.userId, members: [owner]);
        repository.shareResult = ShareResult.error(
          'This user is already a member of this list.',
        );

        final authState = AuthState(
          isGoogleUser: false,
          isAnonymous: false,
          isAuthenticated: true,
          isFirebaseAvailable: false,
          displayName: 'Owner',
          email: 'owner@test.com',
          user: user,
        );

        final container = buildContainer(authState: authState);
        addTearDown(container.dispose);
        final viewModel = container.read(
          listDetailViewModelProvider(listId).notifier,
        );

        await emitList(list);

        final success = await viewModel.shareList('member@test.com');
        final error = container.read(listDetailViewModelProvider(listId)).error;

        expect(success.isSuccess, isFalse);
        expect(repository.shareListCalls, equals(1));
        expect(error, contains('This user is already a member of this list.'));
      },
    );
  });

  group('ListDetailViewModel Undo Tests', () {
    const listId = 'list-undo';
    late FakeShoppingRepository repository;
    late StreamController<ShoppingList?> listController;
    late TestUser user;
    late AuthState authState;

    ShoppingItem buildItem({
      String id = 'item-1',
      String name = 'Milk',
      bool isCompleted = false,
      String? quantity,
    }) {
      return ShoppingItem(
        id: id,
        name: name,
        quantity: quantity,
        isCompleted: isCompleted,
        createdAt: DateTime.now(),
        completedAt: null,
      );
    }

    ShoppingList buildListWithItems(List<ShoppingItem> items) {
      return ShoppingList(
        id: listId,
        name: 'Test List',
        description: '',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: 'member-1',
        members: [
          ListMember(
            userId: 'member-1',
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
          ),
        ],
        items: items,
      );
    }

    setUp(() {
      listController = StreamController<ShoppingList?>.broadcast();
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
      authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
      );
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer() {
      return ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(authState),
          ),
        ],
      );
    }

    Future<void> emitList(ShoppingList list) async {
      listController.add(list);
      await Future<void>.delayed(Duration.zero);
    }

    test('addItem reports repository rejection and resets loading', () async {
      repository.addItemResult = false;
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([]));

      final result = await viewModel.addItem('Bread', null);
      expect(result.isSuccess, isFalse);
      expect(repository.addItemCalls, 1);
      expect(
        container.read(listDetailViewModelProvider(listId)).isAddingItem,
        isFalse,
      );
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        contains('Failed to add item'),
      );
      // The ListActionException type prefix must not leak into the message.
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        isNot(contains('ListAction')),
      );
    });

    test('toggleItemCompletion reports repository rejection', () async {
      repository.updateItemResult = false;
      final item = buildItem();
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.toggleItemCompletion(item);
      expect(result.isSuccess, isFalse);
      expect(repository.updateItemCalls, 1);
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        contains('Failed to update item'),
      );
    });

    test('deleteList reports repository rejection', () async {
      repository.deleteListResult = false;
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([]));

      final result = await viewModel.deleteList();
      expect(result.isSuccess, isFalse);
      expect(
        container.read(listDetailViewModelProvider(listId)).error,
        contains('Failed to delete list'),
      );
    });

    test('clearCompletedItems succeeds when has completed items', () async {
      final pendingItem = buildItem(id: 'item-1', name: 'Milk');
      final completedItem = buildItem(
        id: 'item-2',
        name: 'Bread',
        isCompleted: true,
      );
      final list = buildListWithItems([pendingItem, completedItem]);
      repository.clearCompletedResult = true;

      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.clearCompletedItems();
      expect(result.isSuccess, isTrue);
      expect(repository.clearCompletedCalls, equals(1));
    });

    test('clearCompletedItems stores error on failure', () async {
      final completedItem = buildItem(
        id: 'item-2',
        name: 'Bread',
        isCompleted: true,
      );
      final list = buildListWithItems([completedItem]);
      repository.clearCompletedResult = false;

      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(list);

      final result = await viewModel.clearCompletedItems();
      expect(result.isSuccess, isFalse);

      final state = container.read(listDetailViewModelProvider(listId));
      expect(state.error, contains('Error clearing completed items'));
    });
  });

  group('ListDetailViewModel editItem clear-quantity', () {
    const listId = 'list-edit-quantity';
    late FakeShoppingRepository repository;
    late StreamController<ShoppingList?> listController;
    late TestUser user;
    late AuthState authState;

    ShoppingItem buildItem({String id = 'item-1', String name = 'Milk'}) =>
        ShoppingItem(
          id: id,
          name: name,
          quantity: '2',
          isCompleted: false,
          createdAt: DateTime.now(),
          completedAt: null,
        );

    ShoppingList buildListWithItems(List<ShoppingItem> items) => ShoppingList(
      id: listId,
      name: 'Test List',
      description: '',
      color: '#FF0000',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      ownerId: 'member-1',
      members: [
        ListMember(
          userId: 'member-1',
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
        ),
      ],
      items: items,
    );

    setUp(() {
      listController = StreamController<ShoppingList?>.broadcast();
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
      authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
      );
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer() => ProviderContainer(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(repository),
        authViewModelProvider.overrideWith(() => FakeAuthViewModel(authState)),
      ],
    );

    Future<void> emitList(ShoppingList list) async {
      listController.add(list);
      await Future<void>.delayed(Duration.zero);
    }

    test('clears quantity when the edited quantity field is blank', () async {
      final item = buildItem();
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );

      await emitList(buildListWithItems([item]));

      final result = await viewModel.editItem(item, 'Milk', '   ');

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, 1);
      expect(repository.lastClearQuantity, isTrue);
    });

    test(
      'keeps quantity when a non-blank value is edited',
      () async {
        final item = buildItem();
        final container = buildContainer();
        addTearDown(container.dispose);
        final viewModel = container.read(
          listDetailViewModelProvider(listId).notifier,
        );

        await emitList(buildListWithItems([item]));

        final result = await viewModel.editItem(item, 'Milk', '5');

        expect(result.isSuccess, isTrue);
        expect(repository.updateItemCalls, 1);
        expect(repository.lastClearQuantity, isFalse);
        expect(repository.lastQuantity, '5');
      },
    );
  });

  group('ListDetailViewModel Have at Home (Phase 2)', () {
    const listId = 'list-have-at-home';
    late FakeShoppingRepository repository;
    late StreamController<ShoppingList?> listController;
    late TestUser user;

    ShoppingItem buildItem({
      String id = 'item-1',
      String name = 'Milk',
      bool isCompleted = false,
      ItemType listItemType = ItemType.needsPurchase,
      DateTime? completedAt,
    }) {
      return ShoppingItem(
        id: id,
        name: name,
        isCompleted: isCompleted,
        createdAt: DateTime.now(),
        completedAt: completedAt,
        listItemType: listItemType,
      );
    }

    ShoppingList buildListWithItems(List<ShoppingItem> items) {
      return ShoppingList(
        id: listId,
        name: 'Test List',
        description: '',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: 'member-1',
        members: [
          ListMember(
            userId: 'member-1',
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
          ),
        ],
        items: items,
      );
    }

    setUp(() {
      listController = StreamController<ShoppingList?>.broadcast();
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer() {
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: user,
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

    Future<void> emitList(ShoppingList list) async {
      listController.add(list);
      await Future<void>.delayed(Duration.zero);
    }

    test('addItemToHaveAtHome adds an item typed haveAtHome', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([]));

      final result = await viewModel.addItemToHaveAtHome('Coffee', '1kg');

      expect(result.isSuccess, isTrue);
      expect(repository.addItemCalls, equals(1));
      expect(repository.lastAddedItems.single.name, 'Coffee');
      expect(repository.lastAddedItems.single.quantity, '1kg');
      expect(repository.lastAddedItems.single.listItemType, ItemType.haveAtHome);
    });

    test('addItemToHaveAtHome fails on blank name', () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([]));

      final result = await viewModel.addItemToHaveAtHome('   ', '1kg');

      expect(result.isSuccess, isFalse);
      expect(repository.addItemCalls, equals(0));
    });

    test('finishHaveAtHomeItem moves item to runOut and sets completedAt', () async {
      final item = buildItem(
        id: 'have-1',
        name: 'Coffee',
        listItemType: ItemType.haveAtHome,
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.finishHaveAtHomeItem(item);

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, equals(1));
      expect(repository.lastListItemTypeValue, ItemType.runOut);
      expect(repository.lastCompletedAtValue, isNotNull);
      expect(repository.lastClearCompletedAtValue, isFalse);
      expect(repository.lastCompletedValue, isNull);
    });

    test('markBackToHaveAtHome moves item back and clears completedAt', () async {
      final item = buildItem(
        id: 'run-1',
        name: 'Coffee',
        listItemType: ItemType.runOut,
        completedAt: DateTime(2026, 10, 1),
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.markBackToHaveAtHome(item);

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, equals(1));
      expect(repository.lastListItemTypeValue, ItemType.haveAtHome);
      expect(repository.lastClearCompletedAtValue, isTrue);
      expect(repository.lastCompletedValue, isNull);
    });

    test('toggleItemCompletion rejects have-at-home items', () async {
      final item = buildItem(
        id: 'have-1',
        name: 'Coffee',
        listItemType: ItemType.haveAtHome,
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.toggleItemCompletion(item);

      expect(result.isSuccess, isFalse);
      expect(repository.updateItemCalls, equals(0));
    });

    test('toggleItemCompletion rejects run-out items', () async {
      final item = buildItem(
        id: 'run-1',
        name: 'Coffee',
        listItemType: ItemType.runOut,
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.toggleItemCompletion(item);

      expect(result.isSuccess, isFalse);
      expect(repository.updateItemCalls, equals(0));
    });

    test('toggleItemCompletion still works for shopping items', () async {
      final item = buildItem(id: 'item-1', name: 'Milk');
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildListWithItems([item]));

      final result = await viewModel.toggleItemCompletion(item);

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, equals(1));
      expect(repository.lastCompletedValue, isTrue);
    });
  });

  group('ListDetailViewModel Have at Home permission guard', () {
    const listId = 'list-have-at-home-perms';
    late FakeShoppingRepository repository;
    late StreamController<ShoppingList?> listController;
    late TestUser user;

    ShoppingItem buildItem({
      String id = 'item-1',
      String name = 'Coffee',
      ItemType type = ItemType.haveAtHome,
    }) {
      return ShoppingItem(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        listItemType: type,
      );
    }

    ShoppingList buildList(ListMember member) {
      return ShoppingList(
        id: listId,
        name: 'Test List',
        description: '',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: member.userId,
        members: [member],
        items: <ShoppingItem>[],
      );
    }

    setUp(() {
      listController = StreamController<ShoppingList?>.broadcast();
      repository = FakeShoppingRepository(listController.stream);
      user = TestUser('member-1');
    });

    tearDown(() async {
      await listController.close();
    });

    ProviderContainer buildContainer() {
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: false,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Member',
        email: 'member@test.com',
        user: user,
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

    Future<void> emitList(ShoppingList list) async {
      listController.add(list);
      await Future<void>.delayed(Duration.zero);
    }

    test('owner can finish a have-at-home item', () async {
      final member = ListMember(
        userId: 'member-1',
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
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildList(member));

      final result = await viewModel.finishHaveAtHomeItem(buildItem());

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, equals(1));
    });

    test('member without write permission cannot finish a have-at-home item', (
      ) async {
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Viewer',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true},
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildList(member));

      final result = await viewModel.finishHaveAtHomeItem(buildItem());

      expect(result.isSuccess, isFalse);
      expect(repository.updateItemCalls, equals(0));
    });

    test('member with write permission can finish a have-at-home item', (
      ) async {
      final member = ListMember(
        userId: 'member-1',
        displayName: 'Editor',
        email: 'member@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true, 'write': true},
      );
      final container = buildContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        listDetailViewModelProvider(listId).notifier,
      );
      await emitList(buildList(member));

      final result = await viewModel.finishHaveAtHomeItem(buildItem());

      expect(result.isSuccess, isTrue);
      expect(repository.updateItemCalls, equals(1));
    });
  });
}
