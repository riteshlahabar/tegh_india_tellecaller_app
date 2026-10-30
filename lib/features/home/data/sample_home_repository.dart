import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Placeholder data so the UI can be reviewed before the `/api/queue`
/// endpoint exists. Figures are the real live totals from the CRM; party
/// names are real accounts out of the three companies' books.
///
/// Delete this class once `HttpHomeRepository` lands — nothing but the
/// provider override in `home_view_model.dart` refers to it.
class SampleHomeRepository implements HomeRepository {
  const SampleHomeRepository();

  @override
  Future<HomeSummary> loadSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return const HomeSummary(
      callerName: 'Aakanksha',
      region: 'Mumbai',
      city: 'Bhiwandi',
      totalOutstanding: 19248500,
      overdueAmount: 11420300,
      dueTodayAmount: 842000,
      promiseAmount: 1965000,
      pendingCount: 12,
      overdueCount: 31,
      promiseCount: 4,
      callsMade: 9,
      callsTarget: 25,
      connected: 6,
      promisesTaken: 2,
      priorityCalls: [
        PriorityCall(
          invoiceId: 1042,
          party: 'POLYCAB INDIA LTD RECEIVABLE A/C',
          invoiceNo: 'TCIPL/1042',
          outstanding: 482500,
          mobile: '9820012345',
          status: 'Overdue',
          daysOverdue: 47,
          region: 'Mumbai',
          callCount: 0,
        ),
        PriorityCall(
          invoiceId: 988,
          party: 'TATA POWER LTD',
          invoiceNo: 'TCIPLP/88',
          outstanding: 310000,
          mobile: '9876543210',
          status: 'Overdue',
          daysOverdue: 12,
          region: 'Pune',
          callCount: 2,
          lastOutcome: 'Call Later',
        ),
        PriorityCall(
          invoiceId: 221,
          party: 'YCube Engineered Solutions Pvt Ltd.',
          invoiceNo: 'TCIG/221',
          outstanding: 120000,
          mobile: '9712300456',
          status: 'Due Today',
          daysOverdue: 0,
          region: 'Gujarat',
          callCount: 1,
          lastOutcome: 'Busy',
        ),
        PriorityCall(
          invoiceId: 764,
          party: 'SHREE ELECTRICALS & ENGINEERING',
          invoiceNo: 'TCIPL/764',
          outstanding: 96750,
          mobile: null,
          status: 'Promise Given',
          daysOverdue: 5,
          region: 'Mumbai',
          callCount: 3,
          lastOutcome: 'Payment Promise',
        ),
        PriorityCall(
          invoiceId: 1190,
          party: 'KEI INDUSTRIES LIMITED',
          invoiceNo: 'TCIPL/1190',
          outstanding: 87400,
          mobile: '9833445566',
          status: 'Overdue',
          daysOverdue: 23,
          region: 'Mumbai',
          callCount: 1,
          lastOutcome: 'No Answer',
        ),
        PriorityCall(
          invoiceId: 1203,
          party: 'ANAND ENTERPRISES',
          invoiceNo: 'TCIPL/1203',
          outstanding: 64200,
          mobile: '9821190088',
          status: 'Due Today',
          daysOverdue: 0,
          region: 'Mumbai',
          callCount: 0,
        ),
        PriorityCall(
          invoiceId: 455,
          party: 'VIRAT POWER CABLES PVT LTD',
          invoiceNo: 'TCIG/455',
          outstanding: 51800,
          mobile: '9725566110',
          status: 'Overdue',
          daysOverdue: 8,
          region: 'Gujarat',
          callCount: 2,
          lastOutcome: 'Call Later',
        ),
        PriorityCall(
          invoiceId: 902,
          party: 'DEEPAK SWITCHGEAR CO.',
          invoiceNo: 'TCIPLP/902',
          outstanding: 38900,
          mobile: '9028877445',
          status: 'Promise Given',
          daysOverdue: 2,
          region: 'Pune',
          callCount: 4,
          lastOutcome: 'Payment Promise',
        ),
      ],
    );
  }
}
