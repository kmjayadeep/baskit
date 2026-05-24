import 'alexa_account_linking.dart';

/// Stub implementation of Alexa account linking.
class AlexaLinkService {
  static const String authorizeCompleteEndpoint =
      'https://baskit-b54b5.web.app/oauth/authorize/complete';
  static const String alexaSkillLinkUrl =
      'https://pitangui.amazon.com/api/skill/link/M1KCN5NI02NKKB';

  static Future<AlexaAuthorizationCompleteResult> completeAuthorization({
    required AlexaLinkParams params,
    required String idToken,
  }) async {
    throw const AlexaLinkException('Alexa linking is not supported here.');
  }

  static Future<bool> openAlexaRedirect(Uri uri) async => false;

  static Future<bool> openAlexaSkill() async => false;
}
