import 'package:flutter/material.dart';

import '../../../../app/theme/custom_theme_colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/styles.dart';

/// Demandium's `HomeSearchWidget`: a pill with a hint on the left and a solid
/// circular primary button on the right, floating on a soft shadow.
class QueueSearchBar extends StatelessWidget {
  const QueueSearchBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Container(
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            border: Border.all(color: context.customThemeColors.searchBarBorder),
            boxShadow: isLight ? searchBoxShadow : null,
          ),
          child: Row(
            children: [
              Text(
                'Search party or invoice',
                style: robotoRegular.copyWith(color: theme.hintColor),
              ),
              const Spacer(),
              Container(
                height: 45,
                width: 45,
                margin: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: Dimensions.iconSizeDefault,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
