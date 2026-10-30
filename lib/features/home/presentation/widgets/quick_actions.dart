import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/custom_theme_colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../domain/home_summary.dart';

/// Demandium's `CategoryView`: a horizontally scrolling strip of square
/// tinted tiles with a label underneath. Here each tile is a slice of the
/// dial queue rather than a service category.
class QuickActions extends StatelessWidget {
  const QuickActions({
    required this.summary,
    required this.onSelect,
    super.key,
  });

  final HomeSummary summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        children: [
          _Tile(
            label: 'Overdue',
            count: summary.overdueCount,
            icon: Icons.error_outline_rounded,
            tone: AppPalette.overdue,
            onTap: () => onSelect('Overdue'),
          ),
          _Tile(
            label: 'Pending',
            count: summary.pendingCount,
            icon: Icons.pending_actions_rounded,
            tone: AppPalette.secondary,
            onTap: () => onSelect('Due Today'),
          ),
          _Tile(
            label: 'Promised',
            count: summary.promiseCount,
            icon: Icons.handshake_outlined,
            tone: AppPalette.primary,
            onTap: () => onSelect('Promise Given'),
          ),
          _Tile(
            label: 'Call next',
            icon: Icons.call_rounded,
            tone: AppPalette.paid,
            onTap: () => onSelect('next'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        end: Dimensions.paddingSizeSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                height: 58,
                width: 72,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Center(
                  child: count != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: Dimensions.iconSizeSmall, color: tone),
                            Text(
                              '$count',
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: tone,
                              ),
                            ),
                          ],
                        )
                      : Icon(icon, size: Dimensions.iconSizeDefault, color: tone),
                ),
              ),
              Gaps.vExtraSmall,
              Text(
                label,
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
      ),
    );
  }
}
