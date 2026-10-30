import 'package:flutter/foundation.dart';

/// What the Outstanding list is narrowed by.
///
/// Region and city are *not* here as a rule the app enforces -- the server
/// already scopes every row to the account's region and city. `city` exists
/// only so a telecaller covering a whole region can narrow within it.
@immutable
class OutstandingFilters {
  const OutstandingFilters({
    this.search = '',
    this.status,
    this.aging,
    this.city,
  });

  /// Matched against party name and invoice number by the server.
  final String search;

  /// One of `Invoice::STATUSES`.
  final String? status;

  /// One of `Invoice::AGING_BUCKETS`.
  final String? aging;

  final String? city;

  /// The server's own vocabulary, so a typo here fails loudly in tests rather
  /// than silently returning everything.
  static const List<String> statuses = [
    'Overdue',
    'Due Today',
    'Promise Given',
    'Paid',
    'Not Due',
  ];

  static const List<String> agingBuckets = [
    '0-7 Days',
    '8-15 Days',
    '16-30 Days',
    '31-60 Days',
    '61-90 Days',
    '90+ Days',
  ];

  /// Only the filters behind the funnel icon, so the screen can show a count
  /// badge. Search and the status chips are visible on their own.
  int get advancedCount => (aging == null ? 0 : 1) + (city == null ? 0 : 1);

  bool get isEmpty =>
      search.isEmpty && status == null && aging == null && city == null;

  /// Query parameters for `GET /outstanding`. Null entries are dropped by the
  /// API client, so an unset filter is never sent as an empty string.
  Map<String, String?> toQuery() => <String, String?>{
        // The server matches `party` and `invoice` separately; sending the
        // same text as both would AND them and return nothing. Party name is
        // what a telecaller searches by, so it wins.
        'party': search.isEmpty ? null : search,
        'status': status,
        'aging': aging,
        'city': city,
      };

  OutstandingFilters copyWith({
    String? search,
    String? Function()? status,
    String? Function()? aging,
    String? Function()? city,
  }) {
    return OutstandingFilters(
      search: search ?? this.search,
      status: status == null ? this.status : status(),
      aging: aging == null ? this.aging : aging(),
      city: city == null ? this.city : city(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OutstandingFilters &&
      other.search == search &&
      other.status == status &&
      other.aging == aging &&
      other.city == city;

  @override
  int get hashCode => Object.hash(search, status, aging, city);
}
