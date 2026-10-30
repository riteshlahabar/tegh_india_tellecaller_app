import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/http_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/session_user.dart';

/// Injection point for auth. Swapping in a fake is a one-line override.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (ref) => HttpAuthRepository(
    client: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  ),
);

/// Who is signed in, as a closed set.
///
/// [SessionChecking] is a real state, not a loading flag: on a cold start the
/// app genuinely does not know yet, and the splash screen is what that state
/// looks like. Sealed, so the router's redirect cannot forget a case.
sealed class SessionState {
  const SessionState();
}

/// Restoring from the stored token. The only state the splash screen shows.
final class SessionChecking extends SessionState {
  const SessionChecking();
}

/// No valid token. [message] is set when the user landed here because the
/// server rejected the session mid-use, rather than by signing out.
final class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.message});

  final String? message;
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);

  final SessionUser user;
}

/// Owns who is signed in. The only place the token's lifecycle is decided.
class SessionViewModel extends Notifier<SessionState> {
  StreamSubscription<void>? _unauthorized;

  @override
  SessionState build() {
    // A 401 from anywhere in the app lands here. Only act while signed in, so
    // a failed login (which also answers 401-adjacent codes) cannot loop.
    _unauthorized = ref.watch(unauthorizedSignalProvider).stream.listen((_) {
      if (state is SessionSignedIn) {
        state = const SessionSignedOut(
          message: 'Your session expired. Please sign in again.',
        );
      }
    });
    ref.onDispose(() => _unauthorized?.cancel());

    // Deliberately not awaited: build() must stay synchronous so the first
    // frame can render the splash immediately.
    unawaited(restore());

    return const SessionChecking();
  }

  /// Cold start. Leaves the state in [SessionChecking] only until the stored
  /// token is confirmed or found missing.
  Future<void> restore() async {
    try {
      final SessionUser? user = await ref.read(authRepositoryProvider).restore();

      state = user == null ? const SessionSignedOut() : SessionSignedIn(user);
    } catch (_) {
      // restore() only rethrows network and server failures. Treat those as
      // signed out rather than wedging on the splash forever; the token is
      // still on disk, so the next launch retries it.
      state = const SessionSignedOut(
        message: 'Could not reach the server. Please sign in.',
      );
    }
  }

  /// Signs in, or throws so the login screen can show the reason.
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final SessionUser user = await ref.read(authRepositoryProvider).login(
          username: username,
          password: password,
        );

    state = SessionSignedIn(user);
  }

  Future<void> signOut() async {
    // Flipped first: the UI should leave the signed-in area immediately,
    // not wait on a round trip that may be slow or fail.
    state = const SessionSignedOut();
    await ref.read(authRepositoryProvider).logout();
  }
}

final NotifierProvider<SessionViewModel, SessionState> sessionProvider =
    NotifierProvider<SessionViewModel, SessionState>(SessionViewModel.new);

/// The signed-in user, or null. Saves every screen a pattern match.
final Provider<SessionUser?> currentUserProvider = Provider<SessionUser?>((ref) {
  final SessionState state = ref.watch(sessionProvider);
  return state is SessionSignedIn ? state.user : null;
});
