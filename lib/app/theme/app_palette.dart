import 'package:flutter/material.dart';

/// The only place raw brand colours are written down.
///
/// Values are Demandium customerapp's palette: indigo primary, orange
/// secondary, white page. Widgets read [ColorScheme] or
/// `Theme.of(context).extension<CustomThemeColors>()` where they can, and
/// reach in here only for the status tones.
abstract final class AppPalette {
  /// Client-chosen brand colour, 2026-10-30, replacing Demandium's indigo
  /// `#4153B3`. A straight swap: everything that was indigo is now this, and
  /// text on it stays white.
  ///
  /// White on this measures about 6.3:1 contrast, clearing the 4.5:1 wanted
  /// for body text -- so the white chrome the client asked for is legible
  /// here, which the two lighter tints tried before it were not.
  static const Color primary = Color(0xFF106B6E);
  static const Color primaryLight = Color(0xFFE4F1F1);
  static const Color primaryDark = Color(0xFF0A4A4C);

  static const Color secondary = Color(0xFFFF9900);
  static const Color onSecondary = Color(0xFFFFDA6D);
  static const Color tertiary = Color(0xFFD35221);

  static const Color secondaryHeader = Color(0xFF758493);
  static const Color hint = Color(0xFFA4A4A4);
  static const Color disabled = Color(0xFF8797AB);
  static const Color shadow = Color(0xFFE6E5E5);
  static const Color surface = Color(0xFFFCFCFC);

  /// Invoice status colours, mapped onto Demandium's semantic set:
  /// its error red, its secondary orange, its primary indigo and its
  /// success green.
  static const Color overdue = Color(0xFFF76767);
  static const Color dueToday = Color(0xFFFF9900);
  static const Color promise = Color(0xFF106B6E);
  static const Color paid = Color(0xFF02AA05);
  static const Color notDue = Color(0xFF758493);
}

/// Resolves an invoice status string from the API to its colour.
/// Kept as an extension so adding a status never means editing a widget.
extension InvoiceStatusColor on String {
  Color get statusColor => switch (this) {
        'Overdue' => AppPalette.overdue,
        'Due Today' => AppPalette.dueToday,
        'Promise Given' => AppPalette.promise,
        'Paid' => AppPalette.paid,
        _ => AppPalette.notDue,
      };
}
