import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../shared/widgets/call_tile.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../customers/domain/customer_detail.dart';
import '../../invoice/domain/invoice_repository.dart';
import '../domain/history_repository.dart';
import 'history_view_model.dart';

/// This telecaller's own call log. The server scopes it to them, so nothing
/// identifying the user is sent.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scroll = ScrollController();

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
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;

    if (remaining < 400) {
      ref.read(historyViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<HistoryState> state = ref.watch(historyViewModelProvider);
    final HistoryFilters filters = ref.watch(historyFiltersProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'History', isBackButtonExist: false),
      body: Column(
        children: [
          _RangeTabs(selected: filters.range),
          _OutcomeChips(selected: filters.outcome),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failed(
                message: '$error',
                onRetry: () =>
                    ref.read(historyViewModelProvider.notifier).refresh(),
              ),
              data: (data) => data.items.isEmpty
                  ? _Empty(filters: filters)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(historyViewModelProvider.notifier).refresh(),
                      child: ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeDefault,
                          Dimensions.paddingSizeEight,
                          Dimensions.paddingSizeDefault,
                          Dimensions.pagesBottomPadding,
                        ),
                        itemCount: data.items.length + 1,
                        separatorBuilder: (_, _) => Gaps.vSmall,
                        itemBuilder: (context, index) {
                          if (index == data.items.length) {
                            return _Footer(data: data);
                          }

                          final CallRecord call = data.items[index];
                          return CallTile(
                            call: call,
                            showParty: true,
                            // Only a call tied to an invoice can open one.
                            onTap: call.invoiceId == null
                                ? null
                                : () => context
                                    .push(Routes.invoiceOf(call.invoiceId!)),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today / This week / All.
class _RangeTabs extends ConsumerWidget {
  const _RangeTabs({required this.selected});

  final CallRange selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        0,
      ),
      child: SegmentedButton<CallRange>(
        segments: [
          for (final CallRange range in CallRange.values)
            ButtonSegment<CallRange>(value: range, label: Text(range.label)),
        ],
        selected: <CallRange>{selected},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => ref
            .read(historyFiltersProvider.notifier)
            .setRange(selection.first),
      ),
    );
  }
}

class _OutcomeChips extends ConsumerWidget {
  const _OutcomeChips({required this.selected});

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
          for (final String outcome in CallOutcomes.all)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: Dimensions.paddingSizeEight,
              ),
              child: Center(
                child: ChoiceChip(
                  label: Text(outcome),
                  selected: selected == outcome,
                  showCheckmark: false,
                  onSelected: (_) => ref
                      .read(historyFiltersProvider.notifier)
                      .toggleOutcome(outcome),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.data});

  final HistoryState data;

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

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Center(
        child: Text(
          '${data.items.length} of ${data.total} calls',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: context.customThemeColors.subtitle,
          ),
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.filters});

  final HistoryFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool filtered = filters.outcome != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraMoreLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.history_rounded,
              size: 42,
              color: theme.disabledColor,
            ),
            Gaps.vDefault,
            Text(
              filtered ? 'No matching calls' : 'No calls yet',
              style: theme.textTheme.titleMedium,
            ),
            Gaps.vExtraSmall,
            Text(
              filtered
                  ? 'Nothing with that outcome in ${filters.range.label.toLowerCase()}.'
                  : 'Calls you log will appear here.',
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.hintColor,
              ),
            ),
            if (filtered) ...[
              Gaps.vDefault,
              FilledButton(
                onPressed: () =>
                    ref.read(historyFiltersProvider.notifier).toggleOutcome(
                          filters.outcome,
                        ),
                child: const Text('Clear outcome'),
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
