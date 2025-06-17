// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads and shows lists screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BaskitApp());

    // Verify that the lists screen loads (app starts on /lists, not login)
    expect(find.text('My Lists'), findsOneWidget);
    expect(find.text('Welcome to Baskit! 🛒'), findsOneWidget);
    expect(
      find.text('Create and share shopping lists with friends and family'),
      findsOneWidget,
    );
  });

  // TODO: Add profile navigation test when profile access is re-enabled
}
