/// Compile-time configuration. Nothing else in the app hardcodes a URL.
abstract final class AppConfig {
  static const String appName = 'Tegh Telecaller';

  /// The Laravel CRM's token API (`routes/api.php`).
  ///
  /// Overridable at build time so a device can be pointed at a local Laravel
  /// without editing source:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tpi.turnkeyinfotech.live/api',
  );

  /// Per-request ceiling. The CRM's outstanding page joins across three
  /// companies, so this is deliberately generous.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Regions are the three BUSY companies the CRM syncs. A telecaller is
  /// scoped to one of these at creation time, and the API returns the
  /// account's own region on `/me`, so this list is only for display.
  static const List<String> regions = ['Mumbai', 'Gujarat', 'Pune'];
}
