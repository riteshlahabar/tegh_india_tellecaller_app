import 'package:flutter/material.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';

/// Demandium's `AddressAppBar`, re-pointed at what a telecaller is scoped to.
/// Where that app shows the delivery address under a pin, this shows the
/// region and city the account is assigned to -- same filled primary bar,
/// same white-on-indigo treatment.
class ScopeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScopeAppBar({
    required this.callerName,
    required this.region,
    required this.city,
    required this.notificationCount,
    required this.onSignOut,
    super.key,
  });

  final String callerName;
  final String region;
  final String city;
  final int notificationCount;
  final VoidCallback onSignOut;

  @override
  Size get preferredSize => const Size.fromHeight(Dimensions.customAppbarSize);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.primaryColor,
      elevation: 0,
      toolbarHeight: Dimensions.customAppbarSize,
      leadingWidth: 0,
      leading: const SizedBox(),
      shape: Border(
        bottom: BorderSide(
          width: 0.4,
          color: theme.primaryColorLight.withValues(alpha: 0.2),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            callerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoSemiBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
          Gaps.vTine,
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: Dimensions.paddingSizeDefault,
              ),
              Gaps.hTine,
              Flexible(
                child: Text(
                  '$region, $city',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Badge(
          isLabelVisible: notificationCount > 0,
          label: Text('$notificationCount'),
          backgroundColor: theme.colorScheme.secondary,
          child: const Icon(
            Icons.notifications,
            size: 25,
            color: Colors.white,
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: onSignOut,
          icon: const Icon(
            Icons.logout_rounded,
            size: Dimensions.iconSizeDefault,
            color: Colors.white,
          ),
        ),
        Gaps.hExtraSmall,
      ],
    );
  }
}
