/// Spacing, radius and font-size tokens.
///
/// Lifted from Demandium's `util/dimensions.dart`, with one deliberate change:
/// every value here is a real `const`. Demandium declares its font sizes as
/// static fields that read `Get.context!.width`, so the scale is frozen at
/// whatever the window measured on first access and never updates on resize.
/// Responsive sizing belongs in a widget that can rebuild, not in a static
/// initialiser -- see [Dimensions.fontScaleFor].
abstract final class Dimensions {
  // Font sizes -- phone values. Call [fontScaleFor] for the desktop step.
  static const double fontSizeExtraSmall = 10;
  static const double fontSizeSmall = 12;
  static const double fontSizeDefault = 14;
  static const double fontSizeLarge = 16;
  static const double fontSizeExtraLarge = 18;
  static const double fontSizeOverLarge = 24;

  /// Demandium's desktop step (>= 1300px), expressed as a function of the
  /// width it is given so it re-evaluates on every rebuild.
  static double fontScaleFor(double width) => width >= 1300 ? 1.15 : 1;

  static const double paddingSizeMini = 2;
  static const double paddingSizeTine = 3;
  static const double paddingSizeExtraSmall = 5;
  static const double paddingSizeEight = 8;
  static const double paddingSizeSmall = 10;
  static const double paddingSizeDefault = 15;
  static const double paddingSizeLarge = 20;
  static const double paddingSizeExtraLarge = 25;
  static const double paddingSizeExtraMoreLarge = 40;
  static const double pagesBottomPadding = 100;

  static const double radiusSmall = 5;
  static const double radiusSeven = 7;
  static const double radiusDefault = 10;
  static const double radiusLarge = 15;
  static const double radiusExtraLarge = 20;
  static const double radiusExtraMoreLarge = 50;

  static const double customAppbarSize = 70;
  static const double iconSizeSmall = 18;
  static const double iconSizeDefault = 22;
  static const double imageSize = 50;
  static const double webMaxWidth = 480;
}
