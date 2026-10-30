import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_client.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/core/platform/dialer.dart';
import 'package:telecaller_app/features/invoice/data/http_invoice_repository.dart';
import 'package:telecaller_app/features/invoice/domain/invoice_repository.dart';

import '../support/fake_outstanding_repository.dart';

/// Records what was asked for and replies with canned bodies per path.
class _StubClient implements ApiClient {
  _StubClient(this._bodies);

  final Map<String, Map<String, dynamic>> _bodies;

  final List<String> gets = <String>[];
  final List<(String, Map<String, dynamic>)> posts =
      <(String, Map<String, dynamic>)>[];
  Map<String, String?> lastQuery = const {};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    gets.add(path);
    lastQuery = query;
    return _bodies[path] ?? const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    posts.add((path, body));
    return _bodies[path] ?? const <String, dynamic>{};
  }
}

void main() {
  group('Dialer.sanitise', () {
    test('strips the spacing BUSY stores numbers with', () {
      // A tel: with spaces or dashes in it silently fails to resolve on some
      // Android builds, so this is not cosmetic.
      expect(Dialer.sanitise('98200 12345'), '9820012345');
      expect(Dialer.sanitise('98200-12345'), '9820012345');
      expect(Dialer.sanitise('(022) 2847 1234'), '02228471234');
    });

    test('keeps a leading country code', () {
      expect(Dialer.sanitise('+91 98200 12345'), '+919820012345');
    });

    test('drops a plus that is not leading', () {
      expect(Dialer.sanitise('98200+12345'), '9820012345');
      expect(Dialer.sanitise('+91+9820012345'), '+919820012345');
    });

    test('an unusable number comes back empty', () {
      expect(Dialer.sanitise('n/a'), isEmpty);
      expect(Dialer.sanitise(''), isEmpty);
    });
  });

  group('CallLog', () {
    test('sends only what was filled in', () {
      const log = CallLog(invoiceId: 1042, outcome: 'Connected');

      expect(log.toJson(), {'invoice_id': 1042, 'outcome': 'Connected'});
    });

    test('carries the promise fields when there is a promise', () {
      const log = CallLog(
        invoiceId: 1042,
        outcome: CallOutcomes.promise,
        remarks: 'Will pay Friday',
        promiseAmount: 482500,
        promiseDate: '2026-11-06',
        nextFollowupOn: '2026-11-07',
      );

      expect(log.toJson(), {
        'invoice_id': 1042,
        'outcome': 'Payment Promise',
        'remarks': 'Will pay Friday',
        'next_followup_on': '2026-11-07',
        'promise_amount': 482500,
        'promise_date': '2026-11-06',
      });
    });

    test('empty remarks are omitted rather than sent blank', () {
      const log = CallLog(invoiceId: 1, outcome: 'Busy', remarks: '');

      // The server substitutes "(No remarks entered)" itself.
      expect(log.toJson().containsKey('remarks'), isFalse);
    });
  });

  group('HttpInvoiceRepository', () {
    test('fetch reads the invoice envelope', () async {
      final client = _StubClient({
        'invoices/1042': {'invoice': invoiceJson()},
      });
      final repo = HttpInvoiceRepository(client: client);

      final invoice = await repo.fetch(1042);

      expect(client.gets, ['invoices/1042']);
      expect(invoice.party, startsWith('POLYCAB'));
      expect(invoice.outstandingInr, '₹4,82,500');
    });

    test('a missing envelope is reported, not silently empty', () async {
      final repo = HttpInvoiceRepository(client: _StubClient(const {}));

      await expectLater(
        repo.fetch(1042),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });

    test('logCall posts to /calls and returns the server message', () async {
      final client = _StubClient({
        'calls': {'ok': true, 'message': 'Follow-up saved for POLYCAB.'},
      });
      final repo = HttpInvoiceRepository(client: client);

      final message = await repo.logCall(
        const CallLog(invoiceId: 1042, outcome: 'Connected'),
      );

      expect(client.posts.single.$1, 'calls');
      expect(client.posts.single.$2['invoice_id'], 1042);
      expect(message, 'Follow-up saved for POLYCAB.');
    });

    test('a 200 carrying ok:false is still a failure', () async {
      // The WhatsApp gateway answers this way when it is not configured, so
      // trusting the status code alone would report a send that never went.
      final client = _StubClient({
        'whatsapp': {'ok': false, 'message': 'WhatsApp is not connected.'},
      });
      final repo = HttpInvoiceRepository(client: client);

      await expectLater(
        repo.sendWhatsapp(invoiceId: 1, template: 'x', message: 'y'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'WhatsApp is not connected.',
          ),
        ),
      );
    });

    test('updateMobile returns the number the server saved', () async {
      final client = _StubClient({
        'customers/7/mobile': {'ok': true, 'mobile': '9820012345'},
      });
      final repo = HttpInvoiceRepository(client: client);

      final saved = await repo.updateMobile(partyId: 7, mobile: '98200 12345');

      expect(client.posts.single.$1, 'customers/7/mobile');
      // The server normalises; the app shows what it stored, not what was typed.
      expect(saved, '9820012345');
    });

    test('whatsappPreview asks the server for the wording', () async {
      final client = _StubClient({
        'invoices/1042/whatsapp-preview': {'message': 'Dear POLYCAB, ...'},
      });
      final repo = HttpInvoiceRepository(client: client);

      final text = await repo.whatsappPreview(
        invoiceId: 1042,
        template: 'Overdue Payment',
      );

      // Templates live on the server; a second copy in Dart would drift.
      expect(client.gets, ['invoices/1042/whatsapp-preview']);
      expect(client.lastQuery['template'], 'Overdue Payment');
      expect(text, 'Dear POLYCAB, ...');
    });

    test('sendEmail omits an empty cc', () async {
      final client = _StubClient({
        'email': {'ok': true, 'message': 'Email sent.'},
      });
      final repo = HttpInvoiceRepository(client: client);

      await repo.sendEmail(
        invoiceId: 1,
        toEmail: 'a@b.com',
        subject: 's',
        body: 'b',
        cc: '',
      );

      expect(client.posts.single.$2.containsKey('cc'), isFalse);
    });
  });

  group('vocabularies match the server', () {
    test('every outcome the sheet offers is one Call::OUTCOMES accepts', () {
      // A typo here is a 422 at the moment a telecaller tries to save.
      expect(CallOutcomes.all, hasLength(10));
      expect(CallOutcomes.all, contains(CallOutcomes.promise));
      expect(CallOutcomes.all.first, 'Connected');
    });

    test('the default WhatsApp template is one the server renders', () {
      expect(
        WhatsappTemplates.all,
        contains(WhatsappTemplates.defaultTemplate),
      );
      expect(WhatsappTemplates.all, hasLength(7));
    });
  });
}
