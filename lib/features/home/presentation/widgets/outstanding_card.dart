import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../../../core/formatting/money.dart';
import '../../domain/home_summary.dart';

/// Demandium's home banner slot, carrying the figure a telecaller opens the
/// app for instead of a promotion.
class OutstandingCard extends StatelessWidget {
  const OutstandingCard({required this.summary, super.key});

  final HomeSummary summary;

  double get _collectable => summary.overdueAmount + summary.dueTodayAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Not : white text needs the deeper end of the hue.
            colors: [AppPalette.primary, AppPalette.primaryDark],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your outstanding',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Gaps.vExtraSmall,
            Text(
              inrCompact(summary.totalOutstanding),
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeOverLarge + 4,
                color: Colors.white,
              ),
            ),
            Gaps.vTine,
            Text(
              '${inrCompact(_collectable)} due or overdue today',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            Gaps.vDefault,
            _ProgressStrip(summary: summary),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Today's calling",
              style: robotoSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '${summary.callsMade} / ${summary.callsTarget}',
              style: robotoSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Gaps.vEight,
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: LinearProgressIndicator(
            value: summary.callProgress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppPalette.secondary,
            ),
          ),
        ),
        Gaps.vEight,
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${summary.connected} connected \u00b7 '
            '${summary.promisesTaken} promised',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}
