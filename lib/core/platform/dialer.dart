import 'package:url_launcher/url_launcher.dart';

/// Hands a number to the phone's own dialer.
///
/// `tel:` deliberately, not a direct call: placing one needs `CALL_PHONE`,
/// which is a Play Store review burden for no gain. The dialer opens
/// pre-filled and the telecaller presses the green button.
abstract final class Dialer {
  /// True if the dialer opened. False means no handler -- an emulator or a
  /// tablet with no telephony.
  static Future<bool> call(String number) {
    return _open('tel', number);
  }

  static Future<bool> _open(String scheme, String number) async {
    final String cleaned = sanitise(number);
    if (cleaned.isEmpty) {
      return false;
    }

    return launchUrl(
      Uri(scheme: scheme, path: cleaned),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Strips everything a dialer cannot use. BUSY stores numbers with spaces,
  /// dashes and the occasional stray bracket, and a `tel:` with those in it
  /// silently fails to resolve on some Android builds.
  static String sanitise(String number) {
    final String kept = number.replaceAll(RegExp(r'[^0-9+]'), '');

    // A '+' is only meaningful as the first character.
    if (!kept.startsWith('+')) {
      return kept.replaceAll('+', '');
    }
    return '+${kept.substring(1).replaceAll('+', '')}';
  }
}
