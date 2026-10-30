import 'outstanding_filters.dart';
import 'outstanding_page.dart';

/// The Outstanding screen depends on this, never on an HTTP client.
abstract interface class OutstandingRepository {
  /// One page of `GET /outstanding`. [page] is 1-based, matching Laravel.
  Future<OutstandingPage> load({
    required OutstandingFilters filters,
    int page = 1,
  });
}
