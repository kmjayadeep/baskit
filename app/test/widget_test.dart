// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BaskitApp());

    // Verify that the login screen loads
    expect(find.text('Baskit'), findsOneWidget);
    expect(find.text('Collaborative Shopping Lists'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Navigation to register screen works', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BaskitApp());

    // Find and tap the register link
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle();

    // Verify that we navigated to register screen
    expect(find.text('Join Baskit'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });
}
