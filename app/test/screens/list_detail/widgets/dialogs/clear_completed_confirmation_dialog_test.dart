// ignore_for_file: deprecated_member_use
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/clear_completed_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

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

// Scaffold with Navigator so the AlertDialog can pop to its parent
Widget _createScaffold(ShoppingList list) {
  return MaterialApp(
    home: Navigator(
      onPopPage: (_, __) => false,
      pages: [
        MaterialPage(
          child: Material(
            child: ClearCompletedConfirmationDialog(list: list),
          ),
        ),
      ],
    ),
  );
}

void main() {
  group('ClearCompletedConfirmationDialog', () {
    testWidgets('displays correct item count in content', (tester) async {
      final list = _createList(completedItems: 5);
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.textContaining(RegExp(r'5 completed items')),
        findsOneWidget,
      );
    });

    testWidgets('displays 0 items message', (tester) async {
      final list = _createList(completedItems: 0);
      await tester.pumpWidget(_createScaffold(list));

      expect(
        find.textContaining(RegExp(r'0 completed items')),
        findsOneWidget,
      );
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

      await tester.pumpWidget(MaterialApp(
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
      ));

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(await completer.future, isFalse);
    });

    testWidgets('clear button pops with true', (tester) async {
      final list = _createList();
      final completer = Completer<bool>();

      await tester.pumpWidget(MaterialApp(
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
      ));

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
  });
}
