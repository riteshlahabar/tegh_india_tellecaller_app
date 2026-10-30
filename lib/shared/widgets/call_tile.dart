import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/custom_theme_colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/gaps.dart';
import '../../app/theme/styles.dart';
import '../../features/customers/domain/customer_detail.dart';

/// One logged call. Shared by the customer detail screen and the History tab.
///
/// [showParty] is the only difference between the two: on a customer's own
/// page the party is already the heading, while the History tab lists calls
/// across customers and needs the name on every row.
class CallTile extends StatelessWidget {
  const CallTile({
    required this.call,
    this.showParty = false,
    this.onTap,
    super.key,
  });

  final CallRecord call;
  final bool showParty;
  final VoidCallback? onTap;

  /// Outcomes grouped by what they mean for collection, so a glance down the
  /// list separates progress from dead ends.
  Color get _tone => switch (call.outcome) {
        'Connected' || 'Payment Confirmed' || 'NEFT/RTGS Done' => AppPalette.paid,
        'Payment Promise' || 'Cheque Given' => AppPalette.promise,
        'Dispute' || 'Wrong Number' => AppPalette.overdue,
        _ => AppPalette.notDue,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = context.customThemeColors.subtitle;

    final String meta = <String>[
      if (call.invoiceNo != null) call.invoiceNo!,
      if (call.telecaller != null) 'by ${call.telecaller}',
      if (call.promiseAmountInr != null)
        'PTP ${call.promiseAmountInr}'
            '${call.promiseDate == null ? '' : ' on ${call.promiseDate}'}',
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: theme.brightness == Brightness.light ? cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeEight,
                        vertical: Dimensions.paddingSizeTine,
                      ),
                      decoration: BoxDecoration(
                        color: _tone.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: Text(
                        call.outcome,
                        style: robotoSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: _tone,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (call.calledAt != null)
                      Text(
                        call.calledAt!,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: muted,
                        ),
                      ),
                  ],
                ),
                if (showParty && call.party != null) ...[
                  Gaps.vEight,
                  Text(
                    call.party!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
                if (call.remarks != null) ...[
                  Gaps.vTine,
                  Text(
                    call.remarks!,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  Gaps.vTine,
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
