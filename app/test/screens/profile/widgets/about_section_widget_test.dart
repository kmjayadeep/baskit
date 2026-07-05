import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:baskit/screens/profile/widgets/about_section_widget.dart';

void main() {
  group('AboutSectionWidget account links', () {
    tearDown(() {
      AboutSectionWidget.launchUrlOverrideForTest = null;
    });

    Widget buildSubject() {
      return const MaterialApp(home: Scaffold(body: AboutSectionWidget()));
    }

    Future<void> openAboutDialog(WidgetTester tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('About Baskit'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows account deletion request entry point in Profile About', (
      tester,
    ) async {
      await openAboutDialog(tester);

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Request account deletion'), findsOneWidget);
    });

    testWidgets('opens the account deletion URL externally', (tester) async {
      Uri? launchedUri;
      LaunchMode? launchMode;
      AboutSectionWidget.launchUrlOverrideForTest = (uri, mode) async {
        launchedUri = uri;
        launchMode = mode;
        return true;
      };

      await openAboutDialog(tester);
      await tester.tap(find.text('Request account deletion'));
      await tester.pumpAndSettle();

      expect(
        launchedUri,
        Uri.parse('https://kmjayadeep.github.io/baskit/delete-account.html'),
      );
      expect(launchMode, LaunchMode.externalApplication);
    });

    testWidgets('surfaces a failure message when account deletion URL fails', (
      tester,
    ) async {
      AboutSectionWidget.launchUrlOverrideForTest = (_, _) async => false;

      await openAboutDialog(tester);
      await tester.tap(find.text('Request account deletion'));
      await tester.pump();

      expect(find.text('Could not open account deletion page'), findsOneWidget);
    });
  });
}
