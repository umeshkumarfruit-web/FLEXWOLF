import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopifyConfigProvider = Provider<ShopifyConfig>((ref) {
  throw StateError('ShopifyConfig must be provided by AppConfig.');
});

ShopifyConfig defaultShopifyConfigFor(
  AppEnvironment environment, {
  String shopDomain = '',
  String? publicStorefrontAccessToken,
  String? customerAccountClientId,
  String? customerAccountRedirectUri,
  String? customerAccountAccessToken,
  DateTime? customerAccountTokenExpiresAt,
}) {
  return ShopifyConfig(
    environment: environment,
    shopDomain: shopDomain,
    publicStorefrontAccessToken: publicStorefrontAccessToken,
    storefrontApiVersion: ShopifyApiVersions.storefront,
    customerAccountApiVersion: ShopifyApiVersions.customerAccount,
    adminApiVersion: ShopifyApiVersions.admin,
    customerAccountClientId: customerAccountClientId,
    customerAccountRedirectUri: customerAccountRedirectUri,
    customerAccountAccessToken: customerAccountAccessToken,
    customerAccountTokenExpiresAt: customerAccountTokenExpiresAt,
  );
}
