import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../shared/widgets/title_widget.dart';
import '../domain/home_summary.dart';
import 'home_view_model.dart';
import 'widgets/outstanding_card.dart';
import 'widgets/priority_call_list.dart';
import 'widgets/queue_search_bar.dart';
import 'widgets/quick_actions.dart';
import 'widgets/scope_app_bar.dart';

/// The View. It renders whatever the ViewModel holds and issues commands back
/// to it; it owns no data and performs no I/O.
///
/// Layout follows Demandium's home: scoped app bar, pinned search pill,
/// banner slot, a category strip, then titled list sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeSummary> state = ref.watch(homeViewModelProvider);

    return state.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: _HomeError(
          message: '$error',
          onRetry: () => ref.read(homeViewModelProvider.notifier).refresh(),
        ),
      ),
      data: (summary) => Scaffold(
        appBar: ScopeAppBar(
          region: summary.region,
          city: summary.city,
          notificationCount: summary.overdueCount,
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
            child: _HomeBody(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Clears the docked call button.
      padding: const EdgeInsets.only(bottom: Dimensions.pagesBottomPadding),
      children: [
        Gaps.vExtraSmall,
        QueueSearchBar(onTap: () {}),
        Gaps.vDefault,
        OutstandingCard(summary: summary),
        Gaps.vDefault,
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: TitleWidget(title: 'Quick action', actionLabel: 'All'),
        ),
        Gaps.vSmall,
        QuickActions(summary: summary, onSelect: (_) {}),
        Gaps.vSmall,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
          ),
          child: TitleWidget(title: 'Priority calls', onTap: () {}),
        ),
        Gaps.vSmall,
        PriorityCallList(
          calls: summary.priorityCalls,
          onCall: (_) {},
          onTap: (_) {},
        ),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraMoreLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: Dimensions.paddingSizeExtraMoreLarge,
              color: theme.disabledColor,
            ),
            Gaps.vDefault,
            Text('Could not load your day', style: theme.textTheme.titleMedium),
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
