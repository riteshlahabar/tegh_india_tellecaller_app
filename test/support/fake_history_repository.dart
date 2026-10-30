import 'package:telecaller_app/features/history/domain/history_repository.dart';

/// Scriptable [HistoryRepository] that records what it was asked for.
class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository({
    this.pages = const <int, List<Map<String, dynamic>>>{},
    this.lastPage = 1,
    this.total = 1,
    this.error,
  });

  final Map<int, List<Map<String, dynamic>>> pages;
  final int lastPage;
  final int total;
  final Object? error;

  final List<HistoryFilters> calls = <HistoryFilters>[];
  final List<int> requestedPages = <int>[];

  @override
  Future<CallsPage> load({
    required HistoryFilters filters,
    int page = 1,
  }) async {
    calls.add(filters);
    requestedPages.add(page);

    final Object? failure = error;
    if (failure != null) {
      throw failure;
    }

    return CallsPage.fromJson(<String, dynamic>{
      'data': pages[page] ?? (page == 1 ? [historyCallJson()] : const []),
      'page': page,
      'last_page': lastPage,
      'total': total,
    });
  }
}

/// One call row, as `CrmPayload::call()` returns it.
Map<String, dynamic> historyCallJson({
  int id = 1,
  String outcome = 'Payment Promise',
  String? remarks = 'Will pay Friday',
  int? invoiceId = 1042,
}) {
  return <String, dynamic>{
    'id': id,
    'party': 'POLYCAB INDIA LTD RECEIVABLE A/C',
    'invoice_id': invoiceId,
    'invoice_no': 'TCIPL/1042',
    'outcome': outcome,
    'remarks': remarks,
    'telecaller': 'Aakanksha',
    'called_at': '30 Oct 2026 11:42',
    'promise_amount_inr': '₹4,82,500',
    'promise_date': '2026-11-06',
  };
}
