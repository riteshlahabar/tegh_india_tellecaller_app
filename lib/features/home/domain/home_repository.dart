import 'home_summary.dart';

/// The home screen depends on this interface, never on an HTTP client.
/// Swapping [SampleHomeRepository] for the live one is a one-line provider
/// override — no view or view-model changes.
abstract interface class HomeRepository {
  Future<HomeSummary> loadSummary();
}
