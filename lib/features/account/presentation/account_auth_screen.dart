import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_form_field.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/presentation/customer_profile_screen.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountAuthScreen extends ConsumerStatefulWidget {
  const AccountAuthScreen({super.key});
  @override
  ConsumerState<AccountAuthScreen> createState() => _AccountAuthScreenState();
}

class _AccountAuthScreenState extends ConsumerState<AccountAuthScreen> {
  bool _signUp = false;
  bool _remember = true;
  bool _loading = true;
  bool _offline = false;
  CustomerSession? _session;
  AppException? _error;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final connectivity = await ref
          .read(connectivityServiceProvider)
          .current();
      _offline = connectivity.quality == ConnectivityQuality.offline;
      final session = await ref
          .read(customerSessionProvider.future)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (session != null) {
        _session = session;
        _track(AppAnalyticsEvents.sessionRestored);
      }
    } catch (error) {
      _error = _mapAuthError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final connectivity = await ref
          .read(connectivityServiceProvider)
          .current();
      _offline = connectivity.quality == ConnectivityQuality.offline;
      if (_offline) {
        throw const AppException(
          kind: AppErrorKind.network,
          message: 'You are offline. Check your connection and try again.',
          code: 'customer_auth_offline',
          isRetryable: true,
        );
      }
      _session = await ref
          .read(customerAccountRepositoryProvider)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
            rememberSession: _remember,
            createAccount: _signUp,
          );
      ref.invalidate(customerSessionProvider);
      _track(AppAnalyticsEvents.loginSuccess);
    } catch (error) {
      _error = _mapAuthError(error);
      _track(AppAnalyticsEvents.loginFailure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(customerAccountRepositoryProvider).logout();
      try {
        await ref.read(cartControllerProvider).clear();
      } catch (_) {
        // Signing out must still complete if a stale remote cart cannot clear.
      }
      _session = null;
      ref.invalidate(customerSessionProvider);
      _track(AppAnalyticsEvents.logout);
    } catch (error) {
      _error = _mapAuthError(error);
      // Local sign-out may have completed even if browser logout failed.
      try {
        _session = await ref
            .read(customerAccountRepositoryProvider)
            .restoreSession();
      } catch (_) {
        // Preserve the visible session if secure storage could not be checked.
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AppException _mapAuthError(Object error) {
    if (error is AppException) return error;
    return mapUnknownException(error);
  }

  void _track(String name) {
    ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Semantics(
          label: 'Checking customer session',
          liveRegion: true,
          child: AppSkeletonLoader(width: 220, height: 120),
        ),
      );
    }
    if (_session != null) {
      return Column(
        children: [
          if (_error != null) AppErrorState(error: _error!, onRetry: _logout),
          Expanded(
            child: CustomerProfileScreen(session: _session!, onLogout: _logout),
          ),
        ],
      );
    }
    return Semantics(
      label: 'Customer authentication',
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Text('Account', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.md),
          if (_offline) ...[
            AppNetworkStatusBanner(
              message:
                  'You are offline. Connect to sign in or create an account.',
              status: AppNetworkStatus.offline,
              actionLabel: 'Retry',
              onAction: _restore,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline, color: Colors.white, size: 36),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _signUp ? 'Join the pack.' : 'Welcome back.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Your favourites. Your orders. Your FLEXWOLF.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Sign in')),
              ButtonSegment(value: true, label: Text('Create account')),
            ],
            selected: {_signUp},
            onSelectionChanged: (value) => setState(() {
              _signUp = value.single;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _signUp
                ? 'Your next favourite starts here'
                : 'Sign in to your account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _signUp
                ? 'Create your FLEXWOLF account securely with email and password.'
                : 'Sign in securely with your FLEXWOLF email and password.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _offline
                  ? AppOfflineState(onRetry: _login)
                  : AppErrorState(error: _error!, onRetry: _login),
            ),
          _LoginForm(
            signUp: _signUp,
            remember: _remember,
            emailController: _emailController,
            passwordController: _passwordController,
            onRememberChanged: (value) => setState(() => _remember = value),
            onLogin: _login,
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.signUp,
    required this.remember,
    required this.emailController,
    required this.passwordController,
    required this.onRememberChanged,
    required this.onLogin,
  });

  final bool signUp;
  final bool remember;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutofillGroup(
            child: Column(
              children: [
                AppFormField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  label: 'Password',
                  controller: passwordController,
                  textInputAction: TextInputAction.done,
                  autofillHints: [
                    signUp ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  obscureText: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep me signed in'),
            subtitle: const Text('On this device'),
            value: remember,
            onChanged: onRememberChanged,
          ),
          AppButton.primary(
            label: signUp ? 'Create FLEXWOLF account' : 'Login with FLEXWOLF',
            icon: signUp ? Icons.person_add_alt_1 : Icons.login,
            semanticLabel: signUp
                ? 'Create FLEXWOLF customer account'
                : 'Login with FLEXWOLF customer account',
            onPressed: onLogin,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'A FLEXWOLF account is required to add items, use your bag, and checkout.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
