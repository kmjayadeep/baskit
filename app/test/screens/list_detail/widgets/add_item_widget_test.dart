import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/add_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddItemWidget', () {
    testWidgets('keeps Add button disabled for blank item names', (
      tester,
    ) async {
      var addCalls = 0;
      final itemController = TextEditingController();
      final quantityController = TextEditingController();
      addTearDown(itemController.dispose);
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        _TestApp(
          itemController: itemController,
          quantityController: quantityController,
          onAddItem: () => addCalls++,
        ),
      );

      expect(_addButton(tester).onPressed, isNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(addCalls, 0);

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();

      expect(_addButton(tester).onPressed, isNull);
    });

    testWidgets('enables Add button after an item name is entered', (
      tester,
    ) async {
      var addCalls = 0;
      final itemController = TextEditingController();
      final quantityController = TextEditingController();
      addTearDown(itemController.dispose);
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        _TestApp(
          itemController: itemController,
          quantityController: quantityController,
          onAddItem: () => addCalls++,
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Milk');
      await tester.pump();

      expect(_addButton(tester).onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(addCalls, 1);
    });

    testWidgets('details toggle still works while Add button is disabled', (
      tester,
    ) async {
      final itemController = TextEditingController();
      final quantityController = TextEditingController();
      addTearDown(itemController.dispose);
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        _TestApp(
          itemController: itemController,
          quantityController: quantityController,
          onAddItem: () {},
        ),
      );

      expect(find.text('Qty, note, or type'), findsNothing);
      expect(_addButton(tester).onPressed, isNull);

      await tester.tap(find.byTooltip('Quantity, note, or type'));
      await tester.pumpAndSettle();

      expect(find.text('Qty, note, or type'), findsOneWidget);
      expect(_addButton(tester).onPressed, isNull);
    });

    testWidgets('refreshes Add button state when item controller is swapped', (
      tester,
    ) async {
      final originalController = TextEditingController(text: 'Milk');
      final replacementController = TextEditingController();
      final quantityController = TextEditingController();
      addTearDown(originalController.dispose);
      addTearDown(replacementController.dispose);
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        _TestApp(
          itemController: originalController,
          quantityController: quantityController,
          onAddItem: () {},
        ),
      );

      expect(_addButton(tester).onPressed, isNotNull);

      await tester.pumpWidget(
        _TestApp(
          itemController: replacementController,
          quantityController: quantityController,
          onAddItem: () {},
        ),
      );

      expect(_addButton(tester).onPressed, isNull);

      originalController.text = 'Eggs';
      await tester.pump();

      expect(_addButton(tester).onPressed, isNull);

      replacementController.text = 'Bread';
      await tester.pump();

      expect(_addButton(tester).onPressed, isNotNull);
    });

    testWidgets('uses replacement controller text when swapping controllers', (
      tester,
    ) async {
      final originalController = TextEditingController();
      final replacementController = TextEditingController(text: 'Apples');
      final quantityController = TextEditingController();
      addTearDown(originalController.dispose);
      addTearDown(replacementController.dispose);
      addTearDown(quantityController.dispose);

      await tester.pumpWidget(
        _TestApp(
          itemController: originalController,
          quantityController: quantityController,
          onAddItem: () {},
        ),
      );

      expect(_addButton(tester).onPressed, isNull);

      await tester.pumpWidget(
        _TestApp(
          itemController: replacementController,
          quantityController: quantityController,
          onAddItem: () {},
        ),
      );

      expect(_addButton(tester).onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      replacementController.text = 'Bananas';
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

ElevatedButton _addButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Add'),
  );
}

class _TestApp extends StatelessWidget {
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final VoidCallback onAddItem;

  const _TestApp({
    required this.itemController,
    required this.quantityController,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AddItemWidget(
          list: _testList,
          itemController: itemController,
          quantityController: quantityController,
          isAddingItem: false,
          onAddItem: onAddItem,
        ),
      ),
    );
  }
}

final _testList = ShoppingList(
  id: 'list-1',
  name: 'Groceries',
  description: '',
  color: '#4CAF50',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);
