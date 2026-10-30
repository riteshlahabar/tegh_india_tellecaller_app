import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/features/customers/domain/customer_detail.dart';
import 'package:telecaller_app/features/history/domain/history_repository.dart';

import '../support/fake_auth.dart';
import '../support/fake_history_repository.dart';

/// Opens the History tab in the real shell.
Future<void> openHistory(
  WidgetTester tester,
  FakeHistoryRepository repo,
) async {
  await pumpApp(tester, history: repo);
  await tester.tap(find.text('History'));
  await tester.pumpAndSettle();
}

void main() {
  group('log', () {
    testWidgets('renders calls from the API', (tester) async {
      await openHistory(tester, FakeHistoryRepository());

      expect(find.text('Payment Promise'), findsWidgets);
      expect(find.textContaining('POLYCAB'), findsOneWidget);
      expect(find.text('Will pay Friday'), findsOneWidget);
      expect(find.text('30 Oct 2026 11:42'), findsOneWidget);
    });

    testWidgets('opens today by default', (tester) async {
      final repo = FakeHistoryRepository();
      await openHistory(tester, repo);

      // A telecaller opens History to see what they have done today.
      expect(repo.calls.single.range, CallRange.today);
      expect(repo.calls.single.toQuery()['range'], 'today');
    });

    testWidgets('a count footer shows how many were loaded', (tester) async {
      await openHistory(tester, FakeHistoryRepository(total: 12));

      expect(find.text('1 of 12 calls'), findsOneWidget);
    });

    testWidgets('an empty log explains itself', (tester) async {
      await openHistory(
        tester,
        FakeHistoryRepository(
          pages: const {1: <Map<String, dynamic>>[]},
          total: 0,
        ),
      );

      expect(find.text('No calls yet'), findsOneWidget);
      expect(find.text('Clear outcome'), findsNothing);
    });

    testWidgets('a failure offers retry', (tester) async {
      await openHistory(
        tester,
        FakeHistoryRepository(error: const NetworkException()),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('switching range reloads with it', (tester) async {
      final repo = FakeHistoryRepository();
      await openHistory(tester, repo);

      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.range, CallRange.week);
      expect(repo.calls.last.toQuery()['range'], 'week');
    });

    testWidgets('All sends no range at all', (tester) async {
      final repo = FakeHistoryRepository();
      await openHistory(tester, repo);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Null is dropped by the API client, so no date filter is applied.
      expect(repo.calls.last.range, CallRange.all);
      expect(repo.calls.last.toQuery()['range'], isNull);
    });

    testWidgets('an outcome chip narrows the log', (tester) async {
      final repo = FakeHistoryRepository();
      await openHistory(tester, repo);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Connected'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.outcome, 'Connected');
    });

    testWidgets('tapping the active outcome clears it', (tester) async {
      final repo = FakeHistoryRepository();
      await openHistory(tester, repo);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Connected'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Connected'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.outcome, isNull);
    });

    testWidgets('no match offers a way back', (tester) async {
      final repo = FakeHistoryRepository(
        pages: const {1: <Map<String, dynamic>>[]},
        total: 0,
      );
      await openHistory(tester, repo);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Connected'));
      await tester.pumpAndSettle();

      expect(find.text('No matching calls'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear outcome'));
      await tester.pumpAndSettle();

      expect(repo.calls.last.outcome, isNull);
    });
  });

  group('HistoryFilters', () {
    test('today and week send a range, all sends none', () {
      expect(
        const HistoryFilters().toQuery()['range'],
        'today',
      );
      expect(
        const HistoryFilters(range: CallRange.week).toQuery()['range'],
        'week',
      );
      expect(
        const HistoryFilters(range: CallRange.all).toQuery()['range'],
        isNull,
      );
    });

    test('copyWith can clear the outcome, not just set it', () {
      const filters = HistoryFilters(outcome: 'Connected');

      expect(filters.copyWith(outcome: () => null).outcome, isNull);
      // Omitting the argument leaves it alone.
      expect(filters.copyWith(range: CallRange.all).outcome, 'Connected');
    });
  });

  group('CallsPage', () {
    test('parses what CrmPayload::page() returns', () {
      final page = CallsPage.fromJson(<String, dynamic>{
        'data': [historyCallJson()],
        'page': 1,
        'last_page': 3,
        'total': 140,
      });

      expect(page.items.single.outcome, 'Payment Promise');
      expect(page.items.single.invoiceId, 1042);
      expect(page.hasMore, isTrue);
    });

    test('a call with no invoice still parses', () {
      // Calls can be logged against a customer rather than one bill.
      final record = CallRecord.fromJson(historyCallJson(invoiceId: null));

      expect(record.invoiceId, isNull);
      expect(record.outcome, 'Payment Promise');
    });

    test('a malformed body degrades to an empty page', () {
      final page = CallsPage.fromJson(const <String, dynamic>{});

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });
}
