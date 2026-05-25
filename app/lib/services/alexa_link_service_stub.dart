import 'alexa_account_linking.dart';

/// Stub implementation of Alexa account linking.
class AlexaLinkService {
  static const String authorizeCompleteEndpoint =
      'https://baskit.cboxlab.com/oauth/authorize/complete';
  static const String alexaSkillLinkUrl =
      'https://alexa.amazon.com/spa/index.html#skills/search/Baskit';

  static Future<AlexaAuthorizationCompleteResult> completeAuthorization({
    required AlexaLinkParams params,
    required String idToken,
  }) async {
    throw const AlexaLinkException('Alexa linking is not supported here.');
  }

  static Future<bool> openAlexaRedirect(Uri uri) async => false;

  static Future<bool> openAlexaSkill() async => false;
}
