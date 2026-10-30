import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/features/customers/domain/customer.dart';
import 'package:telecaller_app/features/customers/domain/customer_detail.dart';
import 'package:telecaller_app/features/customers/domain/customers_repository.dart';

import '../support/fake_auth.dart';
import '../support/fake_customers_repository.dart';
import '../support/fake_outstanding_repository.dart';

/// Opens the Customers tab in the real shell.
Future<void> openCustomers(
  WidgetTester tester,
  FakeCustomersRepository repo,
) async {
  await pumpApp(tester, customers: repo);
  await tester.tap(find.text('Customers'));
  await tester.pumpAndSettle();
}

void main() {
  group('directory', () {
    testWidgets('renders parties from the API', (tester) async {
      await openCustomers(tester, FakeCustomersRepository());

      expect(find.textContaining('POLYCAB'), findsOneWidget);
      expect(find.text('₹4,82,500'), findsOneWidget);
      // Code, town and bill count on one line.
      expect(
        find.text('ERP153 · Bhiwandi, Maharashtra · 3 bills'),
        findsOneWidget,
      );
    });

    testWidgets('a single bill is not pluralised', (tester) async {
      await openCustomers(
        tester,
        FakeCustomersRepository(
          pages: {
            1: [partyJson(invoiceCount: 1)],
          },
        ),
      );

      expect(
        find.text('ERP153 · Bhiwandi, Maharashtra · 1 bill'),
        findsOneWidget,
      );
    });

    testWidgets('search is debounced and sent once', (tester) async {
      final repo = FakeCustomersRepository();
      await openCustomers(tester, repo);
      final int before = repo.searches.length;

      await tester.enterText(find.byType(TextField), 'Poly');
      await tester.enterText(find.byType(TextField), 'Polycab');

      // A pending Timer schedules no frame, so the clock must be advanced.
      await tester.pump(const Duration(milliseconds: 200));
      expect(repo.searches.length, before);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(repo.searches.length, before + 1);
      expect(repo.searches.last, 'Polycab');
    });

    testWidgets('no match says so', (tester) async {
      final repo = FakeCustomersRepository(
        pages: const {1: <Map<String, dynamic>>[]},
        total: 0,
      );
      await openCustomers(tester, repo);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No match'), findsOneWidget);
    });

    testWidgets('an empty directory reads differently from no match',
        (tester) async {
      await openCustomers(
        tester,
        FakeCustomersRepository(
          pages: const {1: <Map<String, dynamic>>[]},
          total: 0,
        ),
      );

      expect(find.text('No customers'), findsOneWidget);
      expect(find.text('No match'), findsNothing);
    });

    testWidgets('a failure offers retry', (tester) async {
      await openCustomers(
        tester,
        FakeCustomersRepository(error: const NetworkException()),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('customer detail', () {
    testWidgets('opens from a directory row', (tester) async {
      final repo = FakeCustomersRepository();
      await openCustomers(tester, repo);

      await tester.tap(find.textContaining('POLYCAB').first);
      await tester.pumpAndSettle();

      expect(repo.detailsAsked, [7]);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Invoices (1)'), findsOneWidget);
    });

    testWidgets('shows the call history with its outcome', (tester) async {
      await openCustomers(tester, FakeCustomersRepository());
      await tester.tap(find.textContaining('POLYCAB').first);
      await tester.pumpAndSettle();

      // Call history sits below the invoices, off screen at test size.
      await tester.scrollUntilVisible(
        find.text('Call history (1)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Promise'), findsOneWidget);
      expect(find.text('Will pay Friday'), findsOneWidget);
    });

    testWidgets('an uncalled customer says so', (tester) async {
      await openCustomers(
        tester,
        FakeCustomersRepository(
          detailJson: {
            'party': partyJson(),
            'invoices': const <Map<String, dynamic>>[],
            'calls': const <Map<String, dynamic>>[],
          },
        ),
      );
      await tester.tap(find.textContaining('POLYCAB').first);
      await tester.pumpAndSettle();

      expect(find.text('Nobody has called this customer yet.'), findsOneWidget);
      expect(
        find.text('No invoices on file for this customer.'),
        findsOneWidget,
      );
    });
  });

  group('Customer', () {
    test('parses what CrmPayload::party() returns', () {
      final customer = Customer.fromJson(partyJson());

      expect(customer.id, 7);
      expect(customer.code, 'ERP153');
      expect(customer.place, 'Bhiwandi, Maharashtra');
      expect(customer.isCallable, isTrue);
      // Which invoice a call from the directory belongs against.
      expect(customer.callInvoiceId, 1042);
    });

    test('a party with no mobile is not callable', () {
      final customer = Customer.fromJson(partyJson(mobile: null));

      expect(customer.isCallable, isFalse);
    });

    test('place degrades when the sync read no address', () {
      final customer = Customer.fromJson(<String, dynamic>{
        ...partyJson(),
        'city': null,
        'state': null,
      });

      expect(customer.place, isEmpty);
    });

    test('a malformed row still renders', () {
      final customer = Customer.fromJson(const <String, dynamic>{});

      expect(customer.name, 'Unknown party');
      expect(customer.status, 'Not Due');
      expect(customer.outstanding, 0);
    });
  });

  group('CustomerDetail', () {
    test('splits open invoices from paid ones', () {
      final detail = CustomerDetail.fromJson(<String, dynamic>{
        'party': partyJson(),
        'invoices': [
          invoiceJson(),
          invoiceJson(id: 2, status: 'Paid', outstanding: 0),
        ],
        'calls': const <Map<String, dynamic>>[],
      });

      expect(detail.invoices, hasLength(2));
      expect(detail.openInvoices, hasLength(1));
    });

    test('a missing party does not take the screen down', () {
      final detail = CustomerDetail.fromJson(const <String, dynamic>{});

      expect(detail.customer.name, 'Unknown party');
      expect(detail.invoices, isEmpty);
      expect(detail.calls, isEmpty);
    });
  });

  group('CustomersPage', () {
    test('reports more pages to come', () {
      final page = CustomersPage.fromJson(<String, dynamic>{
        'data': [partyJson()],
        'page': 1,
        'last_page': 4,
        'total': 112,
      });

      expect(page.hasMore, isTrue);
      expect(page.total, 112);
    });

    test('a malformed body degrades to an empty page', () {
      final page = CustomersPage.fromJson(const <String, dynamic>{});

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
