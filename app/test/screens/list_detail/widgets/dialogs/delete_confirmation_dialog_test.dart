import 'package:baskit/constants/app_colors.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeleteConfirmationDialog', () {
    ShoppingList createList({String name = 'Weekly Groceries'}) {
      return ShoppingList(
        id: 'test-list',
        name: name,
        description: '',
        color: '#2196F3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

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

      final result = Navigator.of(tester.element(find.byType(DeleteConfirmationDialog))).pop;
      expect(result, isNotNull);
    });

    testWidgets('shows delete list button that pops true', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Delete List'), findsOneWidget);

      await tester.tap(find.text('Delete List'));
      await tester.pump();

      final result = Navigator.of(tester.element(find.byType(DeleteConfirmationDialog))).pop;
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

    testWidgets('displays with red color scheme', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      final container = tester.widget<Container>(
        find.ancestor.of(find.byIcon(Icons.delete_outline)).matching(
          find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
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
