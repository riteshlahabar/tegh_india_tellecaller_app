import 'package:flutter/foundation.dart';

/// One invoice row, as `CrmPayload::invoice()` returns it.
///
/// Lives in `shared/` because Outstanding, Customers and History all list the
/// same payload. Parsing is defensive for the same reason the dashboard
/// mapper is: the server is a separate deployable, and a list that renders a
/// blank field beats one that throws on a key that moved.
@immutable
class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.invoiceNo,
    required this.party,
    required this.outstanding,
    required this.outstandingInr,
    required this.status,
    required this.daysOverdue,
    required this.agingBucket,
    this.partyId,
    this.mobile,
    this.email,
    this.city,
    this.dueDateLabel,
    this.invoiceDateLabel,
    this.nextFollowupLabel,
    this.promiseAmount,
    this.promiseDate,
    this.assigned,
  });

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      id: _int(json['id']),
      invoiceNo: json['invoice_no'] as String? ?? '',
      party: json['party'] as String? ?? 'Unknown party',
      outstanding: _double(json['outstanding']),
      // The server formats rupees with its own inr() helper, so the app shows
      // the same string the web CRM does rather than re-deriving it.
      outstandingInr: json['outstanding_inr'] as String? ?? '',
      status: json['status'] as String? ?? 'Not Due',
      daysOverdue: _int(json['days_overdue']),
      agingBucket: json['aging_bucket'] as String? ?? '',
      partyId: json['party_id'] == null ? null : _int(json['party_id']),
      mobile: _text(json['mobile']),
      email: _text(json['email']),
      city: _text(json['city']),
      dueDateLabel: _text(json['due_date_label']),
      invoiceDateLabel: _text(json['invoice_date_label']),
      nextFollowupLabel: _text(json['next_followup_label']),
      promiseAmount:
          json['promise_amount'] == null ? null : _double(json['promise_amount']),
      promiseDate: _text(json['promise_date']),
      assigned: _text(json['assigned']),
    );
  }

  final int id;
  final String invoiceNo;
  final String party;
  final double outstanding;
  final String outstandingInr;
  final String status;
  final int daysOverdue;
  final String agingBucket;

  final int? partyId;
  final String? mobile;
  final String? email;
  final String? city;
  final String? dueDateLabel;
  final String? invoiceDateLabel;
  final String? nextFollowupLabel;
  final double? promiseAmount;
  final String? promiseDate;
  final String? assigned;

  bool get isCallable => (mobile ?? '').trim().isNotEmpty;

  /// What the row prints beside the invoice number.
  String get ageLabel => switch (daysOverdue) {
        < 0 => 'not due',
        0 => 'due today',
        1 => '1 day overdue',
        _ => '$daysOverdue days overdue',
      };

  static String? _text(Object? value) {
    if (value is! String) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

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
