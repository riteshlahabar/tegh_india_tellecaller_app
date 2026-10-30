import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/core/storage/prefs_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsTokenStore> storeWith(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    return PrefsTokenStore(await SharedPreferences.getInstance());
  }

  test('reads back what it wrote', () async {
    final store = await storeWith({});

    await store.write('token-123');

    expect(await store.read(), 'token-123');
  });

  test('reads null when nothing was ever stored', () async {
    final store = await storeWith({});

    expect(await store.read(), isNull);
  });

  test('treats a stored empty string as signed out', () async {
    // A half-finished write, or a cleared value some platforms persist as ''.
    // Returning it would send a `Bearer ` header and earn a 401 on every call.
    final store = await storeWith({'auth_token': ''});

    expect(await store.read(), isNull);
  });

  test('clear removes the token', () async {
    final store = await storeWith({'auth_token': 'token-123'});

    await store.clear();

    expect(await store.read(), isNull);
  });
}
