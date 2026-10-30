import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/core/providers.dart';
import 'package:telecaller_app/features/auth/domain/session_user.dart';
import 'package:telecaller_app/features/auth/presentation/session_view_model.dart';

import '../support/fake_auth.dart';

void main() {
  group('routing by session state', () {
    testWidgets('no stored session lands on login', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository(restored: null));

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Username or email'), findsOneWidget);
      // The shell must not be reachable while signed out.
      expect(find.text('Outstanding'), findsNothing);
    });

    testWidgets('a stored session goes straight to home', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository(restored: kTestUser));

      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('signing in moves from login to home', (tester) async {
      await pumpApp(tester, auth: FakeAuthRepository(restored: null));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username or email'),
        'aakanksha',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '1234',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });
  });

  group('signing out', () {
    testWidgets('cancelling the dialog keeps the user signed in',
        (tester) async {
      final auth = FakeAuthRepository(restored: kTestUser);
      await pumpApp(tester, auth: auth);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(auth.logoutCalls, 0);
    });

    testWidgets('confirming returns to the login screen', (tester) async {
      final auth = FakeAuthRepository(restored: kTestUser);
      await pumpApp(tester, auth: auth);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Username or email'), findsOneWidget);
      expect(auth.logoutCalls, 1);
    });
  });

  group('login form', () {
    testWidgets('empty fields are rejected without calling the server',
        (tester) async {
      bool called = false;
      await pumpApp(
        tester,
        auth: FakeAuthRepository(
          restored: null,
          onLogin: (_, _) async {
            called = true;
            return kTestUser;
          },
        ),
      );

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your username or email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('a rejected password shows the server message', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(
          restored: null,
          onLogin: (_, _) async => throw const ValidationException(
            'Invalid username or password.',
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username or email'),
        'aakanksha',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrong',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid username or password.'), findsOneWidget);
      // Still on login.
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('an offline phone shows the network message', (tester) async {
      await pumpApp(
        tester,
        auth: FakeAuthRepository(
          restored: null,
          onLogin: (_, _) async => throw const NetworkException(),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username or email'),
        'aakanksha',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '1234',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('No connection. Check your internet and try again.'),
        findsOneWidget,
      );
    });
  });

  group('session view-model', () {
    ProviderContainer containerWith(FakeAuthRepository auth) {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts in SessionChecking before restore finishes', () {
      final container = containerWith(FakeAuthRepository(restored: kTestUser));

      expect(container.read(sessionProvider), isA<SessionChecking>());
    });

    test('restore with a user ends signed in', () async {
      final container = containerWith(FakeAuthRepository(restored: kTestUser));
      container.read(sessionProvider);

      await container.read(sessionProvider.notifier).restore();

      final state = container.read(sessionProvider);
      expect(state, isA<SessionSignedIn>());
      expect((state as SessionSignedIn).user.username, 'aakanksha');
    });

    test('restore with no token ends signed out', () async {
      final container = containerWith(FakeAuthRepository(restored: null));
      container.read(sessionProvider);

      await container.read(sessionProvider.notifier).restore();

      expect(container.read(sessionProvider), isA<SessionSignedOut>());
    });

    test('signOut flips state immediately and still calls the API', () async {
      final auth = FakeAuthRepository(restored: kTestUser);
      final container = containerWith(auth);
      container.read(sessionProvider);
      await container.read(sessionProvider.notifier).restore();

      final Future<void> pending =
          container.read(sessionProvider.notifier).signOut();

      // Flipped before the round trip completes.
      expect(container.read(sessionProvider), isA<SessionSignedOut>());
      await pending;
      expect(auth.logoutCalls, 1);
    });

    test('a 401 while signed in signs the user out with an explanation',
        () async {
      final container = containerWith(FakeAuthRepository(restored: kTestUser));
      container.read(sessionProvider);
      await container.read(sessionProvider.notifier).restore();
      expect(container.read(sessionProvider), isA<SessionSignedIn>());

      container.read(unauthorizedSignalProvider).fire();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(sessionProvider);
      expect(state, isA<SessionSignedOut>());
      expect(
        (state as SessionSignedOut).message,
        'Your session expired. Please sign in again.',
      );
    });

    test('a 401 while already signed out changes nothing', () async {
      final container = containerWith(FakeAuthRepository(restored: null));
      container.read(sessionProvider);
      await container.read(sessionProvider.notifier).restore();

      container.read(unauthorizedSignalProvider).fire();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(sessionProvider);
      expect(state, isA<SessionSignedOut>());
      // No "expired" banner: they were never signed in.
      expect((state as SessionSignedOut).message, isNull);
    });

    test('currentUserProvider mirrors the signed-in user', () async {
      final container = containerWith(FakeAuthRepository(restored: kTestUser));
      container.read(sessionProvider);

      expect(container.read(currentUserProvider), isNull);

      await container.read(sessionProvider.notifier).restore();

      expect(container.read(currentUserProvider)?.name, 'Aakanksha');
    });
  });

  group('SessionUser', () {
    test('parses what CrmPayload::user() returns', () {
      final user = SessionUser.fromJson(const {
        'id': 2,
        'name': 'Aakanksha',
        'username': 'aakanksha',
        'email': 'aakanksha@teghcables.com',
        'role': 'telecaller',
        'role_label': 'Payment Follow-up Executive',
        'initials': 'AK',
        'branch': 'Mumbai HQ',
        'region': 'mumbai',
        'region_label': 'Mumbai',
        'city': 'Bhiwandi',
        'scoped': true,
      });

      expect(user.isAdmin, isFalse);
      expect(user.scopeLabel, 'Mumbai, Bhiwandi');
    });

    test('an unscoped admin still gets a readable scope label', () {
      final user = SessionUser.fromJson(const {
        'id': 1,
        'name': 'Admin',
        'role': 'admin',
        'scoped': false,
      });

      expect(user.isAdmin, isTrue);
      expect(user.scopeLabel, 'All regions');
    });

    test('several cities are summarised, not listed', () {
      final user = SessionUser.fromJson(const {
        'id': 2,
        'name': 'Aakanksha',
        'region': 'mumbai',
        'region_label': 'Mumbai',
        'cities': ['Bhiwandi', 'Thane', 'Kalyan'],
      });

      // "Mumbai, Bhiwandi, Thane, Kalyan" does not fit the app bar.
      expect(user.cities, hasLength(3));
      expect(user.scopeLabel, 'Mumbai, 3 cities');
    });

    test('one city is named', () {
      final user = SessionUser.fromJson(const {
        'id': 2,
        'name': 'Aakanksha',
        'region_label': 'Mumbai',
        'cities': ['Bhiwandi'],
      });

      expect(user.scopeLabel, 'Mumbai, Bhiwandi');
    });

    test('an empty city list means the whole region', () {
      final user = SessionUser.fromJson(const {
        'id': 2,
        'name': 'Aakanksha',
        'region_label': 'Mumbai',
        'cities': <String>[],
      });

      // Empty is "all cities in Mumbai", never "no cities".
      expect(user.cities, isEmpty);
      expect(user.scopeLabel, 'Mumbai');
    });

    test('an older server sending only `city` still works', () {
      final user = SessionUser.fromJson(const {
        'id': 2,
        'name': 'Aakanksha',
        'region_label': 'Mumbai',
        'city': 'Bhiwandi',
      });

      expect(user.cities, ['Bhiwandi']);
      expect(user.scopeLabel, 'Mumbai, Bhiwandi');
    });

    test('a region with no city falls back to the region alone', () {
      final user = SessionUser.fromJson(const {
        'id': 3,
        'name': 'Amol',
        'region': 'pune',
        'region_label': 'Pune',
      });

      expect(user.scopeLabel, 'Pune');
    });
  });
}
