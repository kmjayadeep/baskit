import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native (mobile/desktop) implementation of Alexa account linking.
///
/// POSTs the Firebase ID token to the OAuth endpoint, then opens
/// the resulting redirect URL in the system browser.
class AlexaLinkService {
  static const String oauthEndpoint =
      'https://alexaoauth-pwg4gg4vla-oa.a.run.app/oauth/authorize';
  static const String clientId = 'baskit-alexa-dev';
  static const String redirectUri =
      'https://pitangui.amazon.com/api/skill/link/M1KCN5NI02NKKB';
  static const String scope = 'baskit.voice';

  /// Start the Alexa account linking flow.
  /// Requires a valid Firebase ID token.
  static Future<bool> linkAlexaAccount(String idToken) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(oauthEndpoint));
      request.headers.contentType =
          ContentType('application/x-www-form-urlencoded', 'utf-8');
      request.followRedirects = false;

      final body = <String, String>{
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scope,
        'id_token': idToken,
      };

      final formData = body.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      request.write(formData);

      final response = await request.close();

      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location');
        if (location != null) {
          debugPrint('🔗 Following Alexa redirect: $location');
          final uri = Uri.parse(location);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }

      debugPrint(
        '❌ Unexpected response from OAuth endpoint: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ Error in Alexa link flow: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
