import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'custom_theme_colors.dart';
import 'dimensions.dart';
import 'styles.dart';

/// Demandium's two-ThemeData structure, kept as one parameterised builder so
/// the light and dark definitions cannot drift apart.
///
/// Deliberate deviation: `useMaterial3` stays true. Demandium is on Material
/// 2, but every surface this app draws is explicitly coloured here, so M3
/// changes nothing visible while keeping modern ripple and state-layer
/// behaviour.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme scheme = (isLight
            ? const ColorScheme.light(
                primary: AppPalette.primary,
                secondary: AppPalette.secondary,
                onSecondary: AppPalette.onSecondary,
                tertiary: AppPalette.tertiary,
                error: AppPalette.overdue,
                onPrimary: Color(0xFFF8FAFC),
              )
            : const ColorScheme.dark(
                primary: Color(0xFF8C9BE8),
                secondary: AppPalette.secondary,
                tertiary: AppPalette.tertiary,
                error: AppPalette.overdue,
              ))
        .copyWith(surface: isLight ? AppPalette.surface : null);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: AppPalette.primary,
      primaryColorLight: AppPalette.primaryLight,
      primaryColorDark: AppPalette.primaryDark,
      secondaryHeaderColor: AppPalette.secondaryHeader,
      disabledColor: AppPalette.disabled,
      hintColor: AppPalette.hint,
      shadowColor: AppPalette.shadow,
      scaffoldBackgroundColor: isLight ? Colors.white : scheme.surface,
      cardColor: isLight ? Colors.white : scheme.surfaceContainerLow,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[
        isLight
            ? const CustomThemeColors.light()
            : const CustomThemeColors.dark(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? Colors.white : scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? Colors.white : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeLarge,
            vertical: Dimensions.paddingSizeDefault,
          ),
          textStyle: robotoSemiBold,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppPalette.primary),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F1F4),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimensions.fontSizeOverLarge,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimensions.fontSizeExtraLarge,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimensions.fontSizeDefault,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimensions.fontSizeDefault,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: Dimensions.fontSizeSmall,
        ),
      ),
    );
  }
}
