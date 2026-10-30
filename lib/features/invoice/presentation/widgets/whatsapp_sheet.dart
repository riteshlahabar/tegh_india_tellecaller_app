import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../domain/invoice_repository.dart';
import '../invoice_view_model.dart';

/// Picks a template, shows the text the **server** rendered, and lets it be
/// edited before sending.
///
/// The wording is never composed here: the web CRM owns the templates, and a
/// second copy in Dart would drift the moment one is reworded.
class WhatsappSheet extends ConsumerStatefulWidget {
  const WhatsappSheet({required this.invoiceId, super.key});

  final int invoiceId;

  @override
  ConsumerState<WhatsappSheet> createState() => _WhatsappSheetState();
}

class _WhatsappSheetState extends ConsumerState<WhatsappSheet> {
  final TextEditingController _message = TextEditingController();

  String _template = WhatsappTemplates.defaultTemplate;

  /// True once the telecaller has typed, so re-rendering a template does not
  /// silently discard their edit.
  bool _edited = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<String> preview = ref.watch(
      whatsappPreviewProvider((invoiceId: widget.invoiceId, template: _template)),
    );

    // Fill the box from the server's render, unless the user has edited it.
    preview.whenData((text) {
      if (!_edited && _message.text != text) {
        _message.text = text;
      }
    });

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
              'WhatsApp reminder',
              style:
                  robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
            Gaps.vDefault,
            Wrap(
              spacing: Dimensions.paddingSizeEight,
              runSpacing: Dimensions.paddingSizeEight,
              children: [
                for (final String template in WhatsappTemplates.all)
                  ChoiceChip(
                    label: Text(template),
                    selected: _template == template,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _template = template;
                      // Picking a template is an explicit request for its
                      // wording, so the edit guard resets.
                      _edited = false;
                    }),
                  ),
              ],
            ),
            Gaps.vDefault,
            if (preview.isLoading && _message.text.isEmpty)
              const Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (preview.hasError && _message.text.isEmpty)
              Text(
                '${preview.error}',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else
              TextField(
                controller: _message,
                maxLines: 8,
                maxLength: 5000,
                style: robotoRegular,
                onChanged: (_) => _edited = true,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
              ),
            Gaps.vSmall,
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _message.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          (template: _template, message: _message.text.trim()),
                        ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
