// Initializing formals would push the private field name into the public
// constructor, so callers would write `HttpHistoryRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../domain/history_repository.dart';

/// [HistoryRepository] against `GET /calls`.
///
/// The server already limits a telecaller to their own calls, so nothing
/// identifying the user is sent.
class HttpHistoryRepository implements HistoryRepository {
  const HttpHistoryRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<CallsPage> load({
    required HistoryFilters filters,
    int page = 1,
  }) async {
    final Map<String, dynamic> body = await _client.get(
      'calls',
      query: <String, String?>{...filters.toQuery(), 'page': '$page'},
    );

    return CallsPage.fromJson(body);
  }
}
