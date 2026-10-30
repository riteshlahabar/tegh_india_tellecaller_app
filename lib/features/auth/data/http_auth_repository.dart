// Initializing formals would push the private field names into the public
// constructor, so callers would write `HttpAuthRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';

/// [AuthRepository] against `routes/api.php`.
class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository({
    required ApiClient client,
    required TokenStore tokenStore,
  })  : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final TokenStore _tokenStore;

  @override
  Future<SessionUser> login({
    required String username,
    required String password,
  }) async {
    final Map<String, dynamic> body = await _client.post(
      'login',
      body: <String, dynamic>{'username': username, 'password': password},
    );

    final String? token = body['token'] as String?;
    final Object? user = body['user'];

    if (token == null || token.isEmpty || user is! Map<String, dynamic>) {
      throw const UnexpectedResponseException(
        'Signed in, but the server did not return a session.',
      );
    }

    // Written before returning, so the very next request is authenticated.
    await _tokenStore.write(token);

    return SessionUser.fromJson(user);
  }

  @override
  Future<SessionUser?> restore() async {
    final String? token = await _tokenStore.read();
    if (token == null) {
      return null;
    }

    try {
      final Map<String, dynamic> body = await _client.get('me');
      final Object? user = body['user'];

      if (user is! Map<String, dynamic>) {
        return null;
      }
      return SessionUser.fromJson(user);
    } on UnauthorizedException {
      // Revoked, expired, or the database was reseeded under us. Drop it so
      // the next launch does not repeat this round trip.
      await _tokenStore.clear();
      return null;
    } on ForbiddenException {
      // The account still exists but may no longer use the CRM.
      await _tokenStore.clear();
      return null;
    }
    // Network and server failures deliberately propagate: a flat battery of a
    // connection is not a reason to throw away a valid session.
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('logout');
    } on ApiException {
      // Best effort. The token may already be dead, or the phone offline --
      // either way this device is signing out.
    } finally {
      await _tokenStore.clear();
    }
  }
}
