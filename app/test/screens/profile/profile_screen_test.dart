import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:baskit/screens/profile/profile_screen.dart';
import 'package:baskit/screens/profile/widgets/about_section_widget.dart';
import 'package:baskit/view_models/auth_view_model.dart';

class FakeAuthViewModel extends AuthViewModel {
  FakeAuthViewModel(this.authState);

  final AuthState authState;

  @override
  AuthState build() => authState;
}

void main() {
  group('ProfileScreen account deletion flow', () {
    tearDown(() {
      AboutSectionWidget.launchUrlOverrideForTest = null;
    });

    testWidgets(
      'opens account deletion URL from Profile About without production Firebase',
      (tester) async {
        Uri? launchedUri;
        LaunchMode? launchMode;
        AboutSectionWidget.launchUrlOverrideForTest = (uri, mode) async {
          launchedUri = uri;
          launchMode = mode;
          return true;
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authViewModelProvider.overrideWith(
                () => FakeAuthViewModel(const AuthState.initial()),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('About Baskit'));
        await tester.tap(find.text('About Baskit'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Request account deletion'));
        await tester.pumpAndSettle();

        expect(
          launchedUri,
          Uri.parse('https://kmjayadeep.github.io/baskit/delete-account.html'),
        );
        expect(launchMode, LaunchMode.externalApplication);
      },
    );
  });
}
