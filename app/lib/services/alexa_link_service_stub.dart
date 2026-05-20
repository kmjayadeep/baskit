/// Stub implementation of Alexa account linking.
/// Only used when neither dart:io nor dart:html is available.
class AlexaLinkService {
  static const String oauthEndpoint =
      'https://alexaoauth-pwg4gg4vla-oa.a.run.app/oauth/authorize';
  static const String clientId = 'baskit-alexa-dev';
  static const String redirectUri =
      'https://pitangui.amazon.com/api/skill/link/M1KCN5NI02NKKB';
  static const String scope = 'baskit.voice';

  /// Stub — not supported on this platform.
  static Future<bool> linkAlexaAccount(String idToken) async {
    return false;
  }
}
