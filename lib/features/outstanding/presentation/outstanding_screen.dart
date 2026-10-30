import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/platform/dialer.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../shared/domain/invoice_summary.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/invoice_card.dart';
import '../domain/outstanding_filters.dart';
import '../domain/outstanding_page.dart';
import 'outstanding_view_model.dart';
import 'widgets/outstanding_filter_sheet.dart';

/// The full outstanding book, scoped by the server to this account.
class OutstandingScreen extends ConsumerStatefulWidget {
  const OutstandingScreen({super.key});

  @override
  ConsumerState<OutstandingScreen> createState() => _OutstandingScreenState();
}

class _OutstandingScreenState extends ConsumerState<OutstandingScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  /// Fetches the next page while the user is still 400px from the bottom, so
  /// the rows are usually there before the scroll reaches them.
  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;

    if (remaining < 400) {
      ref.read(outstandingViewModelProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters(OutstandingFilters current) async {
    // Towns offered are the ones actually present in the loaded rows, so the
    // sheet never offers a city that returns nothing.
    final List<String> cities = (ref
            .read(outstandingViewModelProvider)
            .valueOrNull
            ?.items
            .map((invoice) => invoice.city)
            .whereType<String>()
            .toSet()
            .toList() ??
        <String>[])
      ..sort();

    final OutstandingFilters? applied =
        await showModalBottomSheet<OutstandingFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) =>
          OutstandingFilterSheet(initial: current, cities: cities),
    );

    if (applied == null) {
      return;
    }

    final OutstandingFiltersNotifier filters =
        ref.read(outstandingFiltersProvider.notifier);
    filters
      ..setAging(applied.aging)
      ..setCity(applied.city);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OutstandingState> state =
        ref.watch(outstandingViewModelProvider);
    final OutstandingFilters filters = ref.watch(outstandingFiltersProvider);

    // A failed *extra* page must not blank the list, so it arrives here as a
    // snack bar rather than replacing the screen with an error.
    ref.listen(outstandingErrorProvider, (previous, next) {
      final Object? error = next.error;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
        ref.read(outstandingErrorProvider.notifier).state =
            const AsyncValue<void>.data(null);
      }
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Outstanding',
        isBackButtonExist: false,
        actions: [
          _FilterButton(
            count: filters.advancedCount,
            onPressed: () => _openFilters(filters),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(controller: _search),
          _StatusChips(selected: filters.status),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failed(
                message: '$error',
                onRetry: () =>
                    ref.read(outstandingViewModelProvider.notifier).refresh(),
              ),
              data: (data) => _List(
                data: data,
                scroll: _scroll,
                filtersEmpty: filters.isEmpty,
                onRefresh: () =>
                    ref.read(outstandingViewModelProvider.notifier).refresh(),
                onClearFilters: () {
                  _search.clear();
                  ref.read(outstandingFiltersProvider.notifier).clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        0,
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: robotoRegular,
        onChanged: ref.read(outstandingFiltersProvider.notifier).search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search party or invoice',
          hintStyle: robotoRegular.copyWith(
            color: Theme.of(context).hintColor,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: Dimensions.iconSizeDefault,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: Dimensions.iconSizeSmall,
                  ),
                  onPressed: () {
                    controller.clear();
                    ref.read(outstandingFiltersProvider.notifier).search('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
      ),
    );
  }
}

class _StatusChips extends ConsumerWidget {
  const _StatusChips({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        children: [
          for (final String status in OutstandingFilters.statuses)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: Dimensions.paddingSizeEight,
              ),
              child: Center(
                child: ChoiceChip(
                  label: Text(status),
                  selected: selected == status,
                  showCheckmark: false,
                  onSelected: (_) => ref
                      .read(outstandingFiltersProvider.notifier)
                      .toggleStatus(status),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.data,
    required this.scroll,
    required this.filtersEmpty,
    required this.onRefresh,
    required this.onClearFilters,
  });

  final OutstandingState data;
  final ScrollController scroll;
  final bool filtersEmpty;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return _Empty(
        filtersEmpty: filtersEmpty,
        onClearFilters: onClearFilters,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeEight,
          Dimensions.paddingSizeDefault,
          Dimensions.pagesBottomPadding,
        ),
        // One extra row carries either the count or the next-page spinner.
        itemCount: data.items.length + 1,
        separatorBuilder: (_, _) => Gaps.vSmall,
        itemBuilder: (context, index) {
          if (index == data.items.length) {
            return _Footer(data: data);
          }

          final InvoiceSummary invoice = data.items[index];
          return InvoiceCard(
            invoice: invoice,
            onCall: () => Dialer.call(invoice.mobile ?? ''),
            onTap: () => context.push(Routes.invoiceOf(invoice.id)),
          );
        },
      ),
    );
  }
}

/// Either "loading more" or the count, never both.
class _Footer extends StatelessWidget {
  const _Footer({required this.data});

  final OutstandingState data;

  @override
  Widget build(BuildContext context) {
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    final String label = data.isFiltered
        ? '${data.items.length} of ${data.total} shown · ${data.totalCount} in all'
        : '${data.items.length} of ${data.total}';

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Center(
        child: Text(
          label,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: context.customThemeColors.subtitle,
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtersEmpty, required this.onClearFilters});

  final bool filtersEmpty;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraMoreLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtersEmpty
                  ? Icons.inbox_outlined
                  : Icons.filter_alt_off_outlined,
              size: 42,
              color: theme.disabledColor,
            ),
            Gaps.vDefault,
            Text(
              filtersEmpty ? 'Nothing outstanding' : 'No matches',
              style: theme.textTheme.titleMedium,
            ),
            Gaps.vExtraSmall,
            Text(
              filtersEmpty
                  ? 'Your region and city have no open invoices right now.'
                  : 'No invoice matches these filters.',
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.hintColor,
              ),
            ),
            if (!filtersEmpty) ...[
              Gaps.vDefault,
              FilledButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
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
            Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: theme.disabledColor,
            ),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filter',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(
          Icons.tune_rounded,
          color: Colors.white,
          size: Dimensions.iconSizeDefault,
        ),
      ),
    );
  }
}
