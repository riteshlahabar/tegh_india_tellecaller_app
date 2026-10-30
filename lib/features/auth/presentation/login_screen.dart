import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/custom_theme_colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../app/theme/gaps.dart';
import '../../../app/theme/styles.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import 'session_view_model.dart';

/// Username or email, plus password -- the same two fields `POST /login`
/// takes. The router sends the user away from here the moment the session
/// flips to signed in, so this screen never navigates.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;

  /// Whole-form failure, e.g. wrong password or no connection.
  String? _error;

  /// Per-field messages from Laravel's 422 body.
  Map<String, List<String>> _fieldErrors = const {};

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });

    try {
      await ref.read(sessionProvider.notifier).signIn(
            username: _username.text.trim(),
            password: _password.text,
          );
      // No navigation here: the router's redirect owns where to go next.
    } on ValidationException catch (error) {
      _fail(error.message, error.errors);
    } on ApiException catch (error) {
      _fail(error.message, const {});
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _fail(String message, Map<String, List<String>> errors) {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = message;
      _fieldErrors = errors;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A session that expired mid-use explains itself here.
    final SessionState session = ref.watch(sessionProvider);
    final String? expired =
        session is SessionSignedOut ? session.message : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Masthead(),
                    Gaps.vExtraLarge,
                    if (_error != null)
                      _Banner(message: _error!, tone: AppPalette.overdue)
                    else if (expired != null)
                      _Banner(message: expired, tone: AppPalette.dueToday),
                    if (_error != null || expired != null) Gaps.vDefault,
                    _Field(
                      controller: _username,
                      label: 'Username or email',
                      hint: 'aakanksha',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      errorText: _fieldErrors['username']?.first,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Enter your username or email'
                              : null,
                    ),
                    Gaps.vDefault,
                    _Field(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: _fieldErrors['password']?.first,
                      onSubmitted: (_) => _submit(),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter your password'
                          : null,
                      trailing: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: Dimensions.iconSizeDefault,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    Gaps.vLarge,
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                    ),
                    Gaps.vDefault,
                    Text(
                      'Ask your administrator if you do not have a login.',
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: context.customThemeColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        Gaps.vDefault,
        Text(
          AppConfig.appName,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
        ),
        Gaps.vTine,
        Text(
          'Sign in to work your outstanding book',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: context.customThemeColors.subtitle,
          ),
        ),
      ],
    );
  }
}

/// Whole-form message. Red for a failure, amber for an expired session.
class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.tone});

  final String message;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.radiusSeven),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: Dimensions.iconSizeSmall, color: tone),
          Gaps.hEight,
          Expanded(
            child: Text(
              message,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.hint,
    this.obscure = false,
    this.errorText,
    this.trailing,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final String? hint;
  final bool obscure;
  final String? errorText;
  final Widget? trailing;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: robotoRegular,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, size: Dimensions.iconSizeDefault),
        suffixIcon: trailing,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
    );
  }
}
