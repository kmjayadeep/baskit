import 'package:baskit/constants/app_colors.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/item_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShoppingItem _buildItem({bool isCompleted = false, String? quantity}) {
  return ShoppingItem(
    id: 'item-1',
    name: 'Milk',
    quantity: quantity,
    isCompleted: isCompleted,
    createdAt: DateTime(2024),
    completedAt: isCompleted ? DateTime(2024) : null,
  );
}

void _noop(ShoppingItem _) {}

Widget _buildWidget({
  required ShoppingItem item,
  bool isProcessing = false,
  ValueChanged<ShoppingItem>? onToggleCompleted,
  ValueChanged<ShoppingItem>? onDelete,
  ValueChanged<ShoppingItem>? onEdit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ItemCardWidget(
        item: item,
        isProcessing: isProcessing,
        onToggleCompleted: onToggleCompleted,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    ),
  );
}

Future<void> _openActionsMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  group('ItemCardWidget', () {
    testWidgets('toggles completion when the row is tapped', (tester) async {
      final item = _buildItem();
      ShoppingItem? toggledItem;

      await tester.pumpWidget(
        _buildWidget(
          item: item,
          onToggleCompleted: (value) => toggledItem = value,
        ),
      );

      await tester.tap(find.text('Milk'));
      await tester.pump();

      expect(toggledItem, same(item));
    });

    testWidgets('toggles completion when the checkbox is tapped', (
      tester,
    ) async {
      final item = _buildItem();
      ShoppingItem? toggledItem;

      await tester.pumpWidget(
        _buildWidget(
          item: item,
          onToggleCompleted: (value) => toggledItem = value,
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggledItem, same(item));
    });

    testWidgets('shows processing state and disables interactions', (
      tester,
    ) async {
      final item = _buildItem();
      ShoppingItem? toggledItem;

      await tester.pumpWidget(
        _buildWidget(
          item: item,
          isProcessing: true,
          onToggleCompleted: (value) => toggledItem = value,
          onEdit: _noop,
          onDelete: _noop,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);

      await tester.tap(find.text('Milk'));
      await tester.pump();

      expect(toggledItem, isNull);
    });

    testWidgets('keeps completed styling and displays quantity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(item: _buildItem(isCompleted: true, quantity: '2 liters')),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      final nameStyleFinder = find.ancestor(
        of: find.text('Milk'),
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      final nameStyle = tester.widget<AnimatedDefaultTextStyle>(
        nameStyleFinder.first,
      );

      expect(decoration.color, AppColors.completedSurface);
      expect(
        decoration.border!.top.color,
        AppColors.primaryGreen.withValues(alpha: 0.16),
      );
      expect(nameStyle.style.decoration, TextDecoration.lineThrough);
      expect(nameStyle.style.color, AppColors.textMuted);
      expect(find.text('2 liters'), findsOneWidget);
    });

    testWidgets('hides actions when edit and delete callbacks are absent', (
      tester,
    ) async {
      await tester.pumpWidget(_buildWidget(item: _buildItem()));

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('shows only the edit action when delete is absent', (
      tester,
    ) async {
      await tester.pumpWidget(_buildWidget(item: _buildItem(), onEdit: _noop));
      await _openActionsMenu(tester);

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('shows only the delete action when edit is absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(item: _buildItem(), onDelete: _noop),
      );
      await _openActionsMenu(tester);

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows edit and delete actions when both are available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(item: _buildItem(), onEdit: _noop, onDelete: _noop),
      );
      await _openActionsMenu(tester);

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('dispatches edit and delete with the original item', (
      tester,
    ) async {
      final item = _buildItem();
      ShoppingItem? editedItem;
      ShoppingItem? deletedItem;

      await tester.pumpWidget(
        _buildWidget(
          item: item,
          onEdit: (value) => editedItem = value,
          onDelete: (value) => deletedItem = value,
        ),
      );

      await _openActionsMenu(tester);
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(editedItem, same(item));
      expect(deletedItem, isNull);

      await _openActionsMenu(tester);
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(deletedItem, same(item));
    });
  });
}
