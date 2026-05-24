import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'alexa_account_linking.dart';

/// Native implementation for Alexa account-linking handoff.
class AlexaLinkService {
  static const String authorizeCompleteEndpoint =
      'https://alexaoauth-pwg4gg4vla-oa.a.run.app/oauth/authorize/complete';
  static const String alexaSkillLinkUrl =
      'https://pitangui.amazon.com/api/skill/link/M1KCN5NI02NKKB';

  static Future<AlexaAuthorizationCompleteResult> completeAuthorization({
    required AlexaLinkParams params,
    required String idToken,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse(authorizeCompleteEndpoint),
      );
      request.headers.contentType = ContentType(
        'application/x-www-form-urlencoded',
        'utf-8',
      );
      request.write(encodeFormBody(params.toBackendFields(idToken: idToken)));

      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AlexaLinkException(_errorMessage(body, response.statusCode));
      }

      return AlexaAuthorizationCompleteResult.fromJson(decodeJsonObject(body));
    } finally {
      client.close();
    }
  }

  static Future<bool> openAlexaRedirect(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openAlexaSkill() async {
    final uri = Uri.parse(alexaSkillLinkUrl);
    if (!await canLaunchUrl(uri)) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _errorMessage(String body, int statusCode) {
    try {
      final decoded = decodeJsonObject(body);
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) {
        return 'Account linking failed: $error';
      }
    } catch (_) {
      debugPrint('Could not parse Alexa linking error response.');
    }
    return 'Account linking failed with status $statusCode.';
  }
}
