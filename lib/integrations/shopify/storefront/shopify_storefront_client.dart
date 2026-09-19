import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';

class ShopifyStorefrontClient {
  ShopifyStorefrontClient({
    required this.shopifyConfig,
    required this.appConfig,
    required this.logger,
    ShopifyGraphqlClient? graphqlClient,
  }) : _graphqlClient =
           graphqlClient ??
           ShopifyGraphqlHttpClient(
             endpoint: shopifyConfig.storefrontGraphqlEndpoint(),
             config: appConfig,
             logger: logger,
             headersBuilder: () => storefrontHeaders(shopifyConfig),
           );

  final ShopifyConfig shopifyConfig;
  final AppConfig appConfig;
  final AppLogger logger;
  final ShopifyGraphqlClient _graphqlClient;

  Future<ShopifyGraphqlResponse> query(ShopifyGraphqlRequest request) {
    _ensureConfigured();
    return _graphqlClient.query(request);
  }

  void _ensureConfigured() {
    if (!shopifyConfig.hasShopDomain) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Shopify shop domain is not configured.',
        code: 'shopify_storefront_not_configured',
      );
    }
  }
}

Map<String, String> storefrontHeaders(ShopifyConfig config) {
  return <String, String>{
    if (config.hasPublicStorefrontToken)
      'X-Shopify-Storefront-Access-Token': config.publicStorefrontAccessToken!,
  };
}

enum StorefrontAuthenticationMode { tokenless, publicStorefrontToken }

class StorefrontOperationAuthRule {
  const StorefrontOperationAuthRule({
    required this.operation,
    required this.mode,
  });

  final String operation;
  final StorefrontAuthenticationMode mode;
}

const storefrontOperationAuthRules = <StorefrontOperationAuthRule>[
  StorefrontOperationAuthRule(
    operation: 'products',
    mode: StorefrontAuthenticationMode.tokenless,
  ),
  StorefrontOperationAuthRule(
    operation: 'collections',
    mode: StorefrontAuthenticationMode.tokenless,
  ),
  StorefrontOperationAuthRule(
    operation: 'search',
    mode: StorefrontAuthenticationMode.tokenless,
  ),
  StorefrontOperationAuthRule(
    operation: 'cart read/write',
    mode: StorefrontAuthenticationMode.tokenless,
  ),
  StorefrontOperationAuthRule(
    operation: 'product tags',
    mode: StorefrontAuthenticationMode.publicStorefrontToken,
  ),
  StorefrontOperationAuthRule(
    operation: 'metafields',
    mode: StorefrontAuthenticationMode.publicStorefrontToken,
  ),
  StorefrontOperationAuthRule(
    operation: 'metaobjects',
    mode: StorefrontAuthenticationMode.publicStorefrontToken,
  ),
  StorefrontOperationAuthRule(
    operation: 'menus/navigation',
    mode: StorefrontAuthenticationMode.publicStorefrontToken,
  ),
];
