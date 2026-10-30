import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../customers/domain/customer_detail.dart';
import '../data/http_history_repository.dart';
import '../domain/history_repository.dart';

/// Injection point. The only line naming an implementation.
final Provider<HistoryRepository> historyRepositoryProvider =
    Provider<HistoryRepository>(
  (ref) => HttpHistoryRepository(client: ref.watch(apiClientProvider)),
);

/// Range and outcome, watched by the list.
class HistoryFiltersNotifier extends Notifier<HistoryFilters> {
  @override
  HistoryFilters build() => const HistoryFilters();

  void setRange(CallRange range) => state = state.copyWith(range: range);

  /// Tapping the active outcome clears it.
  void toggleOutcome(String? outcome) {
    state = state.copyWith(
      outcome: () => state.outcome == outcome ? null : outcome,
    );
  }

  void clear() => state = const HistoryFilters();
}

final NotifierProvider<HistoryFiltersNotifier, HistoryFilters>
    historyFiltersProvider =
    NotifierProvider<HistoryFiltersNotifier, HistoryFilters>(
  HistoryFiltersNotifier.new,
);

/// Accumulated call rows plus the paging cursor.
class HistoryState {
  const HistoryState({
    this.items = const <CallRecord>[],
    this.page = 0,
    this.lastPage = 1,
    this.total = 0,
    this.loadingMore = false,
  });

  final List<CallRecord> items;
  final int page;
  final int lastPage;
  final int total;
  final bool loadingMore;

  bool get hasMore => page < lastPage;

  HistoryState appending(CallsPage next) {
    return HistoryState(
      items: <CallRecord>[...items, ...next.items],
      page: next.page,
      lastPage: next.lastPage,
      total: next.total,
    );
  }

  HistoryState copyWith({bool? loadingMore}) {
    return HistoryState(
      items: items,
      page: page,
      lastPage: lastPage,
      total: total,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// The call log. Rebuilt whenever the filters change.
class HistoryViewModel extends AsyncNotifier<HistoryState> {
  @override
  Future<HistoryState> build() async {
    final HistoryFilters filters = ref.watch(historyFiltersProvider);

    final CallsPage first =
        await ref.read(historyRepositoryProvider).load(filters: filters);

    return const HistoryState().appending(first);
  }

  Future<void> loadMore() async {
    final HistoryState? current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) {
      return;
    }

    state = AsyncValue<HistoryState>.data(current.copyWith(loadingMore: true));

    try {
      final CallsPage next = await ref.read(historyRepositoryProvider).load(
            filters: ref.read(historyFiltersProvider),
            page: current.page + 1,
          );

      state = AsyncValue<HistoryState>.data(current.appending(next));
    } catch (_) {
      // Keep the rows already on screen; scrolling again retries.
      state = AsyncValue<HistoryState>.data(
        current.copyWith(loadingMore: false),
      );
    }
  }

  Future<void> refresh() async {
    state = AsyncValue<HistoryState>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final CallsPage first = await ref
          .read(historyRepositoryProvider)
          .load(filters: ref.read(historyFiltersProvider));
      return const HistoryState().appending(first);
    });
  }
}

final AsyncNotifierProvider<HistoryViewModel, HistoryState>
    historyViewModelProvider =
    AsyncNotifierProvider<HistoryViewModel, HistoryState>(
  HistoryViewModel.new,
);
