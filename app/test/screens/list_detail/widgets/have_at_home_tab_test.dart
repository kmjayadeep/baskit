import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/share_result.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/screens/list_detail/widgets/have_at_home_tab.dart';
import 'package:baskit/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'owner-1';
}

class FakeAuthViewModel extends AuthViewModel {
  FakeAuthViewModel(this.authState);

  final AuthState authState;

  @override
  AuthState build() => authState;
}

class FakeRepository implements ShoppingRepository {
  final StreamController<ShoppingList?> _controller =
      StreamController<ShoppingList?>.broadcast();
  int updateItemCalls = 0;

  @override
  Stream<ShoppingList?> watchList(String id) => _controller.stream;

  @override
  Future<bool> addItem(String listId, ShoppingItem item) =>
      Future.value(true);

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
    updateItemCalls++;
    return Future.value(true);
  }

  @override
  Future<bool> deleteItem(String listId, String itemId) => Future.value(true);

  @override
  Future<bool> clearCompleted(String listId) => Future.value(true);

  @override
  Future<bool> createList(ShoppingList list) => Future.value(true);

  @override
  Future<bool> updateList(ShoppingList list) => Future.value(true);

  @override
  Future<bool> deleteList(String id) => Future.value(true);

  @override
  Stream<List<ShoppingList>> watchLists() => const Stream.empty();

  @override
  Future<ShareResult> shareList(String listId, String email) =>
      Future.value(ShareResult.success());

  @override
  Future<bool> removeMember(String listId, String userId) =>
      Future.value(true);

  @override
  Future<void> sync() async {}

  @override
  Future<DateTime?> getLastSyncTime() => Future.value(null);

  @override
  void disposeListStream(String id) {}

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('HaveAtHomeTab', () {
    const listId = 'tab-list';

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
        description: '',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner],
        items: <ShoppingItem>[
          ShoppingItem(
            id: 'have-1',
            name: 'Coffee',
            quantity: '1 kg',
            createdAt: DateTime.now(),
            listItemType: ItemType.haveAtHome,
          ),
          ShoppingItem(
            id: 'run-1',
            name: 'Sugar',
            quantity: '1 kg',
            createdAt: DateTime.now(),
            listItemType: ItemType.runOut,
            completedAt: DateTime.now(),
          ),
        ],
      );
    }

    Future<void> pumpTab(WidgetTester tester) async {
      final authState = AuthState(
        isGoogleUser: false,
        isAnonymous: true,
        isAuthenticated: true,
        isFirebaseAvailable: false,
        displayName: 'Owner',
        email: 'owner@test.com',
        user: FakeUser(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingRepositoryProvider.overrideWith((_) => FakeRepository()),
            authViewModelProvider.overrideWith(
              () => FakeAuthViewModel(authState),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HaveAtHomeTab(
                listId: listId,
                list: buildList(),
                canWrite: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('shows have-at-home and run-out items', (tester) async {
      await pumpTab(tester);

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Run out (1)'), findsOneWidget);
      // Run-out items are hidden in the collapsed section; expand to reveal.
      await tester.tap(find.text('Run out (1)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Sugar'), findsOneWidget);
    });

    testWidgets('shows the "Finished" and "Move back" actions', (
      tester,
    ) async {
      await pumpTab(tester);

      // Have-at-home item shows a Finished button.
      expect(find.text('Finished'), findsOneWidget);
      // Run-out section shows a Move back action when expanded.
      await tester.tap(find.text('Run out (1)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Move back'), findsOneWidget);
    });
  });
}
