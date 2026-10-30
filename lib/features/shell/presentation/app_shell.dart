import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_palette.dart';
import 'widgets/app_bottom_nav.dart';

/// Bottom-nav destinations. Adding a tab means adding one entry here and one
/// branch in the router -- no widget below needs editing.
enum ShellTab {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  outstanding(
    label: 'Outstanding',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  customers(
    label: 'Customers',
    icon: Icons.business_outlined,
    selectedIcon: Icons.business_rounded,
  ),
  history(
    label: 'History',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history_rounded,
  );

  const ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Holds Demandium's chrome around whichever branch is active: the filled
/// bottom bar plus the circular action docked into its centre. State per tab
/// survives switching, because the shell route is an indexed stack.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Phone-first layout. On a tablet, an iPad or a desktop web preview the
  /// content stays a single readable column instead of stretching across the
  /// whole screen.
  static const double _maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: shell,
        ),
      ),
      // Demandium docks a 70px circular cart button here. The telecaller
      // equivalent is the action the whole app exists for: the next call.
      floatingActionButton: MediaQuery.viewInsetsOf(context).bottom != 0
          ? null
          : const _CallNextButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      // Align with heightFactor 1 -- a Center here would take the whole
      // screen and leave the body no height at all.
      bottomNavigationBar: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: AppBottomNav(
            currentIndex: shell.currentIndex,
            onSelect: (index) => shell.goBranch(
              index,
              // Tapping the current tab returns it to its first screen.
              initialLocation: index == shell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}

/// The docked circular action, carrying Demandium's secondary-colour
/// gradient.
class _CallNextButton extends StatelessWidget {
  const _CallNextButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      customBorder: const CircleBorder(),
      child: Container(
        height: 70,
        width: 70,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.onSecondary, AppPalette.secondary],
          ),
        ),
        child: const Icon(Icons.call_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}
