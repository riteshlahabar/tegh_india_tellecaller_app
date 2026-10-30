import 'package:flutter/foundation.dart';

import '../../../shared/domain/invoice_summary.dart';

/// One page of `GET /outstanding`, as `CrmPayload::page()` shapes it plus the
/// two counts the endpoint adds.
@immutable
class OutstandingPage {
  const OutstandingPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
    required this.totalCount,
  });

  factory OutstandingPage.fromJson(Map<String, dynamic> json) {
    final Object? data = json['data'];

    return OutstandingPage(
      items: data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(InvoiceSummary.fromJson)
              .toList()
          : const <InvoiceSummary>[],
      page: _int(json['page'], fallback: 1),
      lastPage: _int(json['last_page'], fallback: 1),
      // `total` is how many matched the filters; `total_count` is the whole
      // book. Showing both is what tells a telecaller a filter is active.
      total: _int(json['total']),
      totalCount: _int(json['total_count']),
    );
  }

  final List<InvoiceSummary> items;
  final int page;
  final int lastPage;
  final int total;
  final int totalCount;

  bool get hasMore => page < lastPage;

  static int _int(Object? value, {int fallback = 0}) => switch (value) {
        num() => value.toInt(),
        String() => int.tryParse(value) ?? fallback,
        _ => fallback,
      };
}

/// Everything the Outstanding screen renders: the rows accumulated so far,
/// plus whether another page is being fetched.
@immutable
class OutstandingState {
  const OutstandingState({
    this.items = const <InvoiceSummary>[],
    this.page = 0,
    this.lastPage = 1,
    this.total = 0,
    this.totalCount = 0,
    this.loadingMore = false,
  });

  final List<InvoiceSummary> items;
  final int page;
  final int lastPage;
  final int total;
  final int totalCount;

  /// True while a *subsequent* page is in flight. The first page is the
  /// AsyncValue's own loading state, which is a different thing on screen:
  /// one is a spinner at the bottom, the other is an empty screen.
  final bool loadingMore;

  bool get hasMore => page < lastPage;

  /// True when the filters are hiding part of the book.
  bool get isFiltered => total != totalCount;

  OutstandingState appending(OutstandingPage next) {
    return OutstandingState(
      items: <InvoiceSummary>[...items, ...next.items],
      page: next.page,
      lastPage: next.lastPage,
      total: next.total,
      totalCount: next.totalCount,
      loadingMore: false,
    );
  }

  OutstandingState copyWith({bool? loadingMore}) {
    return OutstandingState(
      items: items,
      page: page,
      lastPage: lastPage,
      total: total,
      totalCount: totalCount,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}
