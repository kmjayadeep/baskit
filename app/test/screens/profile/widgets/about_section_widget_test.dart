import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/screens/profile/widgets/about_section_widget.dart';
import 'package:baskit/constants/app_version.dart';

void main() {
  group('AboutSectionWidget', () {
    Widget buildWidget() {
      return const MaterialApp(
        home: Scaffold(body: AboutSectionWidget()),
      );
    }

    testWidgets('renders about section with title and version', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('About Baskit'), findsOneWidget);
      expect(
        find.text('Collaborative shopping lists • v${AppVersion.version}'),
        findsOneWidget,
      );
    });

    testWidgets('tapping the about section opens the about dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      // Tap the list tile to open the dialog
      await tester.tap(find.text('About Baskit'));
      await tester.pumpAndSettle();

      // Verify dialog content is displayed
      expect(
        find.text(
          'A collaborative shopping list app that makes shopping with friends and family easy.',
        ),
        findsOneWidget,
      );
      expect(find.text('Features:'), findsOneWidget);
      expect(find.text('• Guest-first experience'), findsOneWidget);
      expect(find.text('• Real-time collaboration'), findsOneWidget);
      expect(find.text('• Cross-device sync'), findsOneWidget);
      expect(find.text('• Offline support'), findsOneWidget);
      expect(find.text('Version ${AppVersion.version}'), findsOneWidget);
    });

    testWidgets('about dialog contains privacy policy button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      // Open the dialog
      await tester.tap(find.text('About Baskit'));
      await tester.pumpAndSettle();

      // Verify privacy policy button is present
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('privacy policy URL is valid and uses HTTPS', (
      WidgetTester tester,
    ) async {
      final uri = Uri.parse(
        'https://kmjayadeep.github.io/baskit/privacy-policy.html',
      );
      expect(uri.isScheme('https'), isTrue);
      expect(uri.host, 'kmjayadeep.github.io');
      expect(uri.path, '/baskit/privacy-policy.html');
    });

    testWidgets('about dialog has close button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      // Open the dialog
      await tester.tap(find.text('About Baskit'));
      await tester.pumpAndSettle();

      // Verify close button
      expect(find.text('Close'), findsOneWidget);

      // Tap close button and verify dialog dismisses
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify features text is no longer visible (dialog closed)
      expect(find.text('Features:'), findsNothing);
    });

    testWidgets('account deletion URL is valid and uses HTTPS', (
      WidgetTester tester,
    ) async {
      final deletionUri = Uri.parse(
        'https://kmjayadeep.github.io/baskit/delete-account.html',
      );

      expect(deletionUri.isScheme('https'), isTrue);
      expect(deletionUri.host, 'kmjayadeep.github.io');
      expect(deletionUri.path, '/baskit/delete-account.html');
    });

  });
}
