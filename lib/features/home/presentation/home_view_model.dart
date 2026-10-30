import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/presentation/session_view_model.dart';
import '../data/http_home_repository.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Injection point. This is the only line that names an implementation --
/// swapping the sample data for the live API changed nothing in the view or
/// the view-model, which is what the repository interface was for.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HttpHomeRepository(
    client: ref.watch(apiClientProvider),
    user: ref.watch(currentUserProvider),
  ),
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
