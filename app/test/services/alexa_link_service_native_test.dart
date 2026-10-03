import 'package:baskit/services/alexa_link_service_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlexaLinkService', () {
    group('endpoint URLs', () {
      test('has correct authorize complete endpoint', () {
        expect(
          AlexaLinkService.authorizeCompleteEndpoint,
          'https://baskit.cboxlab.com/oauth/authorize/complete',
        );
      });

      test('has correct alexa skill link URL', () {
        expect(
          AlexaLinkService.alexaSkillLinkUrl,
          'https://alexa.amazon.com/spa/index.html#skills/search/Baskit',
        );
      });

      test('has correct alexa skill search fallback URL', () {
        expect(
          AlexaLinkService.alexaSkillSearchFallbackUrl,
          'https://www.amazon.com/s?k=Baskit&i=alexa-skills',
        );
      });
    });

    group('openAlexaSkill', () {
      test('returns true or false depending on platform', () async {
        // On non-platform tests, launchUrl may fail gracefully.
        // We just verify it doesn't throw.
        await expectLater(
          AlexaLinkService.openAlexaSkill(),
          returnsNormally,
        );
      });

      test('returns a boolean', () async {
        final result = await AlexaLinkService.openAlexaSkill();
        expect(result, isA<bool>());
      });
    });

    group('openAlexaRedirect', () {
      test('returns false for invalid URI', () async {
        final result =
            await AlexaLinkService.openAlexaRedirect(Uri.parse('invalid://'));
        expect(result, isFalse);
      });

      test('handles malformed URI', () async {
        await expectLater(
          AlexaLinkService.openAlexaRedirect(
            Uri.parse('https://example.com?param=%ZZ'),
          ),
          returnsNormally,
        );
      });

      test('returns boolean', () async {
        final result =
            await AlexaLinkService.openAlexaRedirect(Uri.parse('https://example.com'));
        expect(result, isA<bool>());
      });
    });
  });
}
