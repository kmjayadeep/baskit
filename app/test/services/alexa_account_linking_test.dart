import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/services/alexa_account_linking.dart';

void main() {
  group('AlexaLinkParams', () {
    test('parses valid account linking URI', () {
      final params = AlexaLinkParams.fromUri(
        Uri.parse(
          'baskit://integrations/alexa/link?response_type=code&client_id=client-1&redirect_uri=https%3A%2F%2Falexa.amazon.com%2Fcallback&scope=baskit.voice&state=state-1',
        ),
      );

      expect(params, isNotNull);
      expect(params!.isValid, true);
      expect(params.responseType, 'code');
      expect(params.clientId, 'client-1');
      expect(params.redirectUri, 'https://alexa.amazon.com/callback');
      expect(params.scope, 'baskit.voice');
      expect(params.state, 'state-1');
    });

    test('preserves PKCE params from Alexa request', () {
      final params = AlexaLinkParams.fromUri(
        Uri.parse(
          'baskit://integrations/alexa/link?response_type=code&client_id=client-1&redirect_uri=https%3A%2F%2Falexa.amazon.com%2Fcallback&code_challenge=challenge-1&code_challenge_method=S256',
        ),
      );

      expect(params, isNotNull);
      expect(params!.codeChallenge, 'challenge-1');
      expect(params.codeChallengeMethod, 'S256');
      expect(params.toBackendFields(idToken: 'id-token'), {
        'response_type': 'code',
        'client_id': 'client-1',
        'redirect_uri': 'https://alexa.amazon.com/callback',
        'code_challenge': 'challenge-1',
        'code_challenge_method': 'S256',
        'id_token': 'id-token',
      });
    });

    test('rejects missing required params', () {
      final params = AlexaLinkParams.fromUri(
        Uri.parse('baskit://integrations/alexa/link?response_type=code'),
      );

      expect(params, isNull);
    });

    test('encodes backend fields without empty optional params', () {
      const params = AlexaLinkParams(
        responseType: 'code',
        clientId: 'client-1',
        redirectUri: 'https://alexa.amazon.com/callback',
      );

      expect(params.toBackendFields(idToken: 'id-token'), {
        'response_type': 'code',
        'client_id': 'client-1',
        'redirect_uri': 'https://alexa.amazon.com/callback',
        'id_token': 'id-token',
      });
    });
  });

  group('Alexa redirects', () {
    const params = AlexaLinkParams(
      responseType: 'code',
      clientId: 'client-1',
      redirectUri: 'https://alexa.amazon.com/callback?existing=1',
      scope: 'baskit.voice',
      state: 'state-1',
    );

    test('builds success redirect with code and state', () {
      final redirect = buildAlexaSuccessRedirect(
        params,
        const AlexaAuthorizationCompleteResult(
          authorizationCode: 'code-1',
          expiresIn: 300,
        ),
      );

      expect(redirect.toString(), contains('existing=1'));
      expect(redirect.queryParameters['code'], 'code-1');
      expect(redirect.queryParameters['state'], 'state-1');
    });

    test('builds cancel redirect with access denied error', () {
      final redirect = buildAlexaErrorRedirect(params, 'access_denied');

      expect(redirect.queryParameters['error'], 'access_denied');
      expect(redirect.queryParameters['state'], 'state-1');
    });
  });

  group('AlexaAuthorizationCompleteResult', () {
    test('parses backend response', () {
      final result = AlexaAuthorizationCompleteResult.fromJson({
        'authorizationCode': 'code-1',
        'expiresIn': 300,
        'state': 'state-1',
      });

      expect(result.authorizationCode, 'code-1');
      expect(result.expiresIn, 300);
      expect(result.state, 'state-1');
    });

    test('throws for missing code', () {
      expect(
        () => AlexaAuthorizationCompleteResult.fromJson({'expiresIn': 300}),
        throwsA(isA<AlexaLinkException>()),
      );
    });
  });
}
