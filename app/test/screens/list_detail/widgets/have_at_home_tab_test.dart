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
  final ShoppingList? _emittedList;

  FakeRepository([this._emittedList]);

  @override
  Stream<ShoppingList?> watchList(String id) => _controller
      .stream
      .asBroadcastStream(onListen: (_) => _controller.add(_emittedList));

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
            shoppingRepositoryProvider.overrideWith((_) =>
                FakeRepository(buildList())),
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

    testWidgets('tapping Finished finishes the have-at-home item', (
      tester,
    ) async {
      await pumpTab(tester);

      // Tap the have-at-home item card body (tap = finish).
      await tester.tap(find.text('Coffee'));
      // Short pump so the snackbar appears but isn't auto-dismissed.
      await tester.pump(const Duration(milliseconds: 100));

      // Success path shows a snackbar confirming the finish.
      expect(find.text('Coffee marked finished'), findsOneWidget);
    });

    testWidgets('tapping Move back restores the run-out item', (
      tester,
    ) async {
      await pumpTab(tester);

      // Expand the run-out section to reveal the Sugar card.
      await tester.tap(find.text('Run out (1)'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      // Tap the card body (the item name) — the InkWell wrapping the card
      // routes to the same move-back handler as the "Move back" button.
      await tester.tap(find.text('Sugar'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Sugar moved back to Have at Home'),
        findsOneWidget,
      );
    });

    testWidgets('deleting via the actions menu opens the delete option', (
      tester,
    ) async {
      await pumpTab(tester);

      // Open the actions menu on the have-at-home item.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pump(const Duration(milliseconds: 100));

      // The Delete option is present and tappable.
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump(const Duration(milliseconds: 100));

      // Menu closes after selecting Delete.
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('tapping the add button adds a have-at-home item', (
      tester,
    ) async {
      await pumpTab(tester);

      await tester.enterText(find.byType(TextField).first, 'Milk');
      await tester.tap(find.widgetWithText(
        ElevatedButton,
        'Add',
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('toggling the quantity field reveals the input', (
      tester,
    ) async {
      await pumpTab(tester);

      // The quantity field is hidden initially.
      expect(find.byKey(const ValueKey('have-at-home-quantity-hidden')),
          findsOneWidget);

      // Tap the suffix icon to reveal the quantity field.
      await tester.tap(find.byIcon(Icons.notes_outlined));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('have-at-home-quantity')),
          findsOneWidget);
    });
  });
}
