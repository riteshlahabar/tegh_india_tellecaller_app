import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/custom_theme_colors.dart';
import '../../app/theme/dimensions.dart';
import '../../app/theme/gaps.dart';
import '../../app/theme/styles.dart';
import '../domain/invoice_summary.dart';

/// One invoice, as a white card on the shared `cardShadow`.
///
/// In `shared/` because Outstanding, Customers and History all show the same
/// row. The call button is the only brand-coloured control on it.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    required this.invoice,
    required this.onCall,
    required this.onTap,
    super.key,
  });

  final InvoiceSummary invoice;
  final VoidCallback onCall;
  final VoidCallback onTap;

  IconData get _icon => switch (invoice.status) {
        'Overdue' => Icons.error_outline_rounded,
        'Due Today' => Icons.today_rounded,
        'Promise Given' => Icons.handshake_outlined,
        'Paid' => Icons.check_circle_outline_rounded,
        _ => Icons.receipt_long_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = invoice.status.statusColor;
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: Dimensions.imageSize,
                      width: Dimensions.imageSize,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSeven),
                      ),
                      child: Icon(
                        _icon,
                        size: Dimensions.iconSizeDefault,
                        color: tone,
                      ),
                    ),
                    Gaps.hSmall,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.party,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          Gaps.vTine,
                          Text(
                            '${invoice.invoiceNo} · ${invoice.ageLabel}',
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
                          invoice.outstandingInr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        Gaps.vTine,
                        Text(
                          invoice.status,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: tone,
                          ),
                        ),
                      ],
                    ),
                    Gaps.hExtraSmall,
                    _CallButton(callable: invoice.isCallable, onCall: onCall),
                  ],
                ),
                if (invoice.city != null || invoice.dueDateLabel != null) ...[
                  Gaps.vEight,
                  _MetaRow(invoice: invoice),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The second line: where the customer is and when the bill was due.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.invoice});

  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.customThemeColors.subtitle;
    final TextStyle style = robotoRegular.copyWith(
      fontSize: Dimensions.fontSizeExtraSmall,
      color: muted,
    );

    return Row(
      children: [
        if (invoice.city != null) ...[
          Icon(Icons.place_outlined, size: 13, color: muted),
          Gaps.hTine,
          Flexible(
            child: Text(
              invoice.city!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Gaps.hSmall,
        ],
        if (invoice.dueDateLabel != null) ...[
          Icon(Icons.event_outlined, size: 13, color: muted),
          Gaps.hTine,
          Text('Due ${invoice.dueDateLabel}', style: style),
        ],
        const Spacer(),
        if (invoice.promiseAmount != null && invoice.promiseDate != null)
          Text(
            'PTP ${invoice.promiseDate}',
            style: style.copyWith(color: AppPalette.promise),
          ),
      ],
    );
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
