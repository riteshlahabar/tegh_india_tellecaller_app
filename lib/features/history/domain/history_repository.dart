import 'package:flutter/foundation.dart';

import '../../customers/domain/customer_detail.dart';

/// Which slice of the log to show.
enum CallRange {
  today('Today', 'today'),
  week('This week', 'week'),
  all('All', null);

  const CallRange(this.label, this.query);

  final String label;

  /// What `GET /calls` expects as `range`; null sends nothing.
  final String? query;
}

/// What the History tab is narrowed by.
@immutable
class HistoryFilters {
  const HistoryFilters({this.range = CallRange.today, this.outcome});

  final CallRange range;

  /// One of `Call::OUTCOMES`.
  final String? outcome;

  Map<String, String?> toQuery() => <String, String?>{
        'range': range.query,
        'outcome': outcome,
      };

  HistoryFilters copyWith({CallRange? range, String? Function()? outcome}) {
    return HistoryFilters(
      range: range ?? this.range,
      outcome: outcome == null ? this.outcome : outcome(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HistoryFilters && other.range == range && other.outcome == outcome;

  @override
  int get hashCode => Object.hash(range, outcome);
}

/// One page of `GET /calls`.
@immutable
class CallsPage {
  const CallsPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  factory CallsPage.fromJson(Map<String, dynamic> json) {
    final Object? data = json['data'];

    return CallsPage(
      items: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(CallRecord.fromJson)
              .toList()
          : const <CallRecord>[],
      page: _int(json['page'], fallback: 1),
      lastPage: _int(json['last_page'], fallback: 1),
      total: _int(json['total']),
    );
  }

  final List<CallRecord> items;
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

/// The History tab depends on this, never on an HTTP client.
abstract interface class HistoryRepository {
  Future<CallsPage> load({required HistoryFilters filters, int page = 1});
}
