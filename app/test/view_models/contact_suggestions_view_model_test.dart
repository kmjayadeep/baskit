import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/contact_suggestion_model.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/share_result.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/services/contact_suggestions_service.dart';
import 'package:baskit/view_models/auth_view_model.dart';
import 'package:baskit/view_models/contact_suggestions_view_model.dart';

class FakeShoppingRepository implements ShoppingRepository {
  FakeShoppingRepository(this.listsStream);

  final Stream<List<ShoppingList>> listsStream;
  int watchListsCalls = 0;

  @override
  Stream<List<ShoppingList>> watchLists() {
    watchListsCalls += 1;
    return listsStream;
  }

  @override
  Future<bool> addItem(String listId, ShoppingItem item) =>
      throw UnimplementedError();

  @override
  Future<bool> clearCompleted(String listId) => throw UnimplementedError();

  @override
  Future<bool> createList(ShoppingList list) => throw UnimplementedError();

  @override
  Future<bool> deleteItem(String listId, String itemId) =>
      throw UnimplementedError();

  @override
  Future<bool> deleteList(String id) => throw UnimplementedError();

  @override
  void dispose() {}

  @override
  void disposeListStream(String id) {}

  @override
  Future<DateTime?> getLastSyncTime() => throw UnimplementedError();

  @override
  Future<void> init() => throw UnimplementedError();

  @override
  Future<bool> removeMember(String listId, String userId) =>
      throw UnimplementedError();

  @override
  Future<ShareResult> shareList(String listId, String email) =>
      throw UnimplementedError();

  @override
  Future<void> sync() => throw UnimplementedError();

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) => throw UnimplementedError();

  @override
  Future<bool> updateList(ShoppingList list) => throw UnimplementedError();

  @override
  Stream<ShoppingList?> watchList(String id) => throw UnimplementedError();
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
  group('ContactSuggestionsState', () {
    const contact = ContactSuggestion(
      userId: 'member_user',
      email: 'member@test.com',
      displayName: 'Member User',
      sharedListsCount: 2,
    );
    const otherContact = ContactSuggestion(
      userId: 'other_user',
      email: 'other@test.com',
      displayName: 'Other User',
      sharedListsCount: 1,
    );

    test('compares contact list contents instead of list identity', () {
      final state = ContactSuggestionsState.loaded([contact, otherContact]);
      final sameContents = ContactSuggestionsState.loaded([
        contact,
        otherContact,
      ]);

      expect(state, equals(sameContents));
      expect(state.hashCode, equals(sameContents.hashCode));
    });

    test('detects different contact list contents', () {
      final state = ContactSuggestionsState.loaded([contact, otherContact]);
      final reordered = ContactSuggestionsState.loaded([otherContact, contact]);
      final missingContact = ContactSuggestionsState.loaded([contact]);

      expect(state, isNot(equals(reordered)));
      expect(state, isNot(equals(missingContact)));
    });
  });

  group('ContactSuggestionsViewModel', () {
    late StreamController<List<ShoppingList>> listsController;
    late FakeShoppingRepository repository;

    setUp(() {
      ContactSuggestionsService.clearCache();
      listsController = StreamController<List<ShoppingList>>();
      repository = FakeShoppingRepository(listsController.stream);
    });

    tearDown(() async {
      ContactSuggestionsService.clearCache();
      await listsController.close();
    });

    test('loads contacts through shoppingRepositoryProvider', () async {
      final container = ProviderContainer(
        overrides: [
          shoppingRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith(
            () => FakeAuthViewModel(
              AuthState(
                isGoogleUser: true,
                isAnonymous: false,
                isAuthenticated: true,
                isFirebaseAvailable: true,
                displayName: 'Current User',
                email: 'current@test.com',
                user: TestUser('current_user'),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(contactSuggestionsViewModelProvider);
      await Future<void>.delayed(Duration.zero);

      listsController.add([
        ShoppingList(
          id: 'shared-list',
          name: 'Shared List',
          description: 'Description',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          members: [
            ListMember(
              userId: 'current_user',
              displayName: 'Current User',
              email: 'current@test.com',
              role: MemberRole.owner,
              joinedAt: DateTime.now(),
              permissions: const {'read': true, 'write': true},
            ),
            ListMember(
              userId: 'member_user',
              displayName: 'Member User',
              email: 'member@test.com',
              role: MemberRole.member,
              joinedAt: DateTime.now(),
              permissions: const {'read': true, 'write': true},
            ),
          ],
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(contactSuggestionsViewModelProvider);

      expect(repository.watchListsCalls, equals(1));
      expect(state.isLoading, isFalse);
      expect(state.contacts, hasLength(1));
      expect(state.contacts.single.userId, equals('member_user'));
    });
  });
}
