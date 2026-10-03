import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/clear_completed_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClearCompletedConfirmationDialog', () {
    ShoppingList createList({int completedItems = 3}) {
      return ShoppingList(
        id: 'test-list',
        name: 'Weekly Groceries',
        description: '',
        color: '#FF9800',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: List.generate(
          completedItems,
          (i) => ShoppingItem(
            id: 'item-$i',
            name: 'Item $i',
            isCompleted: true,
          ),
        ),
      );
    }

    Widget createWidget(ShoppingList list) {
      return MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) =>
                ClearCompletedConfirmationDialog(list: list),
          ),
        ),
      );
    }

    testWidgets('displays correct completed count for multiple items',
        (tester) async {
      final list = createList(completedItems: 3);
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Clear completed'), findsOneWidget);
      expect(
        find.text(
          'This will permanently remove 3 completed items from "Weekly Groceries".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays singular "item" for single completed item',
        (tester) async {
      final list = createList(completedItems: 1);
      await tester.pumpWidget(createWidget(list));

      expect(
        find.text(
          'This will permanently remove 1 completed item from "Weekly Groceries".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays 0 completed items correctly', (tester) async {
      final list = createList(completedItems: 0);
      await tester.pumpWidget(createWidget(list));

      expect(
        find.text(
          'This will permanently remove 0 completed items from "Weekly Groceries".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows cancel button that pops false', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
    });

    testWidgets('shows clear items button that pops true', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.text('Clear Items'), findsOneWidget);

      await tester.tap(find.text('Clear Items'));
      await tester.pump();
    });

    testWidgets('shows helpful tip container', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(
        find.text(
          'This is useful for reusing lists like weekly grocery lists.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays bulb icon in tip container', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('dialog is an AlertDialog', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('uses basketOrange color for icon container', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      final containerFinder = find.ancestor
          .of(find.byIcon(Icons.clear_all))
          .matching(find.byType(Container));

      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
    });

    testWidgets('uses Column for content layout', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('title row has clear_all icon', (tester) async {
      final list = createList();
      await tester.pumpWidget(createWidget(list));

      final iconFinder = find
          .descendant(
            of: find.byIcon(Icons.clear_all),
            matching(find.byIcon(Icons.clear_all)),
          )
          .first;

      expect(iconFinder, findsOneWidget);
    });
  });
}
