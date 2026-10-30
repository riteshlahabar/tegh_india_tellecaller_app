// Initializing formals would push the private field name into the public
// constructor, so callers would write `HttpCustomersRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../domain/customer_detail.dart';
import '../domain/customers_repository.dart';

/// [CustomersRepository] against the CRM's customer endpoints.
class HttpCustomersRepository implements CustomersRepository {
  const HttpCustomersRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<CustomersPage> load({String search = '', int page = 1}) async {
    final Map<String, dynamic> body = await _client.get(
      'customers',
      query: <String, String?>{
        // The server reads the search term as `q`, not `search`.
        'q': search.isEmpty ? null : search,
        'page': '$page',
      },
    );

    return CustomersPage.fromJson(body);
  }

  @override
  Future<CustomerDetail> detail(int partyId) async {
    final Map<String, dynamic> body = await _client.get('customers/$partyId');

    return CustomerDetail.fromJson(body);
  }
}
