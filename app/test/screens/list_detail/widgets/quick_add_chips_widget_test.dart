import 'dart:ui';

import 'package:baskit/screens/list_detail/widgets/quick_add_chips_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickAddChips', () {
    testWidgets('renders a chip for each item name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk', 'Eggs', 'Bread'],
              enabled: true,
              onItemTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('tapping a chip calls onItemTap with correct name', (
      tester,
    ) async {
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

      await tester.tap(
        find.ancestor(of: find.text('Eggs'), matching: find.byType(ActionChip)),
      );
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

      await tester.tap(
        find.ancestor(of: find.text('Milk'), matching: find.byType(ActionChip)),
        warnIfMissed: false,
      );
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

    testWidgets('adds item-specific tooltips and semantic labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk'],
              enabled: true,
              onItemTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Add Milk'), findsOneWidget);
      expect(
        find.semantics.byPredicate((node) {
          final data = node.getSemanticsData();
          final flags = data.flagsCollection;
          return node.label == 'Add Milk' &&
              flags.isButton &&
              flags.isEnabled == Tristate.isTrue &&
              data.hasAction(SemanticsAction.tap);
        }, describeMatch: (_) => 'enabled add chip semantics node'),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('uses larger compact tap targets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk'],
              enabled: true,
              onItemTap: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(ActionChip)).height, 44);
      expect(tester.getSize(find.byType(IconButton)).width, 40);
      expect(
        tester.getSize(find.byType(IconButton)).height,
        greaterThanOrEqualTo(40),
      );
    });

    testWidgets('shows close button when onDismiss is provided', (
      tester,
    ) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk'],
              enabled: true,
              onItemTap: (_) {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('no close button when onDismiss is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk'],
              enabled: true,
              onItemTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('uses horizontal scrollable row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddChips(
              itemNames: ['Milk', 'Eggs', 'Bread', 'Butter', 'Cheese'],
              enabled: true,
              onItemTap: (_) {},
            ),
          ),
        ),
      );

      // Horizontal ListView, not Wrap
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Cheese'), findsOneWidget);
    });
  });
}
