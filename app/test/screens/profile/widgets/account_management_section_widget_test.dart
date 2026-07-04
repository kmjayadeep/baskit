import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/screens/profile/widgets/account_management_section_widget.dart';

void main() {
  group('AccountManagementSectionWidget', () {
    testWidgets('shows an obvious account deletion request entry point', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountManagementSectionWidget(isAnonymous: false),
          ),
        ),
      );

      expect(find.text('Account management'), findsOneWidget);
      expect(find.text('Request account deletion'), findsOneWidget);
      expect(
        find.textContaining('Open the deletion request page'),
        findsOneWidget,
      );
    });

    testWidgets('opens the configured account deletion request page', (
      tester,
    ) async {
      final launchedUris = <Uri>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountManagementSectionWidget(
              isAnonymous: false,
              launchAccountDeletionRequest: (uri) async {
                launchedUris.add(uri);
                return true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Request account deletion'));
      await tester.pump();

      expect(launchedUris, [AccountManagementSectionWidget.accountDeletionUri]);
    });

    testWidgets('shows a safe guest-mode explanation without hiding the link', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccountManagementSectionWidget(isAnonymous: true),
          ),
        ),
      );

      expect(find.text('Request account deletion'), findsOneWidget);
      expect(find.textContaining('guest mode'), findsOneWidget);
      expect(find.textContaining('stay on this device'), findsOneWidget);
    });

    testWidgets('shows an error when the deletion request page cannot open', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountManagementSectionWidget(
              isAnonymous: false,
              launchAccountDeletionRequest: (_) async => false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Request account deletion'));
      await tester.pump();

      expect(
        find.text('Could not open account deletion request page'),
        findsOneWidget,
      );
    });
  });
}
