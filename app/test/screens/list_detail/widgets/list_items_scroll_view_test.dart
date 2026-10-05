import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/list_items_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ShoppingItem item(String id, String name, {bool isCompleted = false}) {
    return ShoppingItem(
      id: id,
      name: name,
      isCompleted: isCompleted,
      createdAt: DateTime(2024),
    );
  }

  testWidgets('shows pending items and keeps completed items collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListItemsScrollView(
            pendingItems: [item('pending-1', 'Milk')],
            completedItems: [item('completed-1', 'Eggs', isCompleted: true)],
            processingItems: const {},
          ),
        ),
      ),
    );

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);
    expect(find.text('Eggs'), findsNothing);
  });

  testWidgets('expands the completed items section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListItemsScrollView(
            pendingItems: [item('pending-1', 'Milk')],
            completedItems: [item('completed-1', 'Eggs', isCompleted: true)],
            processingItems: const {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Eggs'), findsOneWidget);
  });
}
