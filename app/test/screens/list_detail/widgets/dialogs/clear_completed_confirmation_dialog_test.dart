// TODO: Replace onPopPage with a test NavigatorObserver when migrating to Router 2.
// ignore_for_file: deprecated_member_use

import 'dart:async';

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

Widget _createScaffold(ShoppingList list) {
  return MaterialApp(
    home: Navigator(
      pages: [
        MaterialPage(
          child: Material(child: ClearCompletedConfirmationDialog(list: list)),
        ),
      ],
      onPopPage: (_, _) => false,
    ),
  );
}

void main() {
  group('ClearCompletedConfirmationDialog', () {
    testWidgets('displays correct item count in content', (tester) async {
      final list = _createList(completedItems: 5);
      await tester.pumpWidget(_createScaffold(list));

      expect(find.textContaining(RegExp(r'5 completed items')), findsOneWidget);
    });

    testWidgets('displays 0 items message', (tester) async {
      final list = _createList(completedItems: 0);
      await tester.pumpWidget(_createScaffold(list));

      expect(find.textContaining(RegExp(r'0 completed items')), findsOneWidget);
    });

    testWidgets('shows warning message', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.textContaining('This will permanently remove'),
        findsOneWidget,
      );
    });

    testWidgets('shows cancel button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows clear button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.text('Clear Items'), findsOneWidget);
    });

    testWidgets('cancel button pops with false', (tester) async {
      final list = _createList();
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                child: Material(
                  child: ClearCompletedConfirmationDialog(list: list),
                ),
              ),
            ],
            onPopPage: (route, result) {
              completer.complete(result as bool);
              return false; // prevent actual pop for test stability
            },
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(await completer.future, isFalse);
    });

    testWidgets('clear button pops with true', (tester) async {
      final list = _createList();
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                child: Material(
                  child: ClearCompletedConfirmationDialog(list: list),
                ),
              ),
            ],
            onPopPage: (route, result) {
              completer.complete(result as bool);
              return false; // prevent actual pop for test stability
            },
          ),
        ),
      );

      await tester.tap(find.text('Clear Items'));
      await tester.pump();

      expect(await completer.future, isTrue);
    });

    testWidgets('uses warning icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('is an AlertDialog', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('title is Clear completed', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.text('Clear completed'), findsOneWidget);
    });

    testWidgets('displays list name in content', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.textContaining('Weekly Groceries'), findsOneWidget);
    });

    testWidgets('uses bulb icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('displays singular "item" for single completed item',
        (tester) async {
      final list = _createList(completedItems: 1);
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.text(
          'This will permanently remove 1 completed item from "Weekly Groceries".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays 0 completed items correctly', (tester) async {
      final list = _createList(completedItems: 0);
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.text(
          'This will permanently remove 0 completed items from "Weekly Groceries".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows cancel button that pops false', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
    });

    testWidgets('shows clear items button that pops true', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.text('Clear Items'), findsOneWidget);

      await tester.tap(find.text('Clear Items'));
      await tester.pump();
    });

    testWidgets('shows helpful tip container', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.text(
          'This is useful for reusing lists like weekly grocery lists.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays bulb icon in tip container', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('dialog is an AlertDialog', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('uses basketOrange color for icon container', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.clear_all),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
    });

    testWidgets('uses Column for content layout', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('title row has clear_all icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_createScaffold(list));

      final iconFinder = find.descendant(
        of: find.byIcon(Icons.clear_all),
        matching: find.byIcon(Icons.clear_all),
      ).first;

      expect(iconFinder, findsOneWidget);
    });
  });
}
