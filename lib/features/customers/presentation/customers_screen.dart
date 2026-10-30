import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../core/platform/dialer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'customers_view_model.dart';
import 'widgets/customer_card.dart';

/// The party directory, scoped by the server to this account.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
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

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final double remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;

    if (remaining < 400) {
      ref.read(customersViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CustomersState> state =
        ref.watch(customersViewModelProvider);
    final String search = ref.watch(customerSearchProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Customers',
        isBackButtonExist: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeEight,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              style: robotoRegular,
              onChanged: ref.read(customerSearchProvider.notifier).search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search name, code or mobile',
                hintStyle:
                    robotoRegular.copyWith(color: Theme.of(context).hintColor),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: Dimensions.iconSizeDefault,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
              ),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failed(
                message: '$error',
                onRetry: () =>
                    ref.read(customersViewModelProvider.notifier).refresh(),
              ),
              data: (data) => data.items.isEmpty
                  ? _Empty(searching: search.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(customersViewModelProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeDefault,
                          0,
                          Dimensions.paddingSizeDefault,
                          Dimensions.pagesBottomPadding,
                        ),
                        itemCount: data.items.length + 1,
                        separatorBuilder: (_, _) => Gaps.vSmall,
                        itemBuilder: (context, index) {
                          if (index == data.items.length) {
                            return _Footer(data: data);
                          }

                          final customer = data.items[index];
                          return CustomerCard(
                            customer: customer,
                            onCall: () =>
                                Dialer.call(customer.mobile ?? ''),
                            onTap: () => context
                                .push(Routes.customerOf(customer.id)),
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

class _Footer extends StatelessWidget {
  const _Footer({required this.data});

  final CustomersState data;

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
          '${data.items.length} of ${data.total} customers',
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
  const _Empty({required this.searching});

  final bool searching;

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
              searching ? Icons.search_off_rounded : Icons.business_outlined,
              size: 42,
              color: theme.disabledColor,
            ),
            Gaps.vDefault,
            Text(
              searching ? 'No match' : 'No customers',
              style: theme.textTheme.titleMedium,
            ),
            Gaps.vExtraSmall,
            Text(
              searching
                  ? 'Nothing matches that name, code or number.'
                  : 'Your region and city have no customers on file.',
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: theme.hintColor,
              ),
            ),
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
