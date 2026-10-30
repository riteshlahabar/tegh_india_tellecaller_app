import 'package:flutter/material.dart';

import '../../app/theme/dimensions.dart';
import '../../app/theme/gaps.dart';
import '../../app/theme/styles.dart';

/// Section heading with an optional trailing link, above every list block.
/// Demandium's `common/widgets/title_widget.dart`, minus the GetX
/// translation lookups.
class TitleWidget extends StatelessWidget {
  const TitleWidget({required this.title, this.onTap, this.actionLabel = 'See all', super.key});

  final String title;
  final VoidCallback? onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            ),
          ),
        ),
        Gaps.hSmall,
        if (onTap != null)
          InkWell(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
