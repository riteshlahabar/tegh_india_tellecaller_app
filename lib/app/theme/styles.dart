import 'package:flutter/material.dart';

import 'dimensions.dart';

/// Named Roboto weights, Demandium's `util/styles.dart`.
///
/// The family here is 'Roboto' and `pubspec.yaml` declares the family as
/// 'Roboto' too. Demandium declares the same TTFs under the family name
/// 'Ubuntu' while every style asks for 'Roboto', so its bundled font never
/// actually loads -- that mismatch is not reproduced here.
const TextStyle robotoLight = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w300,
  fontSize: Dimensions.fontSizeSmall,
  height: 1.5,
);

const TextStyle robotoRegular = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

const TextStyle robotoMedium = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault,
);

const TextStyle robotoSemiBold = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w600,
  fontSize: Dimensions.fontSizeDefault,
);

const TextStyle robotoBold = TextStyle(
  fontFamily: 'Roboto',
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

/// Soft shadow under the search pill.
final List<BoxShadow> searchBoxShadow = [
  BoxShadow(
    offset: const Offset(0, 4),
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 14,
  ),
];

/// The shadow every white card sits on. Demandium's `cardShadow`.
const List<BoxShadow> cardShadow = [
  BoxShadow(
    offset: Offset(0, 2),
    spreadRadius: 2,
    blurRadius: 2,
    color: Color(0x20A8A8EA),
  ),
];
