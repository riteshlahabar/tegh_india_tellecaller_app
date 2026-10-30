// Initializing formals would push the private field names into the public
// constructor, so callers would write `HttpHomeRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/session_user.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';
import 'dashboard_mapper.dart';

/// [HomeRepository] against `GET /dashboard`.
///
/// One request. The server already scopes every figure to this account's
/// region and city, so nothing is sent as a filter.
class HttpHomeRepository implements HomeRepository {
  const HttpHomeRepository({
    required ApiClient client,
    required SessionUser? user,
  })  : _client = client,
        _user = user;

  final ApiClient _client;

  /// Null only in the instant between signing out and the router leaving the
  /// signed-in area. Asking for a dashboard then is a bug, not a state.
  final SessionUser? _user;

  @override
  Future<HomeSummary> loadSummary() async {
    final SessionUser? user = _user;
    if (user == null) {
      throw const UnauthorizedException();
    }

    final Map<String, dynamic> body = await _client.get('dashboard');

    return DashboardMapper.toSummary(body, user: user);
  }
}
