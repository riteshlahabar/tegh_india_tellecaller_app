import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/domain/invoice_summary.dart';
import '../../home/presentation/home_view_model.dart';
import '../../outstanding/presentation/outstanding_view_model.dart';
import '../data/http_invoice_repository.dart';
import '../domain/invoice_repository.dart';

/// Injection point. The only line naming an implementation.
final Provider<InvoiceRepository> invoiceRepositoryProvider =
    Provider<InvoiceRepository>(
  (ref) => HttpInvoiceRepository(client: ref.watch(apiClientProvider)),
);

/// One invoice, by id. A family so several can be open in the back stack
/// without fighting over one slot.
class InvoiceViewModel extends FamilyAsyncNotifier<InvoiceSummary, int> {
  @override
  Future<InvoiceSummary> build(int invoiceId) {
    return ref.read(invoiceRepositoryProvider).fetch(invoiceId);
  }

  Future<void> refresh() async {
    state = AsyncValue<InvoiceSummary>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(invoiceRepositoryProvider).fetch(arg),
    );
  }

  /// Logs a call, then reloads this invoice and the two lists that show it.
  ///
  /// The server moves the invoice's status and follow-up date, so leaving the
  /// lists alone would show a row that no longer matches what was saved.
  Future<String> logCall(CallLog log) async {
    final String message =
        await ref.read(invoiceRepositoryProvider).logCall(log);

    await refresh();
    _invalidateLists();

    return message;
  }

  /// Saves a mobile number on the *party*, which is why every invoice for
  /// that customer has to be re-read, not just this one.
  Future<String> updateMobile(String mobile) async {
    final InvoiceSummary? invoice = state.valueOrNull;
    final int? partyId = invoice?.partyId;

    if (partyId == null) {
      throw StateError('This invoice has no customer attached.');
    }

    final String saved = await ref.read(invoiceRepositoryProvider).updateMobile(
          partyId: partyId,
          mobile: mobile,
        );

    await refresh();
    _invalidateLists();

    return saved;
  }

  Future<String> sendWhatsapp({
    required String template,
    required String message,
  }) {
    return ref.read(invoiceRepositoryProvider).sendWhatsapp(
          invoiceId: arg,
          template: template,
          message: message,
        );
  }

  Future<String> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? cc,
  }) {
    return ref.read(invoiceRepositoryProvider).sendEmail(
          invoiceId: arg,
          toEmail: toEmail,
          subject: subject,
          body: body,
          cc: cc,
        );
  }

  void _invalidateLists() {
    ref.invalidate(outstandingViewModelProvider);
    ref.invalidate(homeViewModelProvider);
  }
}

final AsyncNotifierProviderFamily<InvoiceViewModel, InvoiceSummary, int>
    invoiceViewModelProvider =
    AsyncNotifierProvider.family<InvoiceViewModel, InvoiceSummary, int>(
  InvoiceViewModel.new,
);

/// The rendered WhatsApp text for a template, fetched from the server so the
/// app never duplicates the wording the web CRM sends.
final AutoDisposeFutureProviderFamily<String, ({int invoiceId, String template})>
    whatsappPreviewProvider =
    FutureProvider.autoDispose.family<String, ({int invoiceId, String template})>(
  (ref, args) => ref.read(invoiceRepositoryProvider).whatsappPreview(
        invoiceId: args.invoiceId,
        template: args.template,
      ),
);
