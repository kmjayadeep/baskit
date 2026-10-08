import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/member_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {
    '  alex   middle   smith  ': 'AS',
    '👩‍👩‍👧‍👦 Family': '👩‍👩‍👧‍👦F',
    'éloïse 李': 'É李',
  }.entries) {
    testWidgets('uses first and last graphemes for ${entry.key}', (
      tester,
    ) async {
      final list = ShoppingList(
        id: 'list-1',
        name: 'Shared list',
        description: '',
        color: '#F59E0B',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        ownerId: 'owner-1',
        members: [
          ListMember(
            userId: 'member-1',
            displayName: entry.key,
            role: MemberRole.member,
            joinedAt: DateTime(2026),
            permissions: const {'read': true},
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberListDialog(list: list, currentUserId: 'owner-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CircleAvatar, entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
