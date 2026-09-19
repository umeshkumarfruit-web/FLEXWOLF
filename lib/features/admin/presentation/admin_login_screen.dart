import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  AppException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Semantics(
                label: 'Admin login',
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(child: FlexwolfLogo()),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Admin Portal',
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_error != null) ...[
                        AppErrorState(error: _error!, onRetry: _submit),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextFormField(
                        controller: _email,
                        autofillHints: const [AutofillHints.username],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Admin email',
                        ),
                        validator: (value) {
                          final normalized = value?.trim() ?? '';
                          if (normalized.isEmpty || !normalized.contains('@')) {
                            return 'Enter a valid admin email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) => (value ?? '').isEmpty
                            ? 'Enter your password'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.primary(
                        label: _submitting ? 'Signing in' : 'Sign in',
                        icon: Icons.lock_open_outlined,
                        semanticLabel: 'Sign in to admin portal',
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(adminAuthRepositoryProvider)
          .login(
            AdminCredentials(
              email: _email.text.trim(),
              password: _password.text,
            ),
          );
      ref.invalidate(adminSessionProvider);
      await ref
          .read(analyticsGatewayProvider)
          .track(const AnalyticsEvent(name: AppAnalyticsEvents.adminLogin));
      if (mounted) context.go(AppRoutes.admin);
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
