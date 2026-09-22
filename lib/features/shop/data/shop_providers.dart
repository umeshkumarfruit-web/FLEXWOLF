import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/checkout/data/shopify_checkout_coordinator.dart';
import 'package:flexwolf/features/checkout/data/native_checkout_kit_bridge.dart';
import 'package:flexwolf/features/shop/data/shopify_shop_repositories.dart';
import 'package:flexwolf/features/shop/data/public_storefront_catalog_repository.dart';
import 'package:flexwolf/features/shop/data/shopify_cart_repository.dart';
import 'package:flexwolf/features/shop/data/public_cart_repository.dart';
import 'package:flexwolf/features/shop/data/cart_controller.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';
import 'package:flexwolf/integrations/shopify/storefront/shopify_storefront_client.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final shopify = config.shopify;
  if (!shopify.hasPublicStorefrontToken) {
    return PublicStorefrontCatalogRepository();
  }
  return ShopifyProductRepository(
    LazyStorefrontGraphqlClient(
      shopifyConfig: shopify,
      appConfig: config,
      logger: ref.watch(loggerProvider),
    ),
  );
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.shopify.hasPublicStorefrontToken) {
    return PublicStorefrontCatalogRepository();
  }
  return ShopifyCollectionRepository(
    LazyStorefrontGraphqlClient(
      shopifyConfig: config.shopify,
      appConfig: config,
      logger: ref.watch(loggerProvider),
    ),
  );
});
final shopCollectionConfigProvider = Provider<List<ShopCollectionTab>>((ref) {
  return const <ShopCollectionTab>[
    ShopCollectionTab(id: 'all', label: 'All Products'),
  ];
});

final shopCatalogCacheProvider = Provider<ShopCatalogCache>((ref) {
  return ShopCatalogCache(
    policy: CatalogCachePolicy(
      maxEntries: 16,
      staleAfter: const Duration(minutes: 15),
      environmentKey: ref.watch(appConfigProvider).environment.name,
    ),
  );
});

class ShopCollectionTab {
  const ShopCollectionTab({
    required this.id,
    required this.label,
    this.collectionHandle,
  });

  final String id;
  final String label;
  final String? collectionHandle;

  bool get loadsAllProducts => collectionHandle == null;
}

class ShopCatalogCache {
  ShopCatalogCache({required this.policy});

  final CatalogCachePolicy policy;
  final Map<String, CachedPage<ProductSummary>> _pages =
      <String, CachedPage<ProductSummary>>{};
  CachedPage<ProductCollection>? collections;

  CachedPage<ProductSummary>? read(String key) {
    final page = _pages[key];
    if (page == null) return null;
    if (page.isStale(policy, DateTime.now())) {
      _pages.remove(key);
      return null;
    }
    return page;
  }

  void write(String key, CachedPage<ProductSummary> page) {
    if (_pages.length >= policy.maxEntries && !_pages.containsKey(key)) {
      _pages.remove(_pages.keys.first);
    }
    _pages[key] = page;
  }
}

class LazyStorefrontGraphqlClient implements ShopifyGraphqlClient {
  LazyStorefrontGraphqlClient({
    required this.shopifyConfig,
    required this.appConfig,
    required this.logger,
  });

  final ShopifyConfig shopifyConfig;
  final AppConfig appConfig;
  final AppLogger logger;
  ShopifyGraphqlClient? _client;

  @override
  Future<ShopifyGraphqlResponse> query(
    ShopifyGraphqlRequest request, {
    CancellationToken? cancelToken,
  }) {
    if (!shopifyConfig.hasShopDomain) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Shopify shop domain is not configured.',
        code: 'shopify_storefront_not_configured',
        isRetryable: true,
      );
    }
    final client = _client ??= ShopifyGraphqlHttpClient(
      endpoint: shopifyConfig.storefrontGraphqlEndpoint(),
      config: appConfig,
      logger: logger,
      headersBuilder: () => storefrontHeaders(shopifyConfig),
    );
    return client.query(request, cancelToken: cancelToken);
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.shopify.hasPublicStorefrontToken) {
    return PublicCartRepository(ref.watch(localStorageProvider));
  }
  return ShopifyCartRepository(
    LazyStorefrontGraphqlClient(
      shopifyConfig: config.shopify,
      appConfig: config,
      logger: ref.watch(loggerProvider),
    ),
  );
});

final cartControllerProvider = Provider<CartController>((ref) {
  final controller = CartController(
    repository: ref.watch(cartRepositoryProvider),
    storage: ref.watch(localStorageProvider),
  );
  ref.onDispose(controller.dispose);
  controller.restore();
  return controller;
});

final checkoutKitBridgeProvider = Provider<MethodChannelCheckoutKitBridge>(
  (ref) => const MethodChannelCheckoutKitBridge(),
);

final checkoutPresenterProvider = Provider<CheckoutPresenter>((ref) {
  return AnalyticsCheckoutPresenter(
    presenter: ref.watch(checkoutKitBridgeProvider),
    analytics: ref.watch(analyticsGatewayProvider),
  );
});

final checkoutCoordinatorProvider = Provider<CheckoutCoordinator>((ref) {
  return ShopifyCheckoutCoordinator(
    cartRepository: ref.watch(cartRepositoryProvider),
    presenter: ref.watch(checkoutPresenterProvider),
  );
});

class AnalyticsCheckoutPresenter implements CheckoutPresenter {
  const AnalyticsCheckoutPresenter({
    required CheckoutPresenter presenter,
    required AnalyticsGateway analytics,
  }) : this._(presenter, analytics);

  const AnalyticsCheckoutPresenter._(this._presenter, this._analytics);

  final CheckoutPresenter _presenter;
  final AnalyticsGateway _analytics;

  @override
  Future<CheckoutResult> present(CheckoutSessionRequest request) async {
    await _analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.checkoutStarted),
    );
    if (request.review?.discountCodes.isNotEmpty ?? false) {
      await _analytics.track(
        const AnalyticsEvent(name: AppAnalyticsEvents.discountApplied),
      );
    }
    final result = await _presenter.present(request);
    if (result.isSuccessfulPurchase) {
      await _analytics.track(
        const AnalyticsEvent(name: AppAnalyticsEvents.checkoutCompleted),
      );
    } else if (result.status == CheckoutResultStatus.cancelled ||
        result.status == CheckoutResultStatus.closed) {
      await _analytics.track(
        const AnalyticsEvent(name: AppAnalyticsEvents.checkoutAbandoned),
      );
    }
    return result;
  }
}
