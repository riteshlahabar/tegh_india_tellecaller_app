import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../core/platform/dialer.dart';
import '../../../shared/domain/invoice_summary.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../domain/invoice_repository.dart';
import 'invoice_view_model.dart';
import 'widgets/email_sheet.dart';
import 'widgets/log_call_sheet.dart';
import 'widgets/whatsapp_sheet.dart';

/// One invoice, and everything a telecaller can do about it.
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});

  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<InvoiceSummary> state =
        ref.watch(invoiceViewModelProvider(invoiceId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Invoice'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Failed(
          message: '$error',
          onRetry: () =>
              ref.read(invoiceViewModelProvider(invoiceId).notifier).refresh(),
        ),
        data: (invoice) => _Body(invoice: invoice, invoiceId: invoiceId),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.invoice, required this.invoiceId});

  final InvoiceSummary invoice;
  final int invoiceId;

  InvoiceViewModel _vm(WidgetRef ref) =>
      ref.read(invoiceViewModelProvider(invoiceId).notifier);

  /// Every action reports the server's own words, success or failure.
  Future<void> _run(
    BuildContext context,
    Future<String> Function() action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final String message = await action();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppPalette.overdue,
        ),
      );
    }
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final String? mobile = invoice.mobile;
    if (mobile == null) {
      await _fixMobile(context, ref);
      return;
    }

    final bool opened = await Dialer.call(mobile);
    if (!context.mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dialer available on this device.')),
      );
      return;
    }

    // Offered, not forced: the call may not have connected, and a log the
    // telecaller did not choose to write is worse than none.
    await _logCall(context, ref);
  }

  Future<void> _logCall(BuildContext context, WidgetRef ref) async {
    final CallLog? log = await showModalBottomSheet<CallLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) => LogCallSheet(
        invoiceId: invoiceId,
        outstanding: invoice.outstanding,
      ),
    );

    if (log == null || !context.mounted) {
      return;
    }
    await _run(context, () => _vm(ref).logCall(log));
  }

  Future<void> _fixMobile(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller =
        TextEditingController(text: invoice.mobile ?? '');

    final String? entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mobile number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile',
            helperText: 'Saved against ${invoice.party}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (entered == null || entered.isEmpty || !context.mounted) {
      return;
    }
    await _run(context, () async {
      final String saved = await _vm(ref).updateMobile(entered);
      return 'Mobile saved as $saved.';
    });
  }

  Future<void> _whatsapp(BuildContext context, WidgetRef ref) async {
    if (invoice.mobile == null) {
      await _fixMobile(context, ref);
      return;
    }

    final ({String template, String message})? composed =
        await showModalBottomSheet<({String template, String message})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => WhatsappSheet(invoiceId: invoiceId),
    );

    if (composed == null || !context.mounted) {
      return;
    }
    await _run(
      context,
      () => _vm(ref).sendWhatsapp(
        template: composed.template,
        message: composed.message,
      ),
    );
  }

  Future<void> _email(BuildContext context, WidgetRef ref) async {
    final ({String toEmail, String cc, String subject, String body})? composed =
        await showModalBottomSheet<
            ({String toEmail, String cc, String subject, String body})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmailSheet(invoice: invoice),
    );

    if (composed == null || !context.mounted) {
      return;
    }
    await _run(
      context,
      () => _vm(ref).sendEmail(
        toEmail: composed.toEmail,
        subject: composed.subject,
        body: composed.body,
        cc: composed.cc.isEmpty ? null : composed.cc,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _vm(ref).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
          Dimensions.pagesBottomPadding,
        ),
        children: [
          _Header(invoice: invoice),
          Gaps.vDefault,
          _Actions(
            invoice: invoice,
            onCall: () => _call(context, ref),
            onLog: () => _logCall(context, ref),
            onWhatsapp: () => _whatsapp(context, ref),
            onEmail: () => _email(context, ref),
          ),
          Gaps.vDefault,
          _Details(invoice: invoice, onFixMobile: () => _fixMobile(context, ref)),
        ],
      ),
    );
  }
}

/// Party, amount and status, on the brand card.
class _Header extends StatelessWidget {
  const _Header({required this.invoice});

  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.primary, AppPalette.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invoice.party,
            style: robotoBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeLarge,
            ),
          ),
          Gaps.vTine,
          Text(
            '${invoice.invoiceNo} · ${invoice.ageLabel}',
            style: robotoRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          Gaps.vDefault,
          Text(
            invoice.outstandingInr,
            style: robotoBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeOverLarge + 4,
            ),
          ),
          Gaps.vTine,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeEight,
              vertical: Dimensions.paddingSizeTine,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Text(
              invoice.status,
              style: robotoSemiBold.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeExtraSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.invoice,
    required this.onCall,
    required this.onLog,
    required this.onWhatsapp,
    required this.onEmail,
  });

  final InvoiceSummary invoice;
  final VoidCallback onCall;
  final VoidCallback onLog;
  final VoidCallback onWhatsapp;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            icon: invoice.isCallable
                ? Icons.call_rounded
                : Icons.phone_disabled_rounded,
            label: invoice.isCallable ? 'Call' : 'Add number',
            onTap: onCall,
          ),
        ),
        Gaps.hEight,
        Expanded(
          child: _Action(
            icon: Icons.chat_outlined,
            label: 'WhatsApp',
            onTap: onWhatsapp,
          ),
        ),
        Gaps.hEight,
        Expanded(
          child: _Action(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            onTap: onEmail,
          ),
        ),
        Gaps.hEight,
        Expanded(
          child: _Action(
            icon: Icons.edit_note_rounded,
            label: 'Log',
            onTap: onLog,
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Column(
            children: [
              Icon(icon, size: Dimensions.iconSizeDefault,
                  color: theme.colorScheme.primary),
              Gaps.vTine,
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.invoice, required this.onFixMobile});

  final InvoiceSummary invoice;
  final VoidCallback onFixMobile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow:
            theme.brightness == Brightness.light ? cardShadow : null,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          _Row(
            label: 'Mobile',
            value: invoice.mobile ?? 'Not on file',
            muted: invoice.mobile == null,
            trailing: TextButton(
              onPressed: onFixMobile,
              child: Text(invoice.mobile == null ? 'Add' : 'Edit'),
            ),
          ),
          if (invoice.email != null) _Row(label: 'Email', value: invoice.email!),
          if (invoice.city != null) _Row(label: 'City', value: invoice.city!),
          if (invoice.invoiceDateLabel != null)
            _Row(label: 'Invoice date', value: invoice.invoiceDateLabel!),
          if (invoice.dueDateLabel != null)
            _Row(label: 'Due date', value: invoice.dueDateLabel!),
          if (invoice.agingBucket.isNotEmpty)
            _Row(label: 'Aging', value: invoice.agingBucket),
          if (invoice.nextFollowupLabel != null)
            _Row(label: 'Next follow-up', value: invoice.nextFollowupLabel!),
          if (invoice.promiseDate != null)
            _Row(label: 'Promise date', value: invoice.promiseDate!),
          if (invoice.assigned != null)
            _Row(label: 'Assigned to', value: invoice.assigned!),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.muted = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool muted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: context.customThemeColors.subtitle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: muted ? Theme.of(context).hintColor : null,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraMoreLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: theme.disabledColor),
            Gaps.vDefault,
            Text('Could not load', style: theme.textTheme.titleMedium),
            Gaps.vExtraSmall,
            Text(
              message,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.hintColor,
              ),
            ),
            Gaps.vDefault,
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
