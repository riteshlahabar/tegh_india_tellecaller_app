import 'package:flutter/material.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../app_shell.dart';

/// Demandium's bottom bar: a solid primary-colour strip of plain `Expanded`
/// items -- no rounded corners, no indicator, white on white60 -- with a gap
/// in the middle for the docked circular action button.
///
/// It renders [ShellTab.values] with the gap inserted at the midpoint, so
/// adding a tab is still a one-line change to the enum.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Where the docked button's gap goes.
  static int get _gapAt => ShellTab.values.length ~/ 2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);

    return Container(
      // Demandium pads this by paddingSizeDefault top and bottom. Halved:
      // the bar was eating screen a dial queue needs for rows.
      padding: EdgeInsets.only(
        top: Dimensions.paddingSizeEight,
        bottom: padding.bottom > 15 ? 0 : Dimensions.paddingSizeEight,
      ),
      color: theme.primaryColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraSmall,
          ),
          child: Row(
            children: [
              for (int i = 0; i < ShellTab.values.length; i++) ...[
                if (i == _gapAt) const _DockGap(),
                _BnbItem(
                  tab: ShellTab.values[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty slot the floating action button sits over.
class _DockGap extends StatelessWidget {
  const _DockGap();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 20, height: 18),
          Gaps.vTine,
          Text(''),
        ],
      ),
    );
  }
}

class _BnbItem extends StatelessWidget {
  const _BnbItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tone = selected ? Colors.white : Colors.white60;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? tab.selectedIcon : tab.icon, size: 18, color: tone),
            Gaps.vTine,
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: tone,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
