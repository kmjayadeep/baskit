import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/lists/widgets/welcome_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows empty-state copy and zero metrics', (tester) async {
    await tester.pumpWidget(const _TestApp(lists: []));
    await tester.pumpAndSettle();

    expect(find.text('0 items left'), findsOneWidget);
    expect(find.text('0 lists ready'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('shared'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(_progressValue(tester), 0);
  });

  testWidgets('summarizes partially completed items', (tester) async {
    final list = _list(
      items: [_item('milk', isCompleted: true), _item('eggs'), _item('bread')],
    );

    await tester.pumpWidget(_TestApp(lists: [list]));
    await tester.pumpAndSettle();

    expect(find.text('2 items left'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('shared'), findsOneWidget);
    expect(_progressValue(tester), closeTo(1 / 3, 0.001));
  });

  testWidgets('shows all-completed copy when no items remain', (tester) async {
    final list = _list(
      items: [
        _item('milk', isCompleted: true),
        _item('eggs', isCompleted: true),
      ],
    );

    await tester.pumpWidget(_TestApp(lists: [list]));
    await tester.pumpAndSettle();

    expect(find.text('All items checked off'), findsOneWidget);
    expect(find.text('2 of 2 done'), findsOneWidget);
    expect(find.text('0 items left'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('shared'), findsOneWidget);
    expect(_progressValue(tester), 1);
  });

  testWidgets('counts shared lists separately from active lists', (
    tester,
  ) async {
    final owner = _member('owner-1', 'Owner', MemberRole.owner);
    final member = _member('member-1', 'Member', MemberRole.member);
    final lists = [
      _list(id: 'private-list', items: [_item('apples')], members: [owner]),
      _list(
        id: 'shared-list-1',
        items: [_item('bananas')],
        members: [owner, member],
      ),
      _list(
        id: 'shared-list-2',
        items: [_item('carrots')],
        members: [owner, member],
      ),
    ];

    await tester.pumpWidget(_TestApp(lists: lists));
    await tester.pumpAndSettle();

    expect(find.text('3 items left'), findsOneWidget);
    expect(find.text('0 of 3 done'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('shared'), findsOneWidget);
    expect(_progressValue(tester), 0);
  });
}

class _TestApp extends StatelessWidget {
  final List<ShoppingList> lists;

  const _TestApp({required this.lists});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: WelcomeBannerWidget(lists: lists)),
    );
  }
}

ShoppingList _list({
  String id = 'list-1',
  List<ShoppingItem> items = const [],
  List<ListMember> members = const [],
}) {
  final now = DateTime(2026);
  const ownerId = 'owner-1';

  return ShoppingList(
    id: id,
    name: 'Groceries',
    description: '',
    color: '#2196F3',
    createdAt: now,
    updatedAt: now,
    ownerId: ownerId,
    members: members,
    items: items,
  );
}

ShoppingItem _item(String name, {bool isCompleted = false}) {
  return ShoppingItem(
    id: name,
    name: name,
    isCompleted: isCompleted,
    createdAt: DateTime(2026),
    completedAt: isCompleted ? DateTime(2026) : null,
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

double? _progressValue(WidgetTester tester) {
  return tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value;
}
