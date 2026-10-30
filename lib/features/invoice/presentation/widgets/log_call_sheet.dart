import 'package:flutter/material.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../domain/invoice_repository.dart';

/// What was said on the call. Returns a [CallLog] to the caller, or null if
/// dismissed -- it performs no I/O itself.
class LogCallSheet extends StatefulWidget {
  const LogCallSheet({
    required this.invoiceId,
    required this.outstanding,
    super.key,
  });

  final int invoiceId;

  /// Pre-fills the promise amount, since a full-balance promise is the common
  /// case and retyping a lakh figure on a phone is error-prone.
  final double outstanding;

  @override
  State<LogCallSheet> createState() => _LogCallSheetState();
}

class _LogCallSheetState extends State<LogCallSheet> {
  final TextEditingController _remarks = TextEditingController();
  late final TextEditingController _promiseAmount = TextEditingController(
    text: widget.outstanding > 0
        ? widget.outstanding.toStringAsFixed(0)
        : '',
  );

  String _outcome = CallOutcomes.all.first;
  DateTime? _nextFollowup;
  DateTime? _promiseDate;

  bool get _isPromise => _outcome == CallOutcomes.promise;

  @override
  void dispose() {
    _remarks.dispose();
    _promiseAmount.dispose();
    super.dispose();
  }

  /// yyyy-MM-dd, which is what Laravel's `date` rule parses unambiguously.
  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pick({required bool promise}) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (promise ? _promiseDate : _nextFollowup) ??
          now.add(const Duration(days: 2)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }
    setState(() {
      if (promise) {
        _promiseDate = picked;
      } else {
        _nextFollowup = picked;
      }
    });
  }

  void _save() {
    Navigator.of(context).pop(
      CallLog(
        invoiceId: widget.invoiceId,
        outcome: _outcome,
        remarks: _remarks.text.trim(),
        nextFollowupOn: _nextFollowup == null ? null : _iso(_nextFollowup!),
        // Sent only for the outcome the server acts on, so a stray amount
        // left in the field cannot create a promise nobody made.
        promiseAmount: _isPromise
            ? double.tryParse(_promiseAmount.text.trim())
            : null,
        promiseDate:
            _isPromise && _promiseDate != null ? _iso(_promiseDate!) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        top: Dimensions.paddingSizeDefault,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            Dimensions.paddingSizeLarge,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log call',
              style:
                  robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
            Gaps.vDefault,
            Text(
              'Outcome',
              style:
                  robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
            Gaps.vEight,
            Wrap(
              spacing: Dimensions.paddingSizeEight,
              runSpacing: Dimensions.paddingSizeEight,
              children: [
                for (final String outcome in CallOutcomes.all)
                  ChoiceChip(
                    label: Text(outcome),
                    selected: _outcome == outcome,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _outcome = outcome),
                  ),
              ],
            ),
            Gaps.vDefault,
            TextField(
              controller: _remarks,
              maxLines: 3,
              maxLength: 5000,
              style: robotoRegular,
              decoration: InputDecoration(
                labelText: 'Remarks',
                hintText: 'What did they say?',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            ),
            _DateRow(
              label: 'Next follow-up',
              value: _nextFollowup,
              onPick: () => _pick(promise: false),
              onClear: () => setState(() => _nextFollowup = null),
            ),
            if (_isPromise) ...[
              const Divider(height: Dimensions.paddingSizeLarge),
              Text(
                'Promise',
                style:
                    robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
              Gaps.vEight,
              TextField(
                controller: _promiseAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: robotoRegular,
                decoration: InputDecoration(
                  labelText: 'Amount promised',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
              ),
              _DateRow(
                label: 'Promise date',
                value: _promiseDate,
                onPick: () => _pick(promise: true),
                onClear: () => setState(() => _promiseDate = null),
              ),
              Text(
                'Left blank, the server records the full balance in two days.',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            Gaps.vLarge,
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save follow-up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value == null
                ? label
                : '$label: ${value!.day}/${value!.month}/${value!.year}',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: value == null ? Theme.of(context).hintColor : null,
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'Clear',
            onPressed: onClear,
            icon: const Icon(
              Icons.close_rounded,
              size: Dimensions.iconSizeSmall,
            ),
          ),
        TextButton(onPressed: onPick, child: const Text('Pick')),
      ],
    );
  }
}
