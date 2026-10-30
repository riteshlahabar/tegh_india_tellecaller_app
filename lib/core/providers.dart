import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/api_client.dart';
import 'network/unauthorized_signal.dart';
import 'storage/prefs_token_store.dart';
import 'storage/token_store.dart';

/// Overridden in `main()` once [SharedPreferences] has loaded.
///
/// Reading it before that override is a programming error, not a runtime
/// condition, so it throws rather than returning null -- every consumer can
/// then treat preferences as synchronously available.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);

/// The single injection point for token storage.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (ref) => PrefsTokenStore(ref.watch(sharedPreferencesProvider)),
);

/// Fires whenever the server answers 401. The session view-model listens and
/// signs out; nothing in `core/` knows that is the consequence.
final Provider<UnauthorizedSignal> unauthorizedSignalProvider =
    Provider<UnauthorizedSignal>((ref) {
  final UnauthorizedSignal signal = UnauthorizedSignal();
  ref.onDispose(signal.dispose);
  return signal;
});

/// The single injection point for network access. Repositories depend on
/// [ApiClient]; only this line names an implementation.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final UnauthorizedSignal signal = ref.watch(unauthorizedSignalProvider);

  return HttpApiClient(
    tokenStore: ref.watch(tokenStoreProvider),
    onUnauthorized: signal.fire,
  );
});
