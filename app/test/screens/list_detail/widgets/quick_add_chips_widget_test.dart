import 'package:baskit/screens/list_detail/widgets/quick_add_chips_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickAddChips', () {
    testWidgets('renders a chip for each item name', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk', 'Eggs', 'Bread'],
              enabled: true,
              onItemTap: (name) => tapped = name,
            ),
          ),
        ),
      );

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(tapped, isNull);
    });

    testWidgets('tapping a chip calls onItemTap with correct name',
        (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk', 'Eggs'],
              enabled: true,
              onItemTap: (name) => tapped = name,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Eggs'));
      expect(tapped, 'Eggs');
    });

    testWidgets('disabled chips are not tappable', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk'],
              enabled: false,
              onItemTap: (name) => tapped = name,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Milk'));
      expect(tapped, isNull);
    });

    testWidgets('renders nothing when itemNames is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: [],
              enabled: true,
              onItemTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNothing);
    });
  });
}
