import 'package:flutter/material.dart';

import '../../../../app/theme/dimensions.dart';
import '../../../../app/theme/gaps.dart';
import '../../../../app/theme/styles.dart';
import '../../../../shared/domain/invoice_summary.dart';

/// An email reminder. Returns the composed message, or null if dismissed.
///
/// Unlike WhatsApp there is no server-rendered template endpoint for email,
/// so the subject and opening are composed here from the invoice's own
/// fields -- all of which come from the server.
class EmailSheet extends StatefulWidget {
  const EmailSheet({required this.invoice, super.key});

  final InvoiceSummary invoice;

  @override
  State<EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<EmailSheet> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  late final TextEditingController _to =
      TextEditingController(text: widget.invoice.email ?? '');
  final TextEditingController _cc = TextEditingController();
  late final TextEditingController _subject = TextEditingController(
    text: 'Payment reminder — invoice ${widget.invoice.invoiceNo}',
  );
  late final TextEditingController _body = TextEditingController(
    text: _defaultBody(),
  );

  String _defaultBody() {
    final InvoiceSummary invoice = widget.invoice;
    final String due = invoice.dueDateLabel == null
        ? ''
        : ' which was due on ${invoice.dueDateLabel}';

    return 'Dear ${invoice.party},\n\n'
        'This is a gentle reminder about invoice ${invoice.invoiceNo}$due. '
        'An amount of ${invoice.outstandingInr} is outstanding against it.\n\n'
        'We would be grateful if you could arrange payment at your earliest '
        'convenience. Please ignore this message if payment has already been '
        'made.\n\n'
        'Thank you,\nTegh Cables India Pvt. Ltd.';
  }

  @override
  void dispose() {
    _to.dispose();
    _cc.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _send() {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop((
      toEmail: _to.text.trim(),
      cc: _cc.text.trim(),
      subject: _subject.text.trim(),
      body: _body.text.trim(),
    ));
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
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email reminder',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                ),
              ),
              Gaps.vDefault,
              _Field(
                controller: _to,
                label: 'To',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final String text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Enter an email address';
                  }
                  // Deliberately loose: the server validates properly with
                  // Laravel's `email` rule, and a strict regex here would
                  // reject addresses that are actually fine.
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'That does not look like an email address';
                  }
                  return null;
                },
              ),
              Gaps.vSmall,
              _Field(
                controller: _cc,
                label: 'Cc (optional)',
                keyboardType: TextInputType.emailAddress,
              ),
              Gaps.vSmall,
              _Field(
                controller: _subject,
                label: 'Subject',
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a subject'
                    : null,
              ),
              Gaps.vSmall,
              _Field(
                controller: _body,
                label: 'Message',
                maxLines: 8,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a message' : null,
              ),
              Gaps.vDefault,
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: robotoRegular,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
    );
  }
}
