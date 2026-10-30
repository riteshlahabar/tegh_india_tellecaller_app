import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:telecaller_app/core/network/api_client.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/core/storage/token_store.dart';

/// In-memory [TokenStore], so these tests touch no platform channel.
class _FakeTokenStore implements TokenStore {
  _FakeTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

HttpApiClient _clientReturning(
  http.Response response, {
  String? token,
  void Function()? onUnauthorized,
  void Function(http.Request request)? capture,
}) {
  return HttpApiClient(
    tokenStore: _FakeTokenStore(token),
    baseUrl: 'https://example.test/api',
    onUnauthorized: onUnauthorized,
    client: MockClient((request) async {
      capture?.call(request);
      return response;
    }),
  );
}

void main() {
  group('request shaping', () {
    test('attaches the bearer token when one is stored', () async {
      http.Request? seen;
      final client = _clientReturning(
        http.Response('{"ok":true}', 200),
        token: 'abc123',
        capture: (request) => seen = request,
      );

      await client.get('me');

      expect(seen!.headers['Authorization'], 'Bearer abc123');
      expect(seen!.headers['Accept'], 'application/json');
    });

    test('omits Authorization entirely when signed out', () async {
      http.Request? seen;
      final client = _clientReturning(
        http.Response('{"ok":true}', 200),
        capture: (request) => seen = request,
      );

      await client.get('dashboard');

      expect(seen!.headers.containsKey('Authorization'), isFalse);
    });

    test('drops null and empty query values', () async {
      http.Request? seen;
      final client = _clientReturning(
        http.Response('{"ok":true}', 200),
        capture: (request) => seen = request,
      );

      await client.get('outstanding', query: {
        'status': 'Overdue',
        'city': '',
        'company': null,
      });

      expect(seen!.url.queryParameters, {'status': 'Overdue'});
    });

    test('joins the path whether or not it has a leading slash', () async {
      http.Request? seen;
      final client = _clientReturning(
        http.Response('{"ok":true}', 200),
        capture: (request) => seen = request,
      );

      await client.get('/calls');

      expect(seen!.url.toString(), 'https://example.test/api/calls');
    });

    test('posts the body as JSON', () async {
      http.Request? seen;
      final client = _clientReturning(
        http.Response('{"ok":true}', 200),
        capture: (request) => seen = request,
      );

      await client.post('login', body: {'username': 'amol', 'password': '1234'});

      expect(jsonDecode(seen!.body), {'username': 'amol', 'password': '1234'});
    });
  });

  group('status mapping', () {
    test('401 throws UnauthorizedException and fires the callback once',
        () async {
      int fired = 0;
      final client = _clientReturning(
        http.Response('{"message":"Unauthenticated."}', 401),
        onUnauthorized: () => fired++,
      );

      await expectLater(
        client.get('me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(fired, 1);
    });

    test('403 keeps the server message', () async {
      final client = _clientReturning(
        http.Response(
          '{"message":"This account cannot access the CRM app."}',
          403,
        ),
      );

      await expectLater(
        client.get('me'),
        throwsA(
          isA<ForbiddenException>().having(
            (e) => e.message,
            'message',
            'This account cannot access the CRM app.',
          ),
        ),
      );
    });

    test('404 throws NotFoundException', () async {
      final client = _clientReturning(http.Response('', 404));

      await expectLater(
        client.get('invoices/9999'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('422 carries Laravel field errors', () async {
      final client = _clientReturning(
        http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'password': ['The password field is required.'],
            },
          }),
          422,
        ),
      );

      try {
        await client.post('login');
        fail('expected a ValidationException');
      } on ValidationException catch (error) {
        expect(error.message, 'The given data was invalid.');
        expect(error.forField('password'), 'The password field is required.');
        expect(error.forField('username'), isNull);
      }
    });

    test('500 throws ServerException', () async {
      final client = _clientReturning(http.Response('<html>oops</html>', 500));

      await expectLater(
        client.get('dashboard'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('body decoding', () {
    test('an empty 200 body decodes to an empty map', () async {
      final client = _clientReturning(http.Response('', 200));

      expect(await client.post('logout'), isEmpty);
    });

    test('a top-level list is wrapped under "data"', () async {
      final client = _clientReturning(http.Response('[1,2,3]', 200));

      expect(await client.get('meta'), {
        'data': [1, 2, 3],
      });
    });

    test('HTML served with a 200 throws UnexpectedResponseException', () async {
      final client = _clientReturning(http.Response('<!doctype html>', 200));

      await expectLater(
        client.get('dashboard'),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });
  });

  group('transport failures', () {
    test('a socket failure becomes NetworkException', () async {
      final client = HttpApiClient(
        tokenStore: _FakeTokenStore(),
        baseUrl: 'https://example.test/api',
        client: MockClient((_) => throw const SocketException('no route')),
      );

      await expectLater(
        client.get('dashboard'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a slow server becomes RequestTimeoutException', () async {
      final client = HttpApiClient(
        tokenStore: _FakeTokenStore(),
        baseUrl: 'https://example.test/api',
        timeout: const Duration(milliseconds: 30),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        client.get('dashboard'),
        throwsA(isA<RequestTimeoutException>()),
      );
    });
  });
}
