import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../shared/widgets/coming_soon_screen.dart';

/// Route paths in one place so no widget writes a literal URL.
abstract final class Routes {
  static const String home = '/home';
  static const String outstanding = '/outstanding';
  static const String customers = '/customers';
  static const String history = '/history';
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// A single indexed-stack shell holds the four bottom-nav branches, so each
/// tab keeps its own scroll position and navigation stack.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    routes: [
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
                builder: (context, state) => const ComingSoonScreen(
                  title: 'Outstanding',
                  subtitle: 'Pending, Overdue, Promise Given and All',
                  icon: Icons.receipt_long_rounded,
                  phase: 'The full invoice list with region, city, status and '
                      'aging filters lands next, on GET /api/outstanding.',
                ),
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
