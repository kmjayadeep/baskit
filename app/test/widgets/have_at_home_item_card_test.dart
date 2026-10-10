import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/have_at_home_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShoppingItem _buildItem({String? quantity}) {
  return ShoppingItem(
    id: 'item-1',
    name: 'Toothpaste',
    quantity: quantity,
    createdAt: DateTime(2024),
    listItemType: ItemType.haveAtHome,
  );
}

Widget _buildWidget({
  required ShoppingItem item,
  bool isProcessing = false,
  VoidCallback? onFinished,
  VoidCallback? onDelete,
  VoidCallback? onEdit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: HaveAtHomeItemCard(
        item: item,
        isProcessing: isProcessing,
        onFinished: onFinished,
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
  group('HaveAtHomeItemCard', () {
    testWidgets('shows name, quantity, and the Finished button', (tester) async {
      await tester.pumpWidget(
        _buildWidget(item: _buildItem(quantity: '1 tube'), onFinished: () {}),
      );

      expect(find.text('Toothpaste'), findsOneWidget);
      expect(find.text('1 tube'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
    });

    testWidgets('calls onFinished when the card is tapped', (tester) async {
      var finished = false;

      await tester.pumpWidget(
        _buildWidget(item: _buildItem(), onFinished: () => finished = true),
      );

      await tester.tap(find.text('Toothpaste'));
      await tester.pump();

      expect(finished, isTrue);
    });

    testWidgets('calls onFinished when the Finished button is tapped', (
      tester,
    ) async {
      var finished = false;

      await tester.pumpWidget(
        _buildWidget(item: _buildItem(), onFinished: () => finished = true),
      );

      await tester.tap(find.text('Finished'));
      await tester.pump();

      expect(finished, isTrue);
    });

    testWidgets('shows a spinner and disables actions while processing', (
      tester,
    ) async {
      var finished = false;

      await tester.pumpWidget(
        _buildWidget(
          item: _buildItem(),
          isProcessing: true,
          onFinished: () => finished = true,
          onEdit: () {},
          onDelete: () {},
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finished'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);

      await tester.tap(find.text('Toothpaste'));
      await tester.pump();

      expect(finished, isFalse);
    });

    testWidgets('hides the actions menu when edit/delete are absent', (
      tester,
    ) async {
      await tester.pumpWidget(_buildWidget(item: _buildItem()));

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('shows edit and delete when both are available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWidget(item: _buildItem(), onEdit: () {}, onDelete: () {}),
      );
      await _openActionsMenu(tester);

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('dispatches edit and delete callbacks', (tester) async {
      var edited = false;
      var deleted = false;

      await tester.pumpWidget(
        _buildWidget(
          item: _buildItem(),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      );

      await _openActionsMenu(tester);
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(edited, isTrue);
      expect(deleted, isFalse);

      await _openActionsMenu(tester);
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(deleted, isTrue);
    });
  });
}
