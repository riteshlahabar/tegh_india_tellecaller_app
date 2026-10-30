// Initializing formals would push the private field name into the public
// constructor, so callers would write `HttpOutstandingRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../domain/outstanding_filters.dart';
import '../domain/outstanding_page.dart';
import '../domain/outstanding_repository.dart';

/// [OutstandingRepository] against `GET /outstanding`.
class HttpOutstandingRepository implements OutstandingRepository {
  const HttpOutstandingRepository({required ApiClient client})
      : _client = client;

  final ApiClient _client;

  @override
  Future<OutstandingPage> load({
    required OutstandingFilters filters,
    int page = 1,
  }) async {
    final Map<String, dynamic> body = await _client.get(
      'outstanding',
      query: <String, String?>{
        ...filters.toQuery(),
        // Laravel's paginator reads `page`; sending 1 explicitly keeps the
        // first request identical in shape to every later one.
        'page': '$page',
      },
    );

    return OutstandingPage.fromJson(body);
  }
}
