import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/completed_items_section_widget.dart';

ShoppingItem _buildItem({
  String id = 'item-1',
  String name = 'Milk',
  bool isCompleted = true,
  String? quantity,
}) {
  return ShoppingItem(
    id: id,
    name: name,
    quantity: quantity,
    isCompleted: isCompleted,
    createdAt: DateTime.now(),
    completedAt: isCompleted ? DateTime.now() : null,
  );
}

Widget _buildWidget({
  List<ShoppingItem>? items,
  Set<String>? processingItems,
  Function(ShoppingItem)? onToggle,
  Function(ShoppingItem)? onDelete,
  Function(ShoppingItem)? onEdit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CompletedItemsSection(
          completedItems:
              items ?? [_buildItem(), _buildItem(id: 'item-2', name: 'Bread')],
          processingItems: processingItems ?? const {},
          onToggleCompleted: onToggle,
          onDelete: onDelete,
          onEdit: onEdit,
        ),
      ),
    ),
  );
}

void main() {
  group('CompletedItemsSection', () {
    testWidgets('shows completed count in header', (tester) async {
      await tester.pumpWidget(_buildWidget());

      expect(find.text('Completed (2)'), findsOneWidget);
    });

    testWidgets('items are hidden by default', (tester) async {
      await tester.pumpWidget(_buildWidget());

      // Item cards should not be visible when collapsed.
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('collapsed header shows preview hint', (tester) async {
      await tester.pumpWidget(_buildWidget());

      expect(find.text('Milk, Bread · Tap to show'), findsOneWidget);
    });

    testWidgets('collapsed preview includes at most two names', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          items: [
            _buildItem(),
            _buildItem(id: 'item-2', name: 'Bread'),
            _buildItem(id: 'item-3', name: 'Eggs'),
          ],
        ),
      );

      expect(find.text('Milk, Bread +1 more · Tap to show'), findsOneWidget);
      expect(find.textContaining('Eggs'), findsNothing);
    });

    testWidgets('tapping header expands to show items and hide action', (
      tester,
    ) async {
      await tester.pumpWidget(_buildWidget());

      // Tap the header
      await tester.tap(find.text('Completed (2)'));
      await tester.pumpAndSettle();

      // Items should now be visible
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      expect(find.textContaining('Tap to show'), findsNothing);
    });

    testWidgets('tapping header again collapses items', (tester) async {
      await tester.pumpWidget(_buildWidget());

      // Expand first
      await tester.tap(find.text('Completed (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);

      // Collapse again
      await tester.tap(find.text('Completed (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsNothing);
    });

    testWidgets('shows correct singular count', (tester) async {
      await tester.pumpWidget(_buildWidget(items: [_buildItem()]));

      expect(find.text('Completed (1)'), findsOneWidget);
    });

    testWidgets('calls onToggleCompleted when checkbox is tapped', (
      tester,
    ) async {
      bool? toggled;
      await tester.pumpWidget(
        _buildWidget(items: [_buildItem()], onToggle: (item) => toggled = true),
      );

      // Expand to show items
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      // Tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('does not show toggle/delete/edit when no callbacks provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(
          items: [_buildItem()],
          onToggle: null,
          onDelete: null,
          onEdit: null,
        ),
      );

      // Expand to show items
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();

      // PopupMenuButton should not be present (no actions available)
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
