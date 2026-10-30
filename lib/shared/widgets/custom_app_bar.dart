import 'package:flutter/material.dart';

import '../../app/theme/dimensions.dart';
import '../../app/theme/styles.dart';

/// Demandium's `common/widgets/custom_app_bar.dart`: a filled primary-colour
/// bar with a centred title in `primaryColorLight`, a hairline bottom border
/// and no elevation.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.title,
    this.subTitle,
    this.isBackButtonExist = true,
    this.centerTitle = true,
    this.onBack,
    this.actions,
    super.key,
  });

  final String title;
  final String? subTitle;
  final bool isBackButtonExist;
  final bool centerTitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.primaryColor,
      centerTitle: centerTitle,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(
          width: 0.4,
          color: theme.primaryColorLight.withValues(alpha: 0.2),
        ),
      ),
      leading: isBackButtonExist
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: theme.primaryColorLight,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : const SizedBox(),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: theme.primaryColorLight,
            ),
          ),
          if (subTitle != null)
            Text(
              subTitle!,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.primaryColorLight,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}
