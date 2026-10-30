import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../core/config/app_config.dart';

/// What [SessionChecking] looks like.
///
/// It starts nothing and decides nothing: the session view-model is already
/// restoring by the time this builds, and the router moves on when that
/// finishes. A splash that kicked off its own work would race it.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            Gaps.vLarge,
            Text(
              AppConfig.appName,
              style: robotoBold.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeOverLarge,
              ),
            ),
            Gaps.vExtraSmall,
            Text(
              'Outstanding, on your phone',
              style: robotoRegular.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
            Gaps.vExtraLarge,
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
