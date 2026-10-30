import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecaller_app/app/tegh_app.dart';
import 'package:telecaller_app/core/providers.dart';
import 'package:telecaller_app/features/auth/domain/auth_repository.dart';
import 'package:telecaller_app/features/auth/domain/session_user.dart';
import 'package:telecaller_app/features/auth/presentation/session_view_model.dart';
import 'package:telecaller_app/features/home/domain/home_repository.dart';
import 'package:telecaller_app/features/home/presentation/home_view_model.dart';
import 'package:telecaller_app/features/outstanding/domain/outstanding_repository.dart';
import 'package:telecaller_app/features/outstanding/presentation/outstanding_view_model.dart';

import 'fake_home_repository.dart';
import 'fake_outstanding_repository.dart';

/// The account the signed-in tests run as.
const SessionUser kTestUser = SessionUser(
  id: 2,
  name: 'Aakanksha',
  username: 'aakanksha',
  email: 'aakanksha@teghcables.com',
  role: 'telecaller',
  roleLabel: 'Payment Follow-up Executive',
  initials: 'AK',
  scoped: true,
  region: 'mumbai',
  regionLabel: 'Mumbai',
  city: 'Bhiwandi',
);

/// Scriptable [AuthRepository]: no network, no token store.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.restored,
    this.onLogin,
  });

  /// What `restore()` answers -- null means "no stored session".
  final SessionUser? restored;

  /// Lets a test make `login()` throw, or return a different user.
  final Future<SessionUser> Function(String username, String password)? onLogin;

  int logoutCalls = 0;

  @override
  Future<SessionUser?> restore() async => restored;

  @override
  Future<SessionUser> login({
    required String username,
    required String password,
  }) async {
    final handler = onLogin;
    if (handler != null) {
      return handler(username, password);
    }
    return kTestUser;
  }

  @override
  Future<void> logout() async => logoutCalls++;
}

/// Pumps the real app with auth faked out.
///
/// Every test needs the preferences override too, because the router now
/// reaches the session on its first build and that resolves the token store.
Future<void> pumpApp(
  WidgetTester tester, {
  AuthRepository? auth,
  HomeRepository? home,
  OutstandingRepository? outstanding,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final SharedPreferences preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(restored: kTestUser),
        ),
        // Home now talks to the real API, so a widget test that did not
        // override this would try to reach the live CRM.
        homeRepositoryProvider.overrideWithValue(
          home ?? const FakeHomeRepository(),
        ),
        outstandingRepositoryProvider.overrideWithValue(
          outstanding ?? FakeOutstandingRepository(),
        ),
      ],
      child: const TeghApp(),
    ),
  );

  await tester.pumpAndSettle();
}
