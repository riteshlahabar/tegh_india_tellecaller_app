import 'package:flutter/foundation.dart';

import '../../../shared/domain/invoice_summary.dart';
import 'customer.dart';

/// One logged call, as `CrmPayload::call()` returns it.
@immutable
class CallRecord {
  const CallRecord({
    required this.id,
    required this.outcome,
    this.party,
    this.invoiceId,
    this.invoiceNo,
    this.remarks,
    this.telecaller,
    this.calledAt,
    this.promiseAmountInr,
    this.promiseDate,
    this.nextFollowupOn,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: _int(json['id']),
      outcome: json['outcome'] as String? ?? '',
      party: _text(json['party']),
      invoiceId: json['invoice_id'] == null ? null : _int(json['invoice_id']),
      invoiceNo: _text(json['invoice_no']),
      remarks: _text(json['remarks']),
      telecaller: _text(json['telecaller']),
      calledAt: _text(json['called_at']),
      promiseAmountInr: _text(json['promise_amount_inr']),
      promiseDate: _text(json['promise_date']),
      nextFollowupOn: _text(json['next_followup_on']),
    );
  }

  final int id;
  final String outcome;
  final String? party;

  /// Null for a call logged against a customer rather than one invoice.
  final int? invoiceId;
  final String? invoiceNo;
  final String? remarks;
  final String? telecaller;

  /// Already formatted by the server as `d M Y H:i`.
  final String? calledAt;
  final String? promiseAmountInr;
  final String? promiseDate;
  final String? nextFollowupOn;

  static String? _text(Object? value) {
    if (value is! String) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _int(Object? value) => switch (value) {
        num() => value.toInt(),
        String() => int.tryParse(value) ?? 0,
        _ => 0,
      };
}

/// `GET /customers/{party}` — the party, its invoices and its call history.
@immutable
class CustomerDetail {
  const CustomerDetail({
    required this.customer,
    required this.invoices,
    required this.calls,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    final Object? party = json['party'];

    return CustomerDetail(
      customer: party is Map<String, dynamic>
          ? Customer.fromJson(party)
          : const Customer(
              id: 0,
              name: 'Unknown party',
              outstanding: 0,
              outstandingInr: '',
              invoiceCount: 0,
              status: 'Not Due',
            ),
      invoices: _listOf(json['invoices']).map(InvoiceSummary.fromJson).toList(),
      calls: _listOf(json['calls']).map(CallRecord.fromJson).toList(),
    );
  }

  final Customer customer;
  final List<InvoiceSummary> invoices;
  final List<CallRecord> calls;

  /// Only the invoices still worth a call.
  List<InvoiceSummary> get openInvoices =>
      invoices.where((invoice) => invoice.outstanding > 0).toList();

  static List<Map<String, dynamic>> _listOf(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value.whereType<Map<String, dynamic>>().toList();
  }
}
