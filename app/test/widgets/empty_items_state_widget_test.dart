import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/add_item_widget.dart';
import 'package:baskit/screens/list_detail/widgets/empty_items_state_widget.dart';

void main() {
  group('EmptyItemsStateWidget', () {
    testWidgets('shows CTA and invokes callback when provided', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyItemsStateWidget(onAddFirstItem: () => tapCount += 1),
          ),
        ),
      );

      expect(find.text('Add first item'), findsOneWidget);

      await tester.tap(find.text('Add first item'));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('stays informational without CTA when callback is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EmptyItemsStateWidget())),
      );

      expect(find.text('Add first item'), findsNothing);
      expect(
        find.text('Items added to this list will appear here.'),
        findsOneWidget,
      );
    });
  });

  group('AddItemWidget', () {
    testWidgets('uses the provided focus node for the main item field', (
      tester,
    ) async {
      final itemController = TextEditingController();
      final quantityController = TextEditingController();
      final focusNode = FocusNode();
      final now = DateTime(2026, 1, 1);
      final list = ShoppingList(
        id: 'list-1',
        name: 'Groceries',
        description: '',
        color: '#4CAF50',
        createdAt: now,
        updatedAt: now,
      );

      addTearDown(() {
        itemController.dispose();
        quantityController.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddItemWidget(
              list: list,
              itemController: itemController,
              quantityController: quantityController,
              itemFocusNode: focusNode,
              isAddingItem: false,
              onAddItem: () {},
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });
}
