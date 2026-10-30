import 'package:flutter/foundation.dart';

/// One row of the priority dial queue. Mirrors the fields
/// `CrmPayload::invoice()` already returns, plus the call-history counters
/// Phase 1 adds to it.
@immutable
class PriorityCall {
  const PriorityCall({
    required this.invoiceId,
    required this.party,
    required this.invoiceNo,
    required this.outstanding,
    required this.mobile,
    required this.status,
    required this.daysOverdue,
    required this.region,
    required this.callCount,
    this.lastOutcome,
  });

  final int invoiceId;
  final String party;
  final String invoiceNo;
  final double outstanding;
  final String? mobile;
  final String status;
  final int daysOverdue;
  final String region;
  final int callCount;
  final String? lastOutcome;

  bool get isCallable => mobile != null && mobile!.trim().isNotEmpty;

  /// What the tile prints under the invoice number.
  String get ageLabel => switch (daysOverdue) {
        < 0 => 'not due',
        0 => 'due today',
        1 => '1 day overdue',
        _ => '$daysOverdue days overdue',
      };

  String get historyLabel => switch (callCount) {
        0 => 'Never called',
        1 => '1 call · ${lastOutcome ?? '—'}',
        _ => '$callCount calls · ${lastOutcome ?? '—'}',
      };
}

/// Everything the home screen renders, in one object, so the view never
/// assembles data itself.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.callerName,
    required this.region,
    required this.city,
    required this.totalOutstanding,
    required this.overdueAmount,
    required this.dueTodayAmount,
    required this.promiseAmount,
    required this.pendingCount,
    required this.overdueCount,
    required this.promiseCount,
    required this.callsMade,
    required this.callsTarget,
    required this.connected,
    required this.promisesTaken,
    required this.priorityCalls,
  });

  final String callerName;
  final String region;
  final String city;

  final double totalOutstanding;
  final double overdueAmount;
  final double dueTodayAmount;
  final double promiseAmount;

  final int pendingCount;
  final int overdueCount;
  final int promiseCount;

  final int callsMade;
  final int callsTarget;
  final int connected;
  final int promisesTaken;

  final List<PriorityCall> priorityCalls;

  double get callProgress =>
      callsTarget == 0 ? 0 : (callsMade / callsTarget).clamp(0, 1);
}
