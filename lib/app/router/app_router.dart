import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/app/router/root_navigator.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:flexwolf/features/admin/presentation/admin_login_screen.dart';
import 'package:flexwolf/features/admin/presentation/admin_route_guard.dart';
import 'package:flexwolf/features/home/app_destination_shell.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/home/app_shell.dart';
import 'package:flexwolf/features/checkout/presentation/cart_screen.dart';
import 'package:flexwolf/features/checkout/presentation/checkout_screen.dart';
import 'package:flexwolf/features/shop/presentation/product_page.dart';
import 'package:flexwolf/features/shop/presentation/shop_screen.dart';
import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final deepLinkParserProvider = Provider<DeepLinkParser>((ref) {
  return const DeepLinkParser();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final callback = Uri.tryParse(
        ref.read(appConfigProvider).shopify.customerAccountRedirectUri ?? '',
      );
      if (callback != null &&
          callback.hasScheme &&
          state.uri.path == callback.path &&
          ((state.uri.scheme == callback.scheme &&
                  state.uri.host == callback.host) ||
              (!state.uri.hasScheme && state.uri.host.isEmpty))) {
        return AppRoutes.account;
      }
      final resolution = ref
          .read(deepLinkParserProvider)
          .parse(state.uri.toString());
      if (state.uri.path == AppDeepLinks.fallback) return null;
      if (state.uri.path != resolution.route) return resolution.route;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRouteNames.home,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(section: AppSection.home),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shop,
                name: AppRouteNames.shop,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(section: AppSection.shop),
                ),
                routes: [
                  GoRoute(
                    path: 'products/:handle',
                    name: AppRouteNames.product,
                    pageBuilder: (context, state) => _shellPage(
                      state: state,
                      child: ProductPage(
                        handle: state.pathParameters['handle']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'collections/:handle',
                    name: AppRouteNames.collection,
                    pageBuilder: (context, state) => _shellPage(
                      state: state,
                      child: ResponsivePagePadding(
                        child: ShopScreen(
                          collectionHandle: state.pathParameters['handle'],
                        ),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'promotions/:id',
                    name: AppRouteNames.promotion,
                    pageBuilder: (context, state) => _shellPage(
                      state: state,
                      child: DeepLinkFallbackScreen(
                        title: 'Promotion unavailable',
                        message: 'This promotion is no longer available.',
                        onPrimary: () => context.go(AppRoutes.shop),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: AppRouteNames.search,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(section: AppSection.search),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wishlist,
                name: AppRouteNames.wishlist,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(
                    section: AppSection.wishlist,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.support,
                name: AppRouteNames.support,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(section: AppSection.support),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                name: AppRouteNames.account,
                pageBuilder: (context, state) => _shellPage(
                  state: state,
                  child: const AppDestinationShell(section: AppSection.account),
                ),
                routes: [
                  GoRoute(
                    path: 'profile',
                    name: AppRouteNames.customerProfile,
                    pageBuilder: (context, state) => _shellPage(
                      state: state,
                      child: const AppDestinationShell(
                        section: AppSection.account,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'orders/:id',
                    name: AppRouteNames.orderDetails,
                    pageBuilder: (context, state) => _shellPage(
                      state: state,
                      child: const AppDestinationShell(
                        section: AppSection.account,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        name: AppRouteNames.adminLogin,
        pageBuilder: (context, state) =>
            _shellPage(state: state, child: const AdminLoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: AppRouteNames.admin,
        pageBuilder: (context, state) => _shellPage(
          state: state,
          child: const AdminRouteGuard(child: AdminDashboardScreen()),
        ),
      ),
      GoRoute(
        path: AppDeepLinks.cart,
        name: AppRouteNames.cart,
        pageBuilder: (context, state) =>
            _shellPage(state: state, child: const CartScreen()),
      ),
      GoRoute(
        path: AppDeepLinks.checkout,
        name: AppRouteNames.checkout,
        pageBuilder: (context, state) =>
            _shellPage(state: state, child: const CheckoutScreen()),
      ),
      GoRoute(
        path: AppDeepLinks.fallback,
        name: AppRouteNames.deepLinkFallback,
        pageBuilder: (context, state) => _shellPage(
          state: state,
          child: DeepLinkFallbackScreen(
            title: 'Link unavailable',
            message: _fallbackMessage(state.uri.queryParameters['reason']),
            onPrimary: () => context.go(AppRoutes.home),
          ),
        ),
      ),
    ],
  );
});

class DeepLinkNavigator {
  DeepLinkNavigator({
    required this._parser,
    required this._analytics,
    required this._openRoute,
  });

  final DeepLinkParser _parser;
  final AnalyticsGateway _analytics;
  final void Function(String route) _openRoute;
  String? _lastRoute;

  Future<void> open(String link, {bool fromNotification = false}) async {
    final resolution = _parser.parse(link);
    final route = resolution.route;
    if (_lastRoute == route) return;
    _lastRoute = route;
    await _analytics.track(
      AnalyticsEvent(
        name: AppAnalyticsEvents.deepLinkOpened,
        parameters: {'destination': resolution.destination.name},
      ),
    );
    if (fromNotification) {
      await _analytics.track(
        AnalyticsEvent(
          name: AppAnalyticsEvents.notificationNavigation,
          parameters: {'destination': resolution.destination.name},
        ),
      );
    }
    _openRoute(route);
    // ignore: deprecated_member_use
    SemanticsService.announce('Destination loaded', TextDirection.ltr);
    await _analytics.track(
      AnalyticsEvent(
        name: AppAnalyticsEvents.destinationLoaded,
        parameters: {'destination': resolution.destination.name},
      ),
    );
  }
}

CustomTransitionPage<void> _shellPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppDurations.fast,
    reverseTransitionDuration: AppDurations.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.standard),
        child: child,
      );
    },
  );
}

class DeepLinkFallbackScreen extends StatelessWidget {
  const DeepLinkFallbackScreen({
    required this.title,
    required this.message,
    required this.onPrimary,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppErrorState(
            error: AppException(
              kind: AppErrorKind.unavailable,
              message: message,
              code: 'deep_link_unavailable',
              isRetryable: true,
            ),
            onRetry: onPrimary,
          ),
        ),
      ),
    );
  }
}

String _fallbackMessage(String? reason) {
  return switch (reason) {
    'missing_product' => 'This product could not be found.',
    'deleted_collection' => 'This collection could not be found.',
    'invalid_order' => 'This order could not be opened.',
    'checkout_route_pending' => 'Checkout navigation is not configured yet.',
    'cart_route_pending' => 'Cart navigation is not configured yet.',
    _ => 'This link is no longer available.',
  };
}
