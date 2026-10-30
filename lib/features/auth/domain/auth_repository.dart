import 'session_user.dart';

/// Everything the app needs from the CRM's auth endpoints.
///
/// An interface so the session view-model depends on the idea of signing in,
/// not on `http` or on a token store. Tests drive it with a fake; the real
/// one is injected at a single provider.
abstract interface class AuthRepository {
  /// `POST /login`. Stores the token on success.
  ///
  /// Throws `ValidationException` for bad credentials (the API answers 422),
  /// `ForbiddenException` for a role that may not use the CRM.
  Future<SessionUser> login({
    required String username,
    required String password,
  });

  /// Re-establishes a session from the stored token via `GET /me`.
  ///
  /// Returns null when there is no token, or when the stored one is no longer
  /// accepted -- in which case the token is cleared first, so the next launch
  /// goes straight to login.
  Future<SessionUser?> restore();

  /// `POST /logout`, then clears the token locally.
  ///
  /// The local clear happens even if the call fails: a user who taps Sign out
  /// on a dead connection must still end up signed out on this device.
  Future<void> logout();
}
