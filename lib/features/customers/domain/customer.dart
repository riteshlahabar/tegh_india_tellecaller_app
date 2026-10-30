import 'package:flutter/foundation.dart';

/// One party, as `CrmPayload::party()` returns it.
@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.outstanding,
    required this.outstandingInr,
    required this.invoiceCount,
    required this.status,
    this.code,
    this.contact,
    this.mobile,
    this.email,
    this.city,
    this.state,
    this.gstin,
    this.assigned,
    this.creditLimitInr,
    this.callInvoiceId,
    this.callInvoiceNo,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _int(json['id']),
      name: json['name'] as String? ?? 'Unknown party',
      outstanding: _double(json['outstanding']),
      outstandingInr: json['outstanding_inr'] as String? ?? '',
      invoiceCount: _int(json['invoice_count']),
      status: json['status'] as String? ?? 'Not Due',
      code: _text(json['code']),
      contact: _text(json['contact']),
      mobile: _text(json['mobile']),
      email: _text(json['email']),
      city: _text(json['city']),
      state: _text(json['state']),
      gstin: _text(json['gstin']),
      assigned: _text(json['assigned']),
      creditLimitInr: _text(json['credit_limit_inr']),
      // Which invoice a call from the directory should be logged against:
      // the server picks the oldest overdue one with a balance.
      callInvoiceId:
          json['call_invoice_id'] == null ? null : _int(json['call_invoice_id']),
      callInvoiceNo: _text(json['call_invoice_no']),
    );
  }

  final int id;
  final String name;
  final double outstanding;
  final String outstandingInr;
  final int invoiceCount;
  final String status;

  final String? code;
  final String? contact;
  final String? mobile;
  final String? email;
  final String? city;
  final String? state;
  final String? gstin;
  final String? assigned;
  final String? creditLimitInr;
  final int? callInvoiceId;
  final String? callInvoiceNo;

  bool get isCallable => (mobile ?? '').trim().isNotEmpty;

  /// Town and state, whichever the sync managed to read.
  String get place {
    final List<String> parts =
        <String?>[city, state].whereType<String>().toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }

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
