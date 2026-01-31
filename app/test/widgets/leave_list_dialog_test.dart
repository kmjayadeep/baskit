import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/list_detail_screen.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/leave_list_confirmation_dialog.dart';
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

class _FakeListDetailViewModel extends ListDetailViewModel {
  _FakeListDetailViewModel(
    super.listId, {
    required this.initialState,
    required this.leaveListResult,
  });

  final ListDetailState initialState;
  final bool leaveListResult;
  int leaveListCalls = 0;

  @override
  ListDetailState build() => initialState;

  @override
  Future<bool> leaveList() async {
    leaveListCalls += 1;
    return leaveListResult;
  }
}

void main() {
  group('LeaveListConfirmationDialog', () {
    late ShoppingList list;

    setUp(() {
      list = ShoppingList(
        id: 'list-1',
        name: 'Team Groceries',
        description: 'Shared list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        members: const [],
      );
    });

    testWidgets('shows dialog content and handles cancel', (
      WidgetTester tester,
    ) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) =>
                                LeaveListConfirmationDialog(list: list),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Leave List'), findsNWidgets(2));
      expect(
        find.text(
          'Are you sure you want to leave "Team Groceries"? You will lose access to this list unless you are invited again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });

    testWidgets('confirms leave action', (WidgetTester tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      dialogResult = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) =>
                                LeaveListConfirmationDialog(list: list),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Leave List'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });

  group('Leave list menu action', () {
    late TestUser user;
    late ShoppingList list;
    late AuthState authState;

    setUp(() {
      user = TestUser('member-1');

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

      list = ShoppingList(
        id: 'list-1',
        name: 'Shared List',
        description: 'Test list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ownerId: owner.userId,
        members: [owner, member],
      );

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

    testWidgets('shows leave list menu and triggers view model', (
      WidgetTester tester,
    ) async {
      late _FakeListDetailViewModel fakeViewModel;

      fakeViewModel = _FakeListDetailViewModel(
        list.id,
        initialState: ListDetailState.loaded(list),
        leaveListResult: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listDetailViewModelProvider(
              list.id,
            ).overrideWith(() => fakeViewModel),
            authViewModelProvider.overrideWith(
              () => FakeAuthViewModel(authState),
            ),
          ],
          child: MaterialApp(home: ListDetailScreen(listId: list.id)),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Leave List'), findsOneWidget);

      await tester.tap(find.text('Leave List'));
      await tester.pumpAndSettle();

      expect(find.byType(LeaveListConfirmationDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Leave List'));
      await tester.pumpAndSettle();

      expect(fakeViewModel.leaveListCalls, equals(1));
    });
  });
}
