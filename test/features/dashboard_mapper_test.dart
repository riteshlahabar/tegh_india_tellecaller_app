import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/core/network/api_client.dart';
import 'package:telecaller_app/core/network/api_exception.dart';
import 'package:telecaller_app/features/home/data/dashboard_mapper.dart';
import 'package:telecaller_app/features/home/data/http_home_repository.dart';

import '../support/fake_auth.dart';

/// Records the path asked for and replies with a canned body.
class _StubClient implements ApiClient {
  _StubClient(this._body, {this.error});

  final Map<String, dynamic> _body;
  final ApiException? error;

  String? askedFor;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    askedFor = path;
    final ApiException? failure = error;
    if (failure != null) {
      throw failure;
    }
    return _body;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const {},
  }) async =>
      throw UnimplementedError();
}

/// A trimmed but faithful `GET /dashboard` body, keyed exactly as
/// `CrmApiController::dashboard()` writes it.
Map<String, dynamic> dashboardBody({
  Map<String, dynamic> kpis = const {},
  List<Map<String, dynamic>> followups = const [],
}) {
  return <String, dynamic>{
    'kpis': <String, dynamic>{
      'total_outstanding': 19248500,
      'total_outstanding_inr': '₹1,92,48,500',
      'open_invoices': 1916,
      'overdue': 11420300,
      'overdue_count': 31,
      'due_today': 842000,
      'due_today_count': 7,
      'ptp_amount': 1965000,
      'ptp_count': 4,
      'collected_this_month': 500000,
      'followups_today': 25,
      'completed_followups': 9,
      'connected_today': 6,
      'promises_today': 2,
      ...kpis,
    },
    'aging': const <Map<String, dynamic>>[],
    'followups': followups,
    'team': const <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> followupRow({Map<String, dynamic> overrides = const {}}) {
  return <String, dynamic>{
    'id': 1042,
    'invoice_no': 'TCIPL/1042',
    'party': 'POLYCAB INDIA LTD RECEIVABLE A/C',
    'mobile': '9820012345',
    'outstanding': 482500,
    'status': 'Overdue',
    'days_overdue': 47,
    'city': 'Bhiwandi',
    'call_count': 2,
    'last_outcome': 'Call Later',
    ...overrides,
  };
}

void main() {
  group('KPIs', () {
    test('maps every figure the home screen renders', () {
      final summary =
          DashboardMapper.toSummary(dashboardBody(), user: kTestUser);

      expect(summary.totalOutstanding, 19248500);
      expect(summary.overdueAmount, 11420300);
      expect(summary.dueTodayAmount, 842000);
      expect(summary.promiseAmount, 1965000);
      expect(summary.overdueCount, 31);
      expect(summary.promiseCount, 4);
      expect(summary.pendingCount, 25);
      expect(summary.callsMade, 9);
      expect(summary.callsTarget, 25);
      expect(summary.connected, 6);
      expect(summary.promisesTaken, 2);
    });

    test('name and scope come from the session, not the dashboard', () {
      final summary =
          DashboardMapper.toSummary(dashboardBody(), user: kTestUser);

      expect(summary.callerName, 'Aakanksha');
      expect(summary.region, 'Mumbai');
      expect(summary.city, 'Bhiwandi');
    });

    test('a missing kpis block yields zeroes rather than throwing', () {
      final summary = DashboardMapper.toSummary(
        const <String, dynamic>{},
        user: kTestUser,
      );

      expect(summary.totalOutstanding, 0);
      expect(summary.overdueCount, 0);
      expect(summary.priorityCalls, isEmpty);
      // Guards the divide in callProgress.
      expect(summary.callProgress, 0);
    });

    test('decimals arriving as strings are still parsed', () {
      // MySQL DECIMAL columns serialise as strings through some PHP setups.
      final summary = DashboardMapper.toSummary(
        dashboardBody(kpis: {'total_outstanding': '19248500.50'}),
        user: kTestUser,
      );

      expect(summary.totalOutstanding, 19248500.50);
    });

    test('a null figure does not become NaN', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(kpis: {'overdue': null, 'ptp_count': null}),
        user: kTestUser,
      );

      expect(summary.overdueAmount, 0);
      expect(summary.promiseCount, 0);
    });
  });

  group('HttpHomeRepository', () {
    test('asks for /dashboard and sends no filters', () async {
      final client = _StubClient(dashboardBody());
      final repo = HttpHomeRepository(client: client, user: kTestUser);

      final summary = await repo.loadSummary();

      // The server already scoped the figures; the app must not re-filter.
      expect(client.askedFor, 'dashboard');
      expect(summary.totalOutstanding, 19248500);
    });

    test('passes an API failure through for the view to render', () async {
      final repo = HttpHomeRepository(
        client: _StubClient(const {}, error: const NetworkException()),
        user: kTestUser,
      );

      await expectLater(repo.loadSummary(), throwsA(isA<NetworkException>()));
    });

    test('refuses to load with no signed-in user', () async {
      final repo = HttpHomeRepository(
        client: _StubClient(dashboardBody()),
        user: null,
      );

      await expectLater(
        repo.loadSummary(),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('priority calls', () {
    test('maps a followup row', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(followups: [followupRow()]),
        user: kTestUser,
      );

      final call = summary.priorityCalls.single;
      expect(call.invoiceId, 1042);
      expect(call.party, 'POLYCAB INDIA LTD RECEIVABLE A/C');
      expect(call.invoiceNo, 'TCIPL/1042');
      expect(call.outstanding, 482500);
      expect(call.mobile, '9820012345');
      expect(call.isCallable, isTrue);
      expect(call.ageLabel, '47 days overdue');
      expect(call.historyLabel, '2 calls · Call Later');
    });

    test('a party with no mobile is not callable', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(followups: [
          followupRow(overrides: {'mobile': null}),
        ]),
        user: kTestUser,
      );

      expect(summary.priorityCalls.single.isCallable, isFalse);
    });

    test('a never-called invoice reads as such', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(followups: [
          followupRow(overrides: {'call_count': 0, 'last_outcome': null}),
        ]),
        user: kTestUser,
      );

      expect(summary.priorityCalls.single.historyLabel, 'Never called');
    });

    test('due-today and not-due rows get the right age label', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(followups: [
          followupRow(overrides: {'days_overdue': 0}),
          followupRow(overrides: {'id': 2, 'days_overdue': -3}),
        ]),
        user: kTestUser,
      );

      expect(summary.priorityCalls.first.ageLabel, 'due today');
      expect(summary.priorityCalls.last.ageLabel, 'not due');
    });

    test('a malformed followups entry is skipped, not fatal', () {
      final summary = DashboardMapper.toSummary(
        <String, dynamic>{
          ...dashboardBody(followups: [followupRow()]),
          'followups': <Object>[followupRow(), 'unexpected', 42],
        },
        user: kTestUser,
      );

      expect(summary.priorityCalls, hasLength(1));
    });

    test('a row missing its party still renders', () {
      final summary = DashboardMapper.toSummary(
        dashboardBody(followups: [
          followupRow(overrides: {'party': null, 'status': null}),
        ]),
        user: kTestUser,
      );

      final call = summary.priorityCalls.single;
      expect(call.party, 'Unknown party');
      expect(call.status, 'Not Due');
    });
  });
}
