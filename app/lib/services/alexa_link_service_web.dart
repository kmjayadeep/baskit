// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Web implementation of Alexa account linking.
///
/// Creates a hidden HTML form, populates it with the OAuth parameters
/// and Firebase ID token, then submits it via POST. The browser follows
/// the 302 redirect to Alexa's account linking page automatically.
class AlexaLinkService {
  static const String oauthEndpoint =
      'https://alexaoauth-pwg4gg4vla-oa.a.run.app/oauth/authorize';
  static const String clientId = 'baskit-alexa-dev';
  static const String redirectUri =
      'https://pitangui.amazon.com/api/skill/link/M1KCN5NI02NKKB';
  static const String scope = 'baskit.voice';

  /// Start the Alexa account linking flow.
  /// Requires a valid Firebase ID token.
  static bool linkAlexaAccount(String idToken) {
    try {
      final form = html.document.createElement('form') as html.FormElement;
      form.method = 'post';
      form.action = oauthEndpoint;
      form.target = '_blank';
      form.style.display = 'none';

      void addField(String name, String value) {
        final input =
            html.document.createElement('input') as html.InputElement;
        input.type = 'hidden';
        input.name = name;
        input.value = value;
        form.append(input);
      }

      addField('response_type', 'code');
      addField('client_id', clientId);
      addField('redirect_uri', redirectUri);
      addField('scope', scope);
      addField('id_token', idToken);

      html.document.body?.append(form);
      form.submit();
      form.remove();

      debugPrint('✅ Alexa link form submitted via POST');
      return true;
    } catch (e) {
      debugPrint('❌ Error in Alexa link web flow: $e');
      return false;
    }
  }
}
