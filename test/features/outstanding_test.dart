import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/features/outstanding/domain/outstanding_filters.dart';
import 'package:telecaller_app/features/outstanding/domain/outstanding_page.dart';

import '../support/fake_auth.dart';
import '../support/fake_outstanding_repository.dart';

/// Opens the Outstanding tab in the real shell.
Future<void> openOutstanding(
  WidgetTester tester,
  FakeOutstandingRepository repo,
) async {
  await pumpApp(tester, outstanding: repo);
  await tester.tap(find.text('Outstanding'));
  await tester.pumpAndSettle();
}

void main() {
  group('list', () {
    testWidgets('renders rows from the API', (tester) async {
      await openOutstanding(tester, FakeOutstandingRepository());

      expect(find.textContaining('POLYCAB'), findsOneWidget);
      expect(find.text('TCIPL/1042 · 47 days overdue'), findsOneWidget);
      expect(find.text('₹4,82,500'), findsOneWidget);
    });

    testWidgets('shows a count footer', (tester) async {
      await openOutstanding(
        tester,
        FakeOutstandingRepository(total: 1, totalCount: 1),
      );

      expect(find.text('1 of 1'), findsOneWidget);
    });

    testWidgets('says how many the filters hid', (tester) async {
      await openOutstanding(
        tester,
        FakeOutstandingRepository(total: 12, totalCount: 1916),
      );

      expect(
        find.text('1 of 12 shown · 1916 in all'),
        findsOneWidget,
      );
    });

    testWidgets('an empty book explains itself', (tester) async {
      await openOutstanding(
        tester,
        FakeOutstandingRepository(
          pages: const {1: <Map<String, dynamic>>[]},
          total: 0,
          totalCount: 0,
        ),
      );

      expect(find.text('Nothing outstanding'), findsOneWidget);
      // No filters are set, so no "clear" button.
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('a failure offers retry rather than a blank list',
        (tester) async {
      await openOutstanding(
        tester,
        FakeOutstandingRepository(error: const NetworkException()),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(
        find.text('No connection. Check your internet and try again.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('tapping a status chip sends it to the server',
        (tester) async {
      final repo = FakeOutstandingRepository();
      await openOutstanding(tester, repo);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.status, 'Overdue');
      expect(repo.calls.last.toQuery()['status'], 'Overdue');
    });

    testWidgets('tapping the active chip again clears it', (tester) async {
      final repo = FakeOutstandingRepository();
      await openOutstanding(tester, repo);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.status, isNull);
    });

    testWidgets('search is debounced into a single request', (tester) async {
      final repo = FakeOutstandingRepository();
      await openOutstanding(tester, repo);
      final int before = repo.calls.length;

      await tester.enterText(find.byType(TextField), 'Poly');
      await tester.enterText(find.byType(TextField), 'Polyc');
      await tester.enterText(find.byType(TextField), 'Polycab');

      // Inside the 350ms window, nothing has been asked for yet. The clock
      // has to be advanced explicitly: a pending Timer schedules no frame, so
      // pumpAndSettle alone would return without ever firing it.
      await tester.pump(const Duration(milliseconds: 200));
      expect(repo.calls.length, before);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Three keystrokes, one request -- that is the whole point of the
      // debounce. Without it the results also arrive out of order.
      expect(repo.calls.length, before + 1);
      expect(repo.calls.last.search, 'Polycab');
    });

    testWidgets('no matches offers a way out', (tester) async {
      final repo = FakeOutstandingRepository(
        pages: const {1: <Map<String, dynamic>>[]},
        total: 0,
        totalCount: 1916,
      );
      await openOutstanding(tester, repo);

      // 'Overdue' is the first chip, so it is on screen at phone width --
      // later chips scroll off and cannot be tapped without scrolling first.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.isEmpty, isTrue);
    });
  });

  group('OutstandingFilters', () {
    test('an unset filter is never sent', () {
      const filters = OutstandingFilters();

      expect(filters.toQuery(), {
        'party': null,
        'status': null,
        'aging': null,
        'city': null,
      });
      expect(filters.isEmpty, isTrue);
    });

    test('search goes to the party parameter, not both', () {
      const filters = OutstandingFilters(search: 'Polycab');

      // Sending it as `invoice` too would AND the two and match nothing.
      expect(filters.toQuery()['party'], 'Polycab');
      expect(filters.toQuery().containsKey('invoice'), isFalse);
    });

    test('advancedCount counts only what is behind the funnel', () {
      const filters = OutstandingFilters(
        status: 'Overdue',
        aging: '90+ Days',
        city: 'Bhiwandi',
      );

      // Status is a visible chip, so it does not earn a badge.
      expect(filters.advancedCount, 2);
    });

    test('copyWith can clear a filter, not just set it', () {
      const filters = OutstandingFilters(status: 'Overdue');

      expect(filters.copyWith(status: () => null).status, isNull);
      // Omitting the argument leaves it alone.
      expect(filters.copyWith(search: 'x').status, 'Overdue');
    });
  });

  group('OutstandingPage', () {
    test('parses what CrmPayload::page() returns', () {
      final page = OutstandingPage.fromJson(<String, dynamic>{
        'data': [invoiceJson()],
        'page': 2,
        'last_page': 5,
        'total': 240,
        'total_count': 1916,
      });

      expect(page.items.single.party, startsWith('POLYCAB'));
      expect(page.hasMore, isTrue);
      expect(page.total, 240);
      expect(page.totalCount, 1916);
    });

    test('the final page reports no more', () {
      final page = OutstandingPage.fromJson(<String, dynamic>{
        'data': const <Map<String, dynamic>>[],
        'page': 5,
        'last_page': 5,
      });

      expect(page.hasMore, isFalse);
    });

    test('a malformed body degrades to an empty page', () {
      final page = OutstandingPage.fromJson(const <String, dynamic>{});

      expect(page.items, isEmpty);
      expect(page.page, 1);
      expect(page.hasMore, isFalse);
    });

    test('appending accumulates rows across pages', () {
      const state = OutstandingState();

      final first = state.appending(
        OutstandingPage.fromJson(<String, dynamic>{
          'data': [invoiceJson()],
          'page': 1,
          'last_page': 2,
          'total': 2,
          'total_count': 2,
        }),
      );
      final second = first.appending(
        OutstandingPage.fromJson(<String, dynamic>{
          'data': [invoiceJson(id: 2, party: 'TATA POWER LTD')],
          'page': 2,
          'last_page': 2,
          'total': 2,
          'total_count': 2,
        }),
      );

      expect(second.items, hasLength(2));
      expect(second.hasMore, isFalse);
      expect(second.isFiltered, isFalse);
    });
  });
}
