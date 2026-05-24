// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'alexa_account_linking.dart';

/// Web implementation for Alexa account-linking handoff.
class AlexaLinkService {
  static const String authorizeCompleteEndpoint =
      'https://baskit-b54b5.web.app/oauth/authorize/complete';
  static const String alexaSkillLinkUrl =
      'https://alexa.amazon.com/spa/index.html#skills/search/Baskit';

  static Future<AlexaAuthorizationCompleteResult> completeAuthorization({
    required AlexaLinkParams params,
    required String idToken,
  }) async {
    final fields = params.toBackendFields(idToken: idToken);
    debugPrint(
      'Completing Alexa linking with fields: '
      '${fields.keys.where((key) => key != 'id_token').join(', ')}, '
      'has_id_token=${fields['id_token']?.isNotEmpty == true}',
    );

    final response = await html.HttpRequest.request(
      authorizeCompleteEndpoint,
      method: 'POST',
      requestHeaders: {
        'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
      },
      sendData: encodeFormBody(fields),
    );

    final status = response.status ?? 0;
    final body = response.responseText ?? '';
    if (status < 200 || status >= 300) {
      throw AlexaLinkException('Account linking failed with status $status.');
    }

    return AlexaAuthorizationCompleteResult.fromJson(decodeJsonObject(body));
  }

  static Future<bool> openAlexaRedirect(Uri uri) async {
    html.window.location.href = uri.toString();
    return true;
  }

  static Future<bool> openAlexaSkill() async {
    html.window.open(alexaSkillLinkUrl, '_blank');
    return true;
  }
}
