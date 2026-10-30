import 'package:flutter/material.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../domain/outstanding_filters.dart';

/// Aging and city, behind the funnel icon. Status lives on the chip row
/// instead, because it is the cut a telecaller changes most often.
class OutstandingFilterSheet extends StatefulWidget {
  const OutstandingFilterSheet({
    required this.initial,
    required this.cities,
    super.key,
  });

  final OutstandingFilters initial;

  /// Towns present in this account's own rows. Empty when the API has not
  /// surfaced any, in which case the city section is hidden rather than
  /// shown as a dropdown with nothing in it.
  final List<String> cities;

  @override
  State<OutstandingFilterSheet> createState() => _OutstandingFilterSheetState();
}

class _OutstandingFilterSheetState extends State<OutstandingFilterSheet> {
  late String? _aging = widget.initial.aging;
  late String? _city = widget.initial.city;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        top: Dimensions.paddingSizeDefault,
        // Clears the keyboard and the home indicator.
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            Dimensions.paddingSizeLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Gaps.vDefault,
          Text(
            'Filter',
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          ),
          Gaps.vDefault,
          Text(
            'Aging',
            style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
          Gaps.vEight,
          Wrap(
            spacing: Dimensions.paddingSizeEight,
            runSpacing: Dimensions.paddingSizeEight,
            children: [
              for (final String bucket in OutstandingFilters.agingBuckets)
                ChoiceChip(
                  label: Text(bucket),
                  selected: _aging == bucket,
                  showCheckmark: false,
                  onSelected: (selected) =>
                      setState(() => _aging = selected ? bucket : null),
                ),
            ],
          ),
          if (widget.cities.isNotEmpty) ...[
            Gaps.vDefault,
            Text(
              'City',
              style:
                  robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            Gaps.vEight,
            Wrap(
              spacing: Dimensions.paddingSizeEight,
              runSpacing: Dimensions.paddingSizeEight,
              children: [
                for (final String city in widget.cities)
                  ChoiceChip(
                    label: Text(city),
                    selected: _city == city,
                    showCheckmark: false,
                    onSelected: (selected) =>
                        setState(() => _city = selected ? city : null),
                  ),
              ],
            ),
          ],
          Gaps.vLarge,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _aging = null;
                    _city = null;
                  }),
                  child: const Text('Clear'),
                ),
              ),
              Gaps.hSmall,
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    widget.initial.copyWith(
                      aging: () => _aging,
                      city: () => _city,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
