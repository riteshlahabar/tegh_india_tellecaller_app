import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/custom_theme_colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../../../core/formatting/money.dart';
import '../../domain/home_summary.dart';

/// Demandium's vertical service list: separate white cards, each on the
/// shared `cardShadow`, rather than one block divided by hairlines.
class PriorityCallList extends StatelessWidget {
  const PriorityCallList({
    required this.calls,
    required this.onCall,
    required this.onTap,
    super.key,
  });

  final List<PriorityCall> calls;
  final ValueChanged<PriorityCall> onCall;
  final ValueChanged<PriorityCall> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      itemCount: calls.length,
      separatorBuilder: (_, _) => Gaps.vSmall,
      itemBuilder: (context, index) => _CallCard(
        call: calls[index],
        onCall: () => onCall(calls[index]),
        onTap: () => onTap(calls[index]),
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.call,
    required this.onCall,
    required this.onTap,
  });

  final PriorityCall call;
  final VoidCallback onCall;
  final VoidCallback onTap;

  IconData get _icon => switch (call.status) {
        'Overdue' => Icons.error_outline_rounded,
        'Due Today' => Icons.today_rounded,
        'Promise Given' => Icons.handshake_outlined,
        _ => Icons.receipt_long_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = call.status.statusColor;
    final bool isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: isLight ? cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Container(
                  height: Dimensions.imageSize,
                  width: Dimensions.imageSize,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSeven),
                  ),
                  child: Icon(_icon, size: Dimensions.iconSizeDefault, color: tone),
                ),
                Gaps.hSmall,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.party,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      Gaps.vTine,
                      Text(
                        '${call.invoiceNo} \u00b7 ${call.ageLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: context.customThemeColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                Gaps.hExtraSmall,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      inr(call.outstanding),
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    Gaps.vTine,
                    Text(
                      call.status,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: tone,
                      ),
                    ),
                  ],
                ),
                Gaps.hExtraSmall,
                _CallButton(callable: call.isCallable, onCall: onCall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one primary-coloured control on the card.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.callable, required this.onCall});

  final bool callable;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (!callable) {
      return Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.disabledColor.withValues(alpha: 0.4)),
        ),
        child: Icon(
          Icons.phone_disabled_rounded,
          size: Dimensions.iconSizeSmall - 2,
          color: theme.disabledColor,
        ),
      );
    }

    return SizedBox(
      height: 36,
      width: 36,
      child: Material(
        color: AppPalette.primaryLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onCall,
          child: Icon(
            Icons.call_rounded,
            size: Dimensions.iconSizeSmall - 1,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
