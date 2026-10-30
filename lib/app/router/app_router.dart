import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_view_model.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoice/presentation/invoice_detail_screen.dart';
import '../../features/outstanding/presentation/outstanding_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../shared/widgets/coming_soon_screen.dart';

/// Route paths in one place so no widget writes a literal URL.
abstract final class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String outstanding = '/outstanding';
  static const String customers = '/customers';
  static const String history = '/history';

  /// Pushed over the shell, so the bottom bar is hidden while a single
  /// invoice is being worked.
  static const String invoice = '/invoice/:id';

  static String invoiceOf(int id) => '/invoice/$id';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// A single indexed-stack shell holds the four bottom-nav branches, so each
/// tab keeps its own scroll position and navigation stack.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  // The router is built once. Rebuilding it on every session change would
  // throw away each tab's navigation stack, so instead a listenable nudges
  // go_router to re-run `redirect` against the current state.
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    // The one place that decides what each session state may look at.
    // Exhaustive over the sealed SessionState, so a new state cannot slip
    // through without a decision being made here.
    redirect: (context, state) {
      final String here = state.matchedLocation;

      return switch (ref.read(sessionProvider)) {
        // Still restoring the stored token: hold on the splash.
        SessionChecking() => here == Routes.splash ? null : Routes.splash,

        // Signed out: only the login screen is reachable.
        SessionSignedOut() => here == Routes.login ? null : Routes.login,

        // Signed in: keep them out of the splash and login screens, but leave
        // any in-app route they were already heading to alone.
        SessionSignedIn() =>
          (here == Routes.splash || here == Routes.login) ? Routes.home : null,
      };
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.invoice,
        builder: (context, state) => InvoiceDetailScreen(
          // A non-numeric id cannot match a real invoice, so 0 lets the
          // screen's own error state explain it rather than crashing here.
          invoiceId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.outstanding,
                builder: (context, state) => const OutstandingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customers,
                builder: (context, state) => const ComingSoonScreen(
                  title: 'Customers',
                  subtitle: 'Party directory',
                  icon: Icons.business_rounded,
                  phase: 'Search by name or ERP code, then every invoice and '
                      'call for that account.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (context, state) => const ComingSoonScreen(
                  title: 'History',
                  subtitle: 'Your call log',
                  icon: Icons.history_rounded,
                  phase: 'Today, this week and all, filtered by outcome.',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
