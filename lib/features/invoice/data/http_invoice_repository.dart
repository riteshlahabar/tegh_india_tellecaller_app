// Initializing formals would push the private field name into the public
// constructor, so callers would write `HttpInvoiceRepository(_client: ...)`.
// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/invoice_summary.dart';
import '../domain/invoice_repository.dart';

/// [InvoiceRepository] against the CRM's action endpoints.
///
/// Those endpoints answer `{ok: bool, message: string}` and use **422** for a
/// refusal that is not a validation error -- a dead WhatsApp gateway, for
/// one. The API client already turns 422 into `ValidationException`, whose
/// message is the server's own text, so a failure reaches the screen as
/// something worth showing a telecaller.
class HttpInvoiceRepository implements InvoiceRepository {
  const HttpInvoiceRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<InvoiceSummary> fetch(int invoiceId) async {
    final Map<String, dynamic> body = await _client.get('invoices/$invoiceId');
    final Object? invoice = body['invoice'];

    if (invoice is! Map<String, dynamic>) {
      throw const UnexpectedResponseException('That invoice could not be read.');
    }
    return InvoiceSummary.fromJson(invoice);
  }

  @override
  Future<String> logCall(CallLog log) async {
    final Map<String, dynamic> body =
        await _client.post('calls', body: log.toJson());

    return _message(body, fallback: 'Follow-up saved.');
  }

  @override
  Future<String> updateMobile({
    required int partyId,
    required String mobile,
  }) async {
    final Map<String, dynamic> body = await _client.post(
      'customers/$partyId/mobile',
      body: <String, dynamic>{'mobile': mobile},
    );

    // This endpoint answers the saved number rather than a message.
    return body['mobile'] as String? ?? mobile;
  }

  @override
  Future<String> whatsappPreview({
    required int invoiceId,
    required String template,
  }) async {
    final Map<String, dynamic> body = await _client.get(
      'invoices/$invoiceId/whatsapp-preview',
      query: <String, String?>{'template': template},
    );

    return body['message'] as String? ?? '';
  }

  @override
  Future<String> sendWhatsapp({
    required int invoiceId,
    required String template,
    required String message,
  }) async {
    final Map<String, dynamic> body = await _client.post(
      'whatsapp',
      body: <String, dynamic>{
        'invoice_id': invoiceId,
        'template': template,
        'message': message,
      },
    );

    return _message(body, fallback: 'WhatsApp sent.');
  }

  @override
  Future<String> sendEmail({
    required int invoiceId,
    required String toEmail,
    required String subject,
    required String body,
    String? cc,
  }) async {
    final Map<String, dynamic> response = await _client.post(
      'email',
      body: <String, dynamic>{
        'invoice_id': invoiceId,
        'to_email': toEmail,
        'subject': subject,
        'body': body,
        if (cc != null && cc.isNotEmpty) 'cc': cc,
      },
    );

    return _message(response, fallback: 'Email sent.');
  }

  /// These endpoints can answer 200 with `ok: false` as well as 422, so a
  /// success status alone is not proof the thing happened.
  String _message(Map<String, dynamic> body, {required String fallback}) {
    final String message = body['message'] as String? ?? fallback;

    if (body['ok'] == false) {
      throw ValidationException(message);
    }
    return message;
  }
}
