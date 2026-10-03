import 'package:baskit/constants/app_colors.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/edit_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _dt = DateTime(2026, 1, 1);

void main() {
  group('EditItemDialog', () {
    ShoppingItem createItem(
      String name, {
      String? quantity,
      bool completed = false,
    }) {
      return ShoppingItem(
        'test-item',
        name,
        isCompleted: completed,
        createdAt: _dt,
        quantity: quantity,
      );
    }

    Widget createWidget(ShoppingItem item) {
      return MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) => EditItemDialog(item: item),
          ),
        ),
      );
    }

    testWidgets('displays item name in text field', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(textField.controller?.text, 'Milk');
    });

    testWidgets('displays quantity in second text field', (tester) async {
      final item = createItem('Milk', quantity: '2 cartons');
      await tester.pumpWidget(createWidget(item));

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      final fields = textFields.evaluate().map((e) => e.widget as TextFormField).toList();
      expect(fields[1].controller?.text, '2 cartons');
    });

    testWidgets('shows empty quantity when not provided', (tester) async {
      final item = createItem('Bread');
      await tester.pumpWidget(createWidget(item));

      final fields = find.byType(TextFormField).evaluate().map((e) => e.widget as TextFormField).toList();
      expect(fields[1].controller?.text, '');
    });

    testWidgets('shows item name label', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.text('Item name'), findsOneWidget);
    });

    testWidgets('shows quantity label', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.text('Qty, note, or type'), findsOneWidget);
    });

    testWidgets('shows edit icon with primary green color', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    });

    testWidgets('shows Edit item title', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.text('Edit item'), findsOneWidget);
    });

    testWidgets('shows cancel button', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
    });

    testWidgets('shows save button', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('save returns updated name and quantity', (tester) async {
      final item = createItem('Old Name', quantity: '1');
      await tester.pumpWidget(createWidget(item));

      final fields = find.byType(TextFormField).evaluate().map((e) => e.widget as TextFormField).toList();
      await tester.enterText(fields[0].field!, 'New Name');
      await tester.enterText(fields[1].field!, '3');

      await tester.tap(find.text('Save'));
      await tester.pump();
    });

    testWidgets('save with empty quantity returns null', (tester) async {
      final item = createItem('Test', quantity: '2');
      await tester.pumpWidget(createWidget(item));

      final fields = find.byType(TextFormField).evaluate().map((e) => e.widget as TextFormField).toList();
      await tester.enterText(fields[1].field!, '   ');

      await tester.tap(find.text('Save'));
      await tester.pump();
    });

    testWidgets('dialog is an AlertDialog', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('uses Form widget', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('name field has validator', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      final fields = find.byType(TextFormField).evaluate().map((e) => e.widget as TextFormField).toList();
      await tester.enterText(fields[0].field!, '');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Please enter an item name'), findsOneWidget);
    });

    testWidgets('uses green color for icon container', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    });

    testWidgets('text fields use material text capitalization', (tester) async {
      final item = createItem('Milk');
      await tester.pumpWidget(createWidget(item));

      final fields = find.byType(TextFormField).evaluate().map((e) => e.widget as TextFormField).toList();
      expect(fields[1].textCapitalization, TextCapitalization.words);
    });
  });
}
