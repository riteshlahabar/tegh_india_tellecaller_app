import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../core/platform/dialer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/call_tile.dart';
import '../../../shared/widgets/invoice_card.dart';
import '../../../shared/widgets/title_widget.dart';
import '../domain/customer.dart';
import '../domain/customer_detail.dart';
import 'customers_view_model.dart';

/// One customer: who they are, what they owe, and every call made to them.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({required this.partyId, super.key});

  final int partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CustomerDetail> state =
        ref.watch(customerDetailProvider(partyId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Customer'),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Failed(
          message: '$error',
          onRetry: () => ref.invalidate(customerDetailProvider(partyId)),
        ),
        data: (detail) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(customerDetailProvider(partyId)),
          child: _Body(detail: detail),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final CustomerDetail detail;

  @override
  Widget build(BuildContext context) {
    final Customer customer = detail.customer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.pagesBottomPadding,
      ),
      children: [
        _Header(customer: customer),
        Gaps.vDefault,
        _Contact(customer: customer),
        Gaps.vDefault,
        TitleWidget(title: 'Invoices (${detail.invoices.length})'),
        Gaps.vSmall,
        if (detail.invoices.isEmpty)
          _Nothing(text: 'No invoices on file for this customer.')
        else
          for (final invoice in detail.invoices) ...[
            InvoiceCard(
              invoice: invoice,
              onCall: () => Dialer.call(invoice.mobile ?? ''),
              onTap: () => context.push(Routes.invoiceOf(invoice.id)),
            ),
            Gaps.vSmall,
          ],
        Gaps.vEight,
        TitleWidget(title: 'Call history (${detail.calls.length})'),
        Gaps.vSmall,
        if (detail.calls.isEmpty)
          _Nothing(text: 'Nobody has called this customer yet.')
        else
          for (final call in detail.calls) ...[
            CallTile(
              call: call,
              onTap: call.invoiceId == null
                  ? null
                  : () => context.push(Routes.invoiceOf(call.invoiceId!)),
            ),
            Gaps.vSmall,
          ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.customer});

  final Customer customer;

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
            customer.name,
            style: robotoBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeLarge,
            ),
          ),
          if (customer.code != null || customer.place.isNotEmpty) ...[
            Gaps.vTine,
            Text(
              <String>[
                if (customer.code != null) customer.code!,
                if (customer.place.isNotEmpty) customer.place,
              ].join(' · '),
              style: robotoRegular.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ],
          Gaps.vDefault,
          Text(
            customer.outstandingInr,
            style: robotoBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeOverLarge + 4,
            ),
          ),
          Gaps.vTine,
          Text(
            '${customer.invoiceCount} '
            '${customer.invoiceCount == 1 ? 'invoice' : 'invoices'} '
            '· ${customer.status}',
            style: robotoRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: theme.brightness == Brightness.light ? cardShadow : null,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          _Row(
            label: 'Mobile',
            value: customer.mobile ?? 'Not on file',
            muted: customer.mobile == null,
            trailing: customer.isCallable
                ? IconButton(
                    tooltip: 'Call',
                    icon: Icon(
                      Icons.call_rounded,
                      size: Dimensions.iconSizeDefault,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => Dialer.call(customer.mobile!),
                  )
                : null,
          ),
          if (customer.contact != null)
            _Row(label: 'Contact', value: customer.contact!),
          if (customer.email != null)
            _Row(label: 'Email', value: customer.email!),
          if (customer.gstin != null)
            _Row(label: 'GSTIN', value: customer.gstin!),
          if (customer.creditLimitInr != null)
            _Row(label: 'Credit limit', value: customer.creditLimitInr!),
          if (customer.assigned != null)
            _Row(label: 'Assigned to', value: customer.assigned!),
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
            width: 100,
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

class _Nothing extends StatelessWidget {
  const _Nothing({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Text(
        text,
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).hintColor,
        ),
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
