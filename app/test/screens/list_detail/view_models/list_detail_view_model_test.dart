import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:baskit/services/storage_service.dart' show ShareResult;
import 'package:baskit/view_models/auth_view_model.dart';

class FakeShoppingRepository implements ShoppingRepository {
  FakeShoppingRepository(this.listStream);

  final Stream<ShoppingList?> listStream;
  bool removeMemberResult = true;
  int removeMemberCalls = 0;
  String? lastRemovedListId;
  String? lastRemovedUserId;

  @override
  Stream<ShoppingList?> watchList(String id) => listStream;

  @override
  Future<bool> removeMember(String listId, String userId) async {
    removeMemberCalls += 1;
    lastRemovedListId = listId;
    lastRemovedUserId = userId;
    return removeMemberResult;
  }

  @override
  void disposeListStream(String id) {}

  @override
  Future<bool> addItem(String listId, ShoppingItem item) {
    throw UnimplementedError();
  }

  @override
  Future<bool> clearCompleted(String listId) {
    throw UnimplementedError();
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
  Future<bool> deleteList(String id) {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

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
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
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

void main() {
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
      expect(result, isTrue);
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
      expect(result, isFalse);
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
      expect(result, isFalse);
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
      expect(result, isTrue);
      expect(repository.removeMemberCalls, equals(1));
      expect(repository.lastRemovedListId, listId);
      expect(repository.lastRemovedUserId, otherMember.userId);
    });
  });
}
