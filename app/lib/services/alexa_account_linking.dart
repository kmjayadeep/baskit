import 'dart:convert';

class AlexaLinkParams {
  final String responseType;
  final String clientId;
  final String redirectUri;
  final String? scope;
  final String? state;

  const AlexaLinkParams({
    required this.responseType,
    required this.clientId,
    required this.redirectUri,
    this.scope,
    this.state,
  });

  bool get isValid =>
      responseType == 'code' && clientId.isNotEmpty && redirectUri.isNotEmpty;

  Map<String, String> toBackendFields({required String idToken}) {
    return {
      'response_type': responseType,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      if (scope != null && scope!.isNotEmpty) 'scope': scope!,
      if (state != null && state!.isNotEmpty) 'state': state!,
      'id_token': idToken,
    };
  }

  static AlexaLinkParams? fromUri(Uri uri) {
    final query = uri.queryParameters;
    final responseType = query['response_type']?.trim();
    final clientId = query['client_id']?.trim();
    final redirectUri = query['redirect_uri']?.trim();

    if (responseType == null || clientId == null || redirectUri == null) {
      return null;
    }

    return AlexaLinkParams(
      responseType: responseType,
      clientId: clientId,
      redirectUri: redirectUri,
      scope: _optional(query['scope']),
      state: _optional(query['state']),
    );
  }

  static AlexaLinkParams? fromQueryParameters(Map<String, String> query) {
    return fromUri(
      Uri(path: '/integrations/alexa/link', queryParameters: query),
    );
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class AlexaAuthorizationCompleteResult {
  final String authorizationCode;
  final int expiresIn;
  final String? state;

  const AlexaAuthorizationCompleteResult({
    required this.authorizationCode,
    required this.expiresIn,
    this.state,
  });

  factory AlexaAuthorizationCompleteResult.fromJson(Map<String, dynamic> json) {
    final code = json['authorizationCode'] ?? json['authorization_code'];
    final expiresIn = json['expiresIn'] ?? json['expires_in'];

    if (code is! String || code.trim().isEmpty) {
      throw const AlexaLinkException(
        'Authorization response did not include a code.',
      );
    }

    return AlexaAuthorizationCompleteResult(
      authorizationCode: code,
      expiresIn:
          expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 300,
      state: json['state'] is String ? json['state'] as String : null,
    );
  }
}

class AlexaLinkException implements Exception {
  final String message;

  const AlexaLinkException(this.message);

  @override
  String toString() => message;
}

Uri buildAlexaSuccessRedirect(
  AlexaLinkParams params,
  AlexaAuthorizationCompleteResult result,
) {
  final redirect = Uri.parse(params.redirectUri);
  return redirect.replace(
    queryParameters: {
      ...redirect.queryParameters,
      'code': result.authorizationCode,
      if ((result.state ?? params.state) != null)
        'state': (result.state ?? params.state)!,
    },
  );
}

Uri buildAlexaErrorRedirect(AlexaLinkParams params, String error) {
  final redirect = Uri.parse(params.redirectUri);
  return redirect.replace(
    queryParameters: {
      ...redirect.queryParameters,
      'error': error,
      if (params.state != null) 'state': params.state!,
    },
  );
}

String encodeFormBody(Map<String, String> fields) {
  return fields.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}='
            '${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');
}

Map<String, dynamic> decodeJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const AlexaLinkException('Backend returned an invalid response.');
  }
  return decoded;
}
