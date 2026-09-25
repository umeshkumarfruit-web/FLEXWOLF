import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
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
  bool _remember = true;
  bool _loading = true;
  bool _offline = false;
  CustomerSession? _session;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _restore();
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
          .timeout(
            ref.read(appConfigProvider).shopify.hasCustomerAccountClient
                ? const Duration(seconds: 30)
                : const Duration(seconds: 5),
            onTimeout: () => null,
          );
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
          .login(email: '', password: '', rememberSession: _remember);
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
    final shopifyLogin = ref
        .watch(appConfigProvider)
        .shopify
        .hasCustomerAccountClient;
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
                  'Welcome back.',
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
          Text(
            shopifyLogin
                ? 'Continue with your FLEXWOLF account'
                : 'Customer account setup is pending',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            shopifyLogin
                ? 'Use the same account and order history as flexwolf.co.'
                : 'Shopping works as a guest. Sign-in will be available when the FLEXWOLF Shopify Customer Account connection is configured.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: _offline
                  ? AppOfflineState(onRetry: _login)
                  : AppErrorState(error: _error!, onRetry: _login),
            ),
          if (shopifyLogin) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep me signed in'),
              subtitle: const Text('On this device'),
              value: _remember,
              onChanged: (value) => setState(() => _remember = value),
            ),
            AppButton.primary(
              label: 'Sign in or create account',
              icon: Icons.login,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Shopping and checkout are also available without signing in.',
              textAlign: TextAlign.center,
            ),
          ] else
            const Text(
              'Your existing flexwolf.co account and orders will appear here after Shopify account setup.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
