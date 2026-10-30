import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/http_outstanding_repository.dart';
import '../domain/outstanding_filters.dart';
import '../domain/outstanding_page.dart';
import '../domain/outstanding_repository.dart';

/// Injection point. The only line naming an implementation.
final Provider<OutstandingRepository> outstandingRepositoryProvider =
    Provider<OutstandingRepository>(
  (ref) => HttpOutstandingRepository(client: ref.watch(apiClientProvider)),
);

/// The filters currently applied. Kept separate from the list so changing one
/// is a plain state write, and the list reloads by watching this.
class OutstandingFiltersNotifier extends Notifier<OutstandingFilters> {
  Timer? _debounce;

  @override
  OutstandingFilters build() {
    ref.onDispose(() => _debounce?.cancel());
    return const OutstandingFilters();
  }

  /// Typing fires per keystroke, so the request is held back until the user
  /// pauses. Without this a six-character party name costs six round trips
  /// and the results arrive out of order.
  void search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(search: value.trim());
    });
  }

  /// Tapping the active status chip clears it, which is why this takes a
  /// nullable and toggles rather than just assigning.
  void toggleStatus(String? status) {
    state = state.copyWith(status: () => state.status == status ? null : status);
  }

  void setAging(String? aging) => state = state.copyWith(aging: () => aging);

  void setCity(String? city) => state = state.copyWith(city: () => city);

  void clear() {
    _debounce?.cancel();
    state = const OutstandingFilters();
  }
}

final NotifierProvider<OutstandingFiltersNotifier, OutstandingFilters>
    outstandingFiltersProvider =
    NotifierProvider<OutstandingFiltersNotifier, OutstandingFilters>(
  OutstandingFiltersNotifier.new,
);

/// The list itself. Rebuilt from scratch whenever the filters change, because
/// page 2 of one filter set means nothing under another.
class OutstandingViewModel extends AsyncNotifier<OutstandingState> {
  @override
  Future<OutstandingState> build() async {
    final OutstandingFilters filters = ref.watch(outstandingFiltersProvider);

    final OutstandingPage first = await ref
        .read(outstandingRepositoryProvider)
        .load(filters: filters);

    return const OutstandingState().appending(first);
  }

  /// Appends the next page. Safe to call repeatedly from a scroll listener:
  /// it returns immediately if a page is already in flight or the list is
  /// complete.
  Future<void> loadMore() async {
    final OutstandingState? current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) {
      return;
    }

    state = AsyncValue<OutstandingState>.data(
      current.copyWith(loadingMore: true),
    );

    try {
      final OutstandingPage next =
          await ref.read(outstandingRepositoryProvider).load(
                filters: ref.read(outstandingFiltersProvider),
                page: current.page + 1,
              );

      state = AsyncValue<OutstandingState>.data(current.appending(next));
    } catch (error, stack) {
      // Keep the rows already on screen; a failed page 3 should not blank
      // pages 1 and 2. The flag is cleared so the user can scroll and retry.
      state = AsyncValue<OutstandingState>.data(
        current.copyWith(loadingMore: false),
      );
      ref.read(outstandingErrorProvider.notifier).state =
          AsyncValue<void>.error(error, stack);
    }
  }

  Future<void> refresh() async {
    state = AsyncValue<OutstandingState>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final OutstandingPage first = await ref
          .read(outstandingRepositoryProvider)
          .load(filters: ref.read(outstandingFiltersProvider));
      return const OutstandingState().appending(first);
    });
  }
}

final AsyncNotifierProvider<OutstandingViewModel, OutstandingState>
    outstandingViewModelProvider =
    AsyncNotifierProvider<OutstandingViewModel, OutstandingState>(
  OutstandingViewModel.new,
);

/// A failure that must not blank the list -- a pagination error. The screen
/// shows it as a snack bar and clears it.
final StateProvider<AsyncValue<void>> outstandingErrorProvider =
    StateProvider<AsyncValue<void>>(
  (ref) => const AsyncValue<void>.data(null),
);
