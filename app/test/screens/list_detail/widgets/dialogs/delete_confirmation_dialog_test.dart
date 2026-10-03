import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _dt = DateTime(2026, 1, 1);

ShoppingList _createList({String name = 'Weekly Groceries'}) {
  return ShoppingList(
    'test-list',
    name,
    '',
    '#2196F3',
    _dt,
    _dt,
  );
}

void main() {
  group('DeleteConfirmationDialog', () {

    Widget createWidget(ShoppingList list) {
      return MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) => DeleteConfirmationDialog(list: list),
          ),
        ),
      );
    }

    testWidgets('displays list name in title', (tester) async {
      final list = createList(name: 'My Special List');
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Delete "My Special List"?'), findsOneWidget);
    });

    testWidgets('handles long list name with ellipsis', (tester) async {
      final longName = 'A' * 100;
      final list = createList(name: longName);
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Delete "$longName"?'), findsOneWidget);
    });

    testWidgets('shows cancel button that pops false', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      final result = Navigator.of(tester.element(find.byWidgetPredicate((w) => w is DeleteConfirmationDialog))).pop;
      expect(result, isNotNull);
    });

    testWidgets('shows delete list button that pops true', (tester) async {
      final list = _createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Delete List'), findsOneWidget);

      await tester.tap(find.text('Delete List'));
      await tester.pump();

      final result = Navigator.of(tester.element(find.byWidgetPredicate((w) => w is DeleteConfirmationDialog))).pop;
      expect(result, isNotNull);
    });

    testWidgets('shows deletion warning message', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(
        find.text('This will permanently delete the list and all of its items.'),
        findsOneWidget,
      );
    });

    testWidgets('is an AlertDialog with delete icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('uses titleLarge text style for title', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(
        find.byType(DeleteConfirmationDialog),
        findsOneWidget,
      );
    });

    testWidgets('dialog is an AlertDialog', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
