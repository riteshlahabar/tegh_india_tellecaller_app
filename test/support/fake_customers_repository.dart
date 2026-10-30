import 'package:telecaller_app/features/customers/domain/customer_detail.dart';
import 'package:telecaller_app/features/customers/domain/customers_repository.dart';

import 'fake_outstanding_repository.dart';

/// One party row, shaped as `CrmPayload::party()` returns it.
Map<String, dynamic> partyJson({
  int id = 7,
  String name = 'POLYCAB INDIA LTD RECEIVABLE A/C',
  String? code = 'ERP153',
  String? mobile = '9820012345',
  String? city = 'Bhiwandi',
  num outstanding = 482500,
  int invoiceCount = 3,
  String status = 'Overdue',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'code': code,
    'contact': 'Mr Shah',
    'mobile': mobile,
    'email': 'accounts@polycab.test',
    'gstin': '27AAACP1234A1Z5',
    'city': city,
    'state': 'Maharashtra',
    'outstanding': outstanding,
    'outstanding_inr': '₹4,82,500',
    'credit_limit_inr': '₹10,00,000',
    'invoice_count': invoiceCount,
    'status': status,
    'call_invoice_id': 1042,
    'call_invoice_no': 'TCIPL/1042',
  };
}

/// One logged call, as `CrmPayload::call()` returns it.
Map<String, dynamic> callJson({
  int id = 1,
  String outcome = 'Payment Promise',
  String? remarks = 'Will pay Friday',
}) {
  return <String, dynamic>{
    'id': id,
    'party': 'POLYCAB INDIA LTD RECEIVABLE A/C',
    'invoice_no': 'TCIPL/1042',
    'outcome': outcome,
    'remarks': remarks,
    'telecaller': 'Aakanksha',
    'called_at': '28 Oct 2026 11:42',
    'promise_amount_inr': '₹4,82,500',
    'promise_date': '2026-11-06',
  };
}

/// Scriptable [CustomersRepository] that records what it was asked for.
class FakeCustomersRepository implements CustomersRepository {
  FakeCustomersRepository({
    this.pages = const <int, List<Map<String, dynamic>>>{},
    this.lastPage = 1,
    this.total = 1,
    this.detailJson,
    this.error,
  });

  final Map<int, List<Map<String, dynamic>>> pages;
  final int lastPage;
  final int total;
  final Map<String, dynamic>? detailJson;
  final Object? error;

  final List<String> searches = <String>[];
  final List<int> requestedPages = <int>[];
  final List<int> detailsAsked = <int>[];

  @override
  Future<CustomersPage> load({String search = '', int page = 1}) async {
    searches.add(search);
    requestedPages.add(page);

    final Object? failure = error;
    if (failure != null) {
      throw failure;
    }

    return CustomersPage.fromJson(<String, dynamic>{
      'data': pages[page] ?? (page == 1 ? [partyJson()] : const []),
      'page': page,
      'last_page': lastPage,
      'total': total,
    });
  }

  @override
  Future<CustomerDetail> detail(int partyId) async {
    detailsAsked.add(partyId);

    final Object? failure = error;
    if (failure != null) {
      throw failure;
    }

    return CustomerDetail.fromJson(
      detailJson ??
          <String, dynamic>{
            'party': partyJson(),
            'invoices': [invoiceJson()],
            'calls': [callJson()],
          },
    );
  }
}
