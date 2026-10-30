import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/http_customers_repository.dart';
import '../domain/customer.dart';
import '../domain/customer_detail.dart';
import '../domain/customers_repository.dart';

/// Injection point. The only line naming an implementation.
final Provider<CustomersRepository> customersRepositoryProvider =
    Provider<CustomersRepository>(
  (ref) => HttpCustomersRepository(client: ref.watch(apiClientProvider)),
);

/// The directory search term, debounced the same way Outstanding's is.
class CustomerSearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      state = value.trim();
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

final NotifierProvider<CustomerSearchNotifier, String> customerSearchProvider =
    NotifierProvider<CustomerSearchNotifier, String>(
  CustomerSearchNotifier.new,
);

/// Accumulated directory rows plus the paging cursor.
class CustomersState {
  const CustomersState({
    this.items = const <Customer>[],
    this.page = 0,
    this.lastPage = 1,
    this.total = 0,
    this.loadingMore = false,
  });

  final List<Customer> items;
  final int page;
  final int lastPage;
  final int total;
  final bool loadingMore;

  bool get hasMore => page < lastPage;

  CustomersState appending(CustomersPage next) {
    return CustomersState(
      items: <Customer>[...items, ...next.items],
      page: next.page,
      lastPage: next.lastPage,
      total: next.total,
    );
  }

  CustomersState copyWith({bool? loadingMore}) {
    return CustomersState(
      items: items,
      page: page,
      lastPage: lastPage,
      total: total,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// The directory. Rebuilt whenever the search term changes.
class CustomersViewModel extends AsyncNotifier<CustomersState> {
  @override
  Future<CustomersState> build() async {
    final String search = ref.watch(customerSearchProvider);

    final CustomersPage first =
        await ref.read(customersRepositoryProvider).load(search: search);

    return const CustomersState().appending(first);
  }

  /// Appends the next page; a no-op while one is in flight or the list is
  /// complete, so a scroll listener can call it freely.
  Future<void> loadMore() async {
    final CustomersState? current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) {
      return;
    }

    state = AsyncValue<CustomersState>.data(current.copyWith(loadingMore: true));

    try {
      final CustomersPage next =
          await ref.read(customersRepositoryProvider).load(
                search: ref.read(customerSearchProvider),
                page: current.page + 1,
              );

      state = AsyncValue<CustomersState>.data(current.appending(next));
    } catch (_) {
      // Keep what is on screen; the user can scroll again to retry.
      state =
          AsyncValue<CustomersState>.data(current.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = AsyncValue<CustomersState>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final CustomersPage first = await ref
          .read(customersRepositoryProvider)
          .load(search: ref.read(customerSearchProvider));
      return const CustomersState().appending(first);
    });
  }
}

final AsyncNotifierProvider<CustomersViewModel, CustomersState>
    customersViewModelProvider =
    AsyncNotifierProvider<CustomersViewModel, CustomersState>(
  CustomersViewModel.new,
);

/// One customer with its invoices and call history, by party id.
final AutoDisposeFutureProviderFamily<CustomerDetail, int>
    customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetail, int>(
  (ref, partyId) => ref.read(customersRepositoryProvider).detail(partyId),
);
