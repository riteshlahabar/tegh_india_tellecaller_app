/// Compile-time configuration. Nothing else in the app hardcodes a URL.
abstract final class AppConfig {
  static const String appName = 'Tegh Telecaller';

  /// The Laravel CRM's token API (`routes/api.php`).
  static const String apiBaseUrl = 'https://tpi.turnkeyinfotech.live/api';

  /// Regions are the three BUSY companies the CRM syncs. A telecaller is
  /// scoped to one of these at creation time.
  static const List<String> regions = ['Mumbai', 'Gujarat', 'Pune'];
}
