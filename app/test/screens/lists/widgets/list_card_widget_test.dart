import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/lists/widgets/list_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows private label for private lists', (tester) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final list = _list(ownerId: owner.userId, members: [owner]);

    await tester.pumpWidget(_TestApp(list: list));

    expect(find.text('Private'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('shows shared member avatars instead of numeric count', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final jane = _member('member-1', 'Jane Doe', MemberRole.member);
    final alex = _member('member-2', 'Alex Smith', MemberRole.member);
    final list = _list(ownerId: owner.userId, members: [owner, jane, alex]);

    await tester.pumpWidget(_TestApp(list: list));

    expect(find.text('JD'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.textContaining('Shared with'), findsNothing);
    expect(
      find.bySemanticsLabel('Shared with Jane Doe and Alex Smith'),
      findsOneWidget,
    );
  });

  testWidgets('shows overflow avatar after three shared members', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final members = [
      owner,
      _member('member-1', 'Jane Doe', MemberRole.member),
      _member('member-2', 'Alex Smith', MemberRole.member),
      _member('member-3', 'Sam Taylor', MemberRole.member),
      _member('member-4', 'Priya Patel', MemberRole.member),
      _member('member-5', 'Morgan Lee', MemberRole.member),
    ];
    final list = _list(ownerId: owner.userId, members: members);

    await tester.pumpWidget(_TestApp(list: list));

    expect(find.text('JD'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.text('ST'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('PP'), findsNothing);
    expect(find.text('ML'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Shared with Jane Doe, Alex Smith, Sam Taylor, and 2 others',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'uses initials or generic icon when avatar is missing or invalid',
    (tester) async {
      final owner = _member('owner-1', 'Owner', MemberRole.owner);
      final initialsMember = _member(
        'member-1',
        'Cher',
        MemberRole.member,
        avatarUrl: 'not-a-valid-url',
      );
      final unknownMember = _member('member-2', '', MemberRole.member);
      final list = _list(
        ownerId: owner.userId,
        members: [owner, initialsMember, unknownMember],
      );

      await tester.pumpWidget(_TestApp(list: list));

      expect(find.text('CH'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    },
  );

  testWidgets('does not show the current owner in avatar stack', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner Name', MemberRole.owner);
    final jane = _member('member-1', 'Jane Doe', MemberRole.member);
    final list = _list(ownerId: owner.userId, members: [owner, jane]);

    await tester.pumpWidget(_TestApp(list: list, currentUserId: owner.userId));

    expect(find.text('ON'), findsNothing);
    expect(find.text('JD'), findsOneWidget);
    expect(find.bySemanticsLabel('Shared with Jane Doe'), findsOneWidget);
  });

  testWidgets('excludes the current member from shared list avatar stacks', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner Name', MemberRole.owner);
    final currentMember = _member('member-1', 'Jane Doe', MemberRole.member);
    final list = _list(ownerId: owner.userId, members: [owner, currentMember]);

    await tester.pumpWidget(
      _TestApp(list: list, currentUserId: currentMember.userId),
    );

    expect(find.text('ON'), findsOneWidget);
    expect(find.text('JD'), findsNothing);
    expect(find.bySemanticsLabel('Shared with Owner Name'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final ShoppingList list;
  final String? currentUserId;

  const _TestApp({required this.list, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListCardWidget(
          list: list,
          currentUserId: currentUserId,
          onTap: () {},
        ),
      ),
    );
  }
}

ShoppingList _list({
  required String ownerId,
  required List<ListMember> members,
}) {
  final now = DateTime(2026);

  return ShoppingList(
    id: 'list-1',
    name: 'Groceries',
    description: '',
    color: '#2196F3',
    createdAt: now,
    updatedAt: now,
    ownerId: ownerId,
    members: members,
  );
}

ListMember _member(
  String userId,
  String displayName,
  MemberRole role, {
  String? avatarUrl,
}) {
  return ListMember(
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    role: role,
    joinedAt: DateTime(2026),
    permissions: const {'read': true, 'write': true},
  );
}
