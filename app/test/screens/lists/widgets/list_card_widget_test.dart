import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/lists/widgets/list_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows total member count instead of long shared label', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final member = _member('member-1', 'Long Member Name', MemberRole.member);
    final list = _list(ownerId: owner.userId, members: [owner, member]);

    await tester.pumpWidget(_TestApp(list: list));

    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Shared with'), findsNothing);
    expect(find.textContaining('Long Member Name'), findsNothing);
  });

  testWidgets('shows private label for private lists', (tester) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final list = _list(ownerId: owner.userId, members: [owner]);

    await tester.pumpWidget(_TestApp(list: list));

    expect(find.text('Private'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final ShoppingList list;

  const _TestApp({required this.list});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: ListCardWidget(list: list, onTap: () {})),
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

ListMember _member(String userId, String displayName, MemberRole role) {
  return ListMember(
    userId: userId,
    displayName: displayName,
    role: role,
    joinedAt: DateTime(2026),
    permissions: const {'read': true, 'write': true},
  );
}
