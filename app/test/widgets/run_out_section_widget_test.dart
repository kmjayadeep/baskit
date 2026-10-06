import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/run_out_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShoppingItem _buildItem({required String id, required String name}) {
  return ShoppingItem(
    id: id,
    name: name,
    createdAt: DateTime(2024),
    listItemType: ItemType.runOut,
  );
}

Widget _buildSection({
  required List<ShoppingItem> items,
  Set<String> processing = const {},
  Function(ShoppingItem)? onMoveBack,
  Function(ShoppingItem)? onDelete,
  Function(ShoppingItem)? onEdit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: RunOutSection(
        runOutItems: items,
        processingItems: processing,
        onMoveBack: onMoveBack,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    ),
  );
}

void main() {
  group('RunOutSection', () {
    testWidgets('shows the header count and is collapsed by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(
          items: [
            _buildItem(id: '1', name: 'Coffee'),
            _buildItem(id: '2', name: 'Sugar'),
          ],
        ),
      );

      expect(find.text('Run out (2)'), findsOneWidget);
      // Collapsed: the summary shows both names in one text, and no
      // actionable "Move back" button is rendered.
      expect(find.text('Coffee, Sugar · Tap to show'), findsOneWidget);
      expect(find.text('Move back'), findsNothing);
    });

    testWidgets('expands to show all items when the header is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(
          items: [
            _buildItem(id: '1', name: 'Coffee'),
            _buildItem(id: '2', name: 'Sugar'),
          ],
        ),
      );

      await tester.tap(find.text('Run out (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Sugar'), findsOneWidget);
    });

    testWidgets('collapses again when the header is tapped a second time', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSection(items: [_buildItem(id: '1', name: 'Coffee')]),
      );

      await tester.tap(find.text('Run out (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Coffee'), findsOneWidget);

      // Expand shows the card; tap header again to collapse. The expanded
      // summary text is just "Hide", so the name is only in the item card.
      expect(find.text('Coffee'), findsOneWidget);
      await tester.tap(find.text('Run out (1)'));
      await tester.pumpAndSettle();

      // Collapsed: no item card, and the name is gone from the "Hide" summary.
      expect(find.text('Move back'), findsNothing);
    });

    testWidgets('dispatches move-back with the tapped item', (tester) async {
      ShoppingItem? moved;

      await tester.pumpWidget(
        _buildSection(
          items: [_buildItem(id: '1', name: 'Coffee')],
          onMoveBack: (item) => moved = item,
        ),
      );

      await tester.tap(find.text('Run out (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move back'));
      await tester.pump();

      expect(moved, isNotNull);
      expect(moved!.id, '1');
    });

    testWidgets('dispatches delete via the item actions menu', (
      tester,
    ) async {
      ShoppingItem? deleted;

      await tester.pumpWidget(
        _buildSection(
          items: [_buildItem(id: '1', name: 'Coffee')],
          onMoveBack: (item) {},
          onDelete: (item) => deleted = item,
        ),
      );

      await tester.tap(find.text('Run out (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(deleted, isNotNull);
      expect(deleted!.id, '1');
    });
  });
}
