import 'package:flutter/widgets.dart';

import 'dimensions.dart';

/// Spacing widgets, so a layout never writes a raw `SizedBox(height: 15)`.
/// Demandium's `util/gaps.dart`, same idea and same scale.
abstract final class Gaps {
  static const Widget vTine = SizedBox(height: Dimensions.paddingSizeTine);
  static const Widget vExtraSmall =
      SizedBox(height: Dimensions.paddingSizeExtraSmall);
  static const Widget vEight = SizedBox(height: Dimensions.paddingSizeEight);
  static const Widget vSmall = SizedBox(height: Dimensions.paddingSizeSmall);
  static const Widget vDefault = SizedBox(height: Dimensions.paddingSizeDefault);
  static const Widget vLarge = SizedBox(height: Dimensions.paddingSizeLarge);
  static const Widget vExtraLarge =
      SizedBox(height: Dimensions.paddingSizeExtraLarge);

  static const Widget hTine = SizedBox(width: Dimensions.paddingSizeTine);
  static const Widget hExtraSmall =
      SizedBox(width: Dimensions.paddingSizeExtraSmall);
  static const Widget hEight = SizedBox(width: Dimensions.paddingSizeEight);
  static const Widget hSmall = SizedBox(width: Dimensions.paddingSizeSmall);
  static const Widget hDefault = SizedBox(width: Dimensions.paddingSizeDefault);
  static const Widget hLarge = SizedBox(width: Dimensions.paddingSizeLarge);
}
