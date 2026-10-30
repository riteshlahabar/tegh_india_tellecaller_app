import 'package:flutter/foundation.dart';

import '../../../shared/domain/invoice_summary.dart';

/// Outcomes the server accepts, from `Call::OUTCOMES`. Sending anything else
/// is a 422, so the list is mirrored here rather than typed free-form.
abstract final class CallOutcomes {
  static const List<String> all = [
    'Connected',
    'Not Connected',
    'Busy',
    'Call Later',
    'Wrong Number',
    'Payment Confirmed',
    'Payment Promise',
    'Dispute',
    'Cheque Given',
    'NEFT/RTGS Done',
  ];

  /// The one outcome that makes the server create a `PaymentPromise`, so the
  /// sheet reveals the amount and date fields for it.
  static const String promise = 'Payment Promise';
}

/// WhatsApp templates the server can render, from `WhatsappTemplates`.
abstract final class WhatsappTemplates {
  static const List<String> all = [
    'Payment Reminder',
    'Due Today',
    'Overdue Payment',
    'Payment Promise Reminder',
    'Statement Request',
    'Payment Confirmation',
    'Thank You for Payment',
  ];

  static const String defaultTemplate = 'Payment Reminder';
}

/// What a telecaller logs after a call.
@immutable
class CallLog {
  const CallLog({
    required this.invoiceId,
    required this.outcome,
    this.remarks,
    this.nextFollowupOn,
    this.promiseAmount,
    this.promiseDate,
  });

  final int invoiceId;
  final String outcome;
  final String? remarks;

  /// ISO yyyy-MM-dd. The server validates with `date`.
  final String? nextFollowupOn;
  final double? promiseAmount;
  final String? promiseDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'invoice_id': invoiceId,
        'outcome': outcome,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
        if (nextFollowupOn != null) 'next_followup_on': nextFollowupOn,
        if (promiseAmount != null) 'promise_amount': promiseAmount,
        if (promiseDate != null) 'promise_date': promiseDate,
      };
}

/// Everything the invoice detail screen can do.
abstract interface class InvoiceRepository {
  Future<InvoiceSummary> fetch(int invoiceId);

  /// `POST /calls`. Returns the server's confirmation message.
  Future<String> logCall(CallLog log);

  /// `POST /customers/{party}/mobile`. Returns the saved number.
  Future<String> updateMobile({required int partyId, required String mobile});

  /// `GET /invoices/{id}/whatsapp-preview` — the rendered template text, so
  /// the app never duplicates the wording the web CRM sends.
  Future<String> whatsappPreview({required int invoiceId, required String template});

  /// `POST /whatsapp`. Returns the server's confirmation message.
  Future<String> sendWhatsapp({
    required int invoiceId,
    required String template,
    required String message,
  });

  /// `POST /email`. Returns the server's confirmation message.
  Future<String> sendEmail({
    required int invoiceId,
    required String toEmail,
    required String subject,
    required String body,
    String? cc,
  });
}
