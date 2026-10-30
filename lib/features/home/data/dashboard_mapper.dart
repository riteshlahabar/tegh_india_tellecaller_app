import '../../auth/domain/session_user.dart';
import '../domain/home_summary.dart';

/// Turns `GET /dashboard` into a [HomeSummary].
///
/// Kept out of the repository so the mapping can be tested against a literal
/// response body with no client, no network and no provider container. Every
/// field is read defensively: the server is a separate deployable, and a home
/// screen that crashes because one key moved is worse than one showing zero.
abstract final class DashboardMapper {
  /// [user] supplies the name and scope -- `/dashboard` returns neither,
  /// because the server already applied the scope to every figure in it.
  static HomeSummary toSummary(
    Map<String, dynamic> json, {
    required SessionUser user,
  }) {
    final Map<String, dynamic> kpis = _mapOf(json['kpis']);

    return HomeSummary(
      callerName: user.name,
      region: user.regionLabel ?? user.region ?? 'All regions',
      city: user.city ?? 'All cities',
      totalOutstanding: _double(kpis['total_outstanding']),
      overdueAmount: _double(kpis['overdue']),
      dueTodayAmount: _double(kpis['due_today']),
      promiseAmount: _double(kpis['ptp_amount']),
      pendingCount: _int(kpis['followups_today']),
      overdueCount: _int(kpis['overdue_count']),
      promiseCount: _int(kpis['ptp_count']),
      callsMade: _int(kpis['completed_followups']),
      // The queue is the day's target. A telecaller with nothing to call has
      // no target either, and callProgress already guards a zero divisor.
      callsTarget: _int(kpis['followups_today']),
      connected: _int(kpis['connected_today']),
      promisesTaken: _int(kpis['promises_today']),
      priorityCalls: _listOf(json['followups'])
          .map(DashboardMapper.toPriorityCall)
          .toList(),
    );
  }

  /// One row of `followups`, as `CrmPayload::invoice()` returns it plus the
  /// two call-history fields the dashboard endpoint adds.
  static PriorityCall toPriorityCall(Map<String, dynamic> json) {
    return PriorityCall(
      invoiceId: _int(json['id']),
      party: json['party'] as String? ?? 'Unknown party',
      invoiceNo: json['invoice_no'] as String? ?? '',
      outstanding: _double(json['outstanding']),
      mobile: json['mobile'] as String?,
      status: json['status'] as String? ?? 'Not Due',
      daysOverdue: _int(json['days_overdue']),
      region: json['city'] as String? ?? '',
      callCount: _int(json['call_count']),
      lastOutcome: json['last_outcome'] as String?,
    );
  }

  static Map<String, dynamic> _mapOf(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static List<Map<String, dynamic>> _listOf(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value.whereType<Map<String, dynamic>>().toList();
  }

  /// The API sends money as a JSON number, but a column that is NULL or a
  /// string-typed decimal both turn up in practice.
  static double _double(Object? value) => switch (value) {
        num() => value.toDouble(),
        String() => double.tryParse(value) ?? 0,
        _ => 0,
      };

  static int _int(Object? value) => switch (value) {
        num() => value.toInt(),
        String() => int.tryParse(value) ?? 0,
        _ => 0,
      };
}
