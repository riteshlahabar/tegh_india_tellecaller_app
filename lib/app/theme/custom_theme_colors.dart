import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Colours that are not part of [ColorScheme] but still need to flip with the
/// theme. Demandium does the same thing with its `CustomThemeColors`
/// extension; this is the typed, generated-free version of it.
@immutable
class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  const CustomThemeColors({
    required this.searchBarBorder,
    required this.cardBorder,
    required this.subtitle,
    required this.tileTint,
  });

  const CustomThemeColors.light()
      : searchBarBorder = const Color(0xFFEDEDED),
        cardBorder = const Color(0xFFF1F1F4),
        subtitle = AppPalette.secondaryHeader,
        tileTint = AppPalette.primaryLight;

  const CustomThemeColors.dark()
      : searchBarBorder = const Color(0xFF2A2F45),
        cardBorder = const Color(0xFF2A2F45),
        subtitle = const Color(0xFF9AA6B8),
        tileTint = const Color(0xFF232845);

  final Color searchBarBorder;
  final Color cardBorder;
  final Color subtitle;
  final Color tileTint;

  @override
  CustomThemeColors copyWith({
    Color? searchBarBorder,
    Color? cardBorder,
    Color? subtitle,
    Color? tileTint,
  }) {
    return CustomThemeColors(
      searchBarBorder: searchBarBorder ?? this.searchBarBorder,
      cardBorder: cardBorder ?? this.cardBorder,
      subtitle: subtitle ?? this.subtitle,
      tileTint: tileTint ?? this.tileTint,
    );
  }

  @override
  CustomThemeColors lerp(CustomThemeColors? other, double t) {
    if (other == null) {
      return this;
    }
    return CustomThemeColors(
      searchBarBorder:
          Color.lerp(searchBarBorder, other.searchBarBorder, t) ?? searchBarBorder,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      subtitle: Color.lerp(subtitle, other.subtitle, t) ?? subtitle,
      tileTint: Color.lerp(tileTint, other.tileTint, t) ?? tileTint,
    );
  }
}

/// `context.customThemeColors.subtitle`, exactly as Demandium reads it.
extension CustomThemeColorsContext on BuildContext {
  CustomThemeColors get customThemeColors =>
      Theme.of(this).extension<CustomThemeColors>()!;
}
