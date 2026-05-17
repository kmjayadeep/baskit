import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/member_list_dialog.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/remove_member_confirmation_dialog.dart';

void main() {
  group('RemoveMemberConfirmationDialog', () {
    late ShoppingList list;
    late ListMember member;

    setUp(() {
      member = ListMember(
        userId: 'member-1',
        displayName: 'Riley',
        email: 'riley@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true},
      );
      list = ShoppingList(
        id: 'list-1',
        name: 'Team Groceries',
        description: 'Shared list',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        members: [member],
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
                            (context) => RemoveMemberConfirmationDialog(
                              list: list,
                              member: member,
                            ),
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

      expect(find.text('Remove member'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Remove Member'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Remove Riley from "Team Groceries"? They will lose access to this list unless they are invited again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });

    testWidgets('confirms remove action', (WidgetTester tester) async {
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
                            (context) => RemoveMemberConfirmationDialog(
                              list: list,
                              member: member,
                            ),
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

      await tester.tap(find.widgetWithText(ElevatedButton, 'Remove Member'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });

  group('MemberListDialog remove member flow', () {
    late ListMember owner;
    late ListMember member;
    late ShoppingList list;

    setUp(() {
      owner = ListMember(
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
      member = ListMember(
        userId: 'member-1',
        displayName: 'Riley',
        email: 'riley@test.com',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        permissions: const {'read': true},
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
    });

    testWidgets('shows remove button for owner and removes member', (
      WidgetTester tester,
    ) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder:
                            (context) => MemberListDialog(
                              list: list,
                              currentUserEmail: owner.email,
                              currentUserId: owner.userId,
                              onRemoveMember: (member) async {
                                removed = true;
                                return true;
                              },
                            ),
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

      expect(find.byIcon(Icons.person_remove), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_remove));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveMemberConfirmationDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Remove Member'));
      await tester.pumpAndSettle();

      expect(removed, isTrue);
      expect(find.text('Riley'), findsNothing);
    });

    testWidgets('does not show remove button for non-owner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder:
                            (context) => MemberListDialog(
                              list: list,
                              currentUserEmail: member.email,
                              currentUserId: member.userId,
                            ),
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

      expect(find.byIcon(Icons.person_remove), findsNothing);
    });
  });
}
