import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baskit/services/alexa_account_linking.dart';
import 'package:baskit/services/alexa_link_service_native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHeaders extends Fake implements HttpHeaders {
  @override
  ContentType? contentType;
}

class FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  FakeResponse(this.statusCode, this.body);

  @override
  final int statusCode;
  final String body;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRequest extends Fake implements HttpClientRequest {
  FakeRequest(this.response);

  final FakeResponse response;
  final body = StringBuffer();

  @override
  final headers = FakeHeaders();

  @override
  void write(Object? object) => body.write(object);

  @override
  Future<HttpClientResponse> close() async => response;
}

class FakeClient extends Fake implements HttpClient {
  FakeClient(this.request, {this.error});

  final FakeRequest request;
  final Object? error;
  Uri? postedUri;
  bool closed = false;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = Duration.zero;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    postedUri = url;
    if (error != null) throw error!;
    return request;
  }

  @override
  void close({bool force = false}) => closed = true;
}

void main() {
  const params = AlexaLinkParams(
    responseType: 'code',
    clientId: 'alexa-client',
    redirectUri: 'https://alexa.amazon.com/callback',
    state: 'state + &',
    codeChallenge: 'challenge',
    codeChallengeMethod: 'S256',
  );

  Future<AlexaAuthorizationCompleteResult> authorize(FakeClient client) =>
      HttpOverrides.runZoned(
        () => AlexaLinkService.completeAuthorization(
          params: params,
          idToken: 'token + &',
        ),
        createHttpClient: (_) => client,
      );

  test(
    'posts encoded authorization fields with timeouts and closes client',
    () async {
      final request = FakeRequest(
        FakeResponse(200, '{"authorizationCode":"code-1","expiresIn":120}'),
      );
      final client = FakeClient(request);

      final result = await authorize(client);

      expect(result.authorizationCode, 'code-1');
      expect(result.expiresIn, 120);
      expect(
        client.postedUri.toString(),
        AlexaLinkService.authorizeCompleteEndpoint,
      );
      expect(client.connectionTimeout, const Duration(seconds: 10));
      expect(client.idleTimeout, const Duration(seconds: 10));
      expect(
        request.headers.contentType?.mimeType,
        'application/x-www-form-urlencoded',
      );
      expect(request.headers.contentType?.charset, 'utf-8');
      expect(
        Uri.splitQueryString(request.body.toString()),
        params.toBackendFields(idToken: 'token + &'),
      );
      expect(client.closed, isTrue);
    },
  );

  for (final response in [
    FakeResponse(400, '{"error":"invalid_request"}'),
    FakeResponse(503, '<html>Unavailable</html>'),
    FakeResponse(500, '{"error":null}'),
  ]) {
    test('reports HTTP ${response.statusCode} and closes client', () async {
      final client = FakeClient(FakeRequest(response));
      final message = response.statusCode == 400
          ? 'Account linking failed: invalid_request'
          : 'Account linking failed with status ${response.statusCode}.';

      await expectLater(
        authorize(client),
        throwsA(
          isA<AlexaLinkException>().having(
            (e) => e.message,
            'message',
            message,
          ),
        ),
      );
      expect(client.closed, isTrue);
    });
  }

  test('closes client when a successful response is malformed', () async {
    final client = FakeClient(FakeRequest(FakeResponse(200, 'not JSON')));
    await expectLater(authorize(client), throwsFormatException);
    expect(client.closed, isTrue);
  });

  test('closes client when connection fails', () async {
    final error = const SocketException('Offline');
    final client = FakeClient(
      FakeRequest(FakeResponse(200, '{}')),
      error: error,
    );
    await expectLater(authorize(client), throwsA(same(error)));
    expect(client.closed, isTrue);
  });
}
