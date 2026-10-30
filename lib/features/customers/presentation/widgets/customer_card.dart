import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/custom_theme_colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../domain/customer.dart';

/// One party in the directory.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    required this.customer,
    required this.onCall,
    required this.onTap,
    super.key,
  });

  final Customer customer;
  final VoidCallback onCall;
  final VoidCallback onTap;

  /// Initials, as the web CRM derives them, so a party with no logo still
  /// has something to recognise in a long list.
  String get _initials {
    final List<String> words = customer.name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '?';
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = customer.status.statusColor;

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
            child: Row(
              children: [
                Container(
                  height: Dimensions.imageSize,
                  width: Dimensions.imageSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSeven),
                  ),
                  child: Text(
                    _initials,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: tone,
                    ),
                  ),
                ),
                Gaps.hSmall,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      Gaps.vTine,
                      Text(
                        _subtitle,
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
                      customer.outstandingInr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    Gaps.vTine,
                    Text(
                      customer.status,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: tone,
                      ),
                    ),
                  ],
                ),
                Gaps.hExtraSmall,
                _CallButton(callable: customer.isCallable, onCall: onCall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ERP code, town and bill count — whichever of them the sync produced.
  String get _subtitle {
    final List<String> parts = <String>[
      if (customer.code != null) customer.code!,
      if (customer.place.isNotEmpty) customer.place,
      '${customer.invoiceCount} '
          '${customer.invoiceCount == 1 ? 'bill' : 'bills'}',
    ];

    return parts.join(' · ');
  }
}

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
