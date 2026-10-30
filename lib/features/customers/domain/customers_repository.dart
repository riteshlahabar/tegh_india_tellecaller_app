import 'customer.dart';
import 'customer_detail.dart';

/// One page of the party directory.
class CustomersPage {
  const CustomersPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  factory CustomersPage.fromJson(Map<String, dynamic> json) {
    final Object? data = json['data'];

    return CustomersPage(
      items: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(Customer.fromJson)
              .toList()
          : const <Customer>[],
      page: _int(json['page'], fallback: 1),
      lastPage: _int(json['last_page'], fallback: 1),
      total: _int(json['total']),
    );
  }

  final List<Customer> items;
  final int page;
  final int lastPage;
  final int total;

  bool get hasMore => page < lastPage;

  static int _int(Object? value, {int fallback = 0}) => switch (value) {
        num() => value.toInt(),
        String() => int.tryParse(value) ?? fallback,
        _ => fallback,
      };
}

/// The Customers tab depends on this, never on an HTTP client.
abstract interface class CustomersRepository {
  /// `GET /customers`. [search] matches name, ERP code or mobile.
  Future<CustomersPage> load({String search = '', int page = 1});

  /// `GET /customers/{party}`.
  Future<CustomerDetail> detail(int partyId);
}
