import 'package:shared_preferences/shared_preferences.dart';

import 'token_store.dart';

/// [TokenStore] backed by `shared_preferences`.
///
/// Not secure storage: on a rooted or jailbroken device this value is
/// readable. It is a CRM session token with no payment rights, and the server
/// can revoke it, so the trade is deliberate -- swapping in
/// `flutter_secure_storage` later means writing one class and overriding
/// [tokenStoreProvider], with nothing else touched.
class PrefsTokenStore implements TokenStore {
  const PrefsTokenStore(this._prefs);

  static const String _key = 'auth_token';

  final SharedPreferences _prefs;

  @override
  Future<String?> read() async {
    final String? token = _prefs.getString(_key);
    return (token == null || token.isEmpty) ? null : token;
  }

  @override
  Future<void> write(String token) => _prefs.setString(_key, token);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
