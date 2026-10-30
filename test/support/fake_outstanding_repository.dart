import 'package:telecaller_app/features/outstanding/domain/outstanding_filters.dart';
import 'package:telecaller_app/features/outstanding/domain/outstanding_page.dart';
import 'package:telecaller_app/features/outstanding/domain/outstanding_repository.dart';

/// One invoice row shaped exactly as `CrmPayload::invoice()` returns it.
Map<String, dynamic> invoiceJson({
  int id = 1042,
  String party = 'POLYCAB INDIA LTD RECEIVABLE A/C',
  String invoiceNo = 'TCIPL/1042',
  String status = 'Overdue',
  int daysOverdue = 47,
  String? mobile = '9820012345',
  String? city = 'Bhiwandi',
  num outstanding = 482500,
}) {
  return <String, dynamic>{
    'id': id,
    'invoice_no': invoiceNo,
    'party': party,
    'party_id': 7,
    'mobile': mobile,
    'city': city,
    'outstanding': outstanding,
    'outstanding_inr': '₹4,82,500',
    'status': status,
    'days_overdue': daysOverdue,
    'aging_bucket': '90+ Days',
    'due_date_label': '12 Sep 2026',
  };
}

/// Scriptable [OutstandingRepository] that records what it was asked for.
class FakeOutstandingRepository implements OutstandingRepository {
  FakeOutstandingRepository({
    this.pages = const <int, List<Map<String, dynamic>>>{},
    this.lastPage = 1,
    this.total = 1,
    this.totalCount = 1,
    this.error,
  });

  /// Page number to the rows it returns. Page 1 defaults to a single row.
  final Map<int, List<Map<String, dynamic>>> pages;
  final int lastPage;
  final int total;
  final int totalCount;

  /// When set, every call throws this instead.
  final Object? error;

  /// Every filter set this was called with, in order.
  final List<OutstandingFilters> calls = <OutstandingFilters>[];
  final List<int> requestedPages = <int>[];

  @override
  Future<OutstandingPage> load({
    required OutstandingFilters filters,
    int page = 1,
  }) async {
    calls.add(filters);
    requestedPages.add(page);

    final Object? failure = error;
    if (failure != null) {
      throw failure;
    }

    return OutstandingPage.fromJson(<String, dynamic>{
      'data': pages[page] ?? (page == 1 ? [invoiceJson()] : const []),
      'page': page,
      'last_page': lastPage,
      'total': total,
      'total_count': totalCount,
    });
  }
}
