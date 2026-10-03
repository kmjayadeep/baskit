import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/clear_completed_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShoppingList _createList({int completedItems = 3}) {
  final dt = DateTime.now();
  return ShoppingList(
    id: 'test-list',
    name: 'Weekly Groceries',
    description: '',
    color: '#FF9800',
    createdAt: dt,
    updatedAt: dt,
    items: List.generate(
      completedItems,
      (i) => ShoppingItem(
        id: 'item-$i',
        name: 'Item $i',
        isCompleted: true,
        createdAt: dt,
      ),
    ),
  );
}

Widget _createWidget(ShoppingList list) {
  return MaterialApp(
    home: Material(
      child: Builder(
        builder: (context) => ClearCompletedConfirmationDialog(list: list),
      ),
    ),
  );
}

void main() {
  group('ClearCompletedConfirmationDialog', () {
    testWidgets('displays correct item count', (tester) async {
      final list = _createList(completedItems: 5);
      await tester.pumpWidget(_createWidget(list));

      expect(find.text('Clear 5 completed items?'), findsOneWidget);
    });

    testWidgets('displays 0 items message', (tester) async {
      final list = _createList(completedItems: 0);
      await tester.pumpWidget(_createWidget(list));

      expect(find.text('Clear 0 completed items?'), findsOneWidget);
    });

    testWidgets('shows warning message', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(
        find.text('This action cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('shows cancel button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows clear button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('cancel button pops null', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
    });

    testWidgets('clear button pops true', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      await tester.tap(find.text('Clear'));
      await tester.pump();
    });

    testWidgets('uses warning icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('is an AlertDialog', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('title is in titleLarge style', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.text('Clear completed items'), findsOneWidget);
    });

    testWidgets('uses Form widget', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createWidget(list));

      expect(find.byType(Form), findsOneWidget);
    });
  });
}
