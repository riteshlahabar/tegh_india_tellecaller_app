import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sample_home_repository.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Injection point. Phase 2 overrides this with the HTTP implementation and
/// nothing else in the feature changes.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const SampleHomeRepository(),
);

/// The home screen's ViewModel. Holds no widgets and no HTTP; it owns the
/// screen's state and the one command the screen can issue.
class HomeViewModel extends AsyncNotifier<HomeSummary> {
  @override
  Future<HomeSummary> build() => ref.read(homeRepositoryProvider).loadSummary();

  /// Pull-to-refresh. Keeps the old data on screen while reloading so the
  /// list does not flash empty.
  Future<void> refresh() async {
    state = AsyncValue<HomeSummary>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).loadSummary(),
    );
  }
}

final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, HomeSummary>(HomeViewModel.new);
