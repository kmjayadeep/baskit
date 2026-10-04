import 'dart:async';

import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
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

Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Material(child: child),
  );
}

void main() {
  group('ClearCompletedConfirmationDialog', () {
    testWidgets('displays correct item count in content', (tester) async {
      final list = _createList(completedItems: 5);
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.textContaining(RegExp(r'5 completed items')), findsOneWidget);
    });

    testWidgets('displays 0 items message', (tester) async {
      final list = _createList(completedItems: 0);
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.textContaining(RegExp(r'0 completed items')), findsOneWidget);
    });

    testWidgets('shows warning message', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.textContaining('This will permanently remove'), findsOneWidget);
    });

    testWidgets('shows cancel button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows clear button', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.text('Clear Items'), findsOneWidget);
    });

    testWidgets('cancel button returns false via showDialog', (tester) async {
      final list = _createList();
      bool? dialogResult;
      await tester.pumpWidget(_scaffold(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              dialogResult = await showDialog<bool>(
                context: context,
                builder: (ctx) => ClearCompletedConfirmationDialog(list: list),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);
    });

    testWidgets('clear button returns true via showDialog', (tester) async {
      final list = _createList();
      bool? dialogResult;
      await tester.pumpWidget(_scaffold(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              dialogResult = await showDialog<bool>(
                context: context,
                builder: (ctx) => ClearCompletedConfirmationDialog(list: list),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Items'));
      await tester.pumpAndSettle();
      expect(dialogResult, isTrue);
    });

    testWidgets('uses clear_all icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });

    testWidgets('is an AlertDialog', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('title contains "Clear completed"', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.textContaining('Clear completed'), findsOneWidget);
    });

    testWidgets('displays list name in content', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.textContaining('Weekly Groceries'), findsOneWidget);
    });

    testWidgets('uses lightbulb_outline icon', (tester) async {
      final list = _createList();
      await tester.pumpWidget(_scaffold(ClearCompletedConfirmationDialog(list: list)));
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });
  });
}
