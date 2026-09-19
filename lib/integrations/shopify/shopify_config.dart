import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/security/security_policy.dart';

abstract final class ShopifyApiVersions {
  static const storefront = '2026-07';
  static const customerAccount = '2026-07';
  static const admin = '2026-07';
}

class ShopifyConfig {
  const ShopifyConfig({
    required this.environment,
    required this.shopDomain,
    required this.storefrontApiVersion,
    required this.customerAccountApiVersion,
    required this.adminApiVersion,
    this.publicStorefrontAccessToken,
    this.customerAccountClientId,
    this.customerAccountRedirectUri,
    this.customerAccountAccessToken,
    this.customerAccountTokenExpiresAt,
  });

  final AppEnvironment environment;
  final String shopDomain;
  final String storefrontApiVersion;
  final String customerAccountApiVersion;
  final String adminApiVersion;
  final String? publicStorefrontAccessToken;
  final String? customerAccountClientId;
  final String? customerAccountRedirectUri;
  final String? customerAccountAccessToken;
  final DateTime? customerAccountTokenExpiresAt;

  bool get hasShopDomain => shopDomain.trim().isNotEmpty;
  bool get hasPublicStorefrontToken =>
      publicStorefrontAccessToken?.trim().isNotEmpty ?? false;
  bool get hasCustomerAccountClient =>
      customerAccountClientId?.trim().isNotEmpty ?? false;
  bool get hasCustomerAccountAccessToken =>
      customerAccountAccessToken?.trim().isNotEmpty ?? false;

  Uri storefrontGraphqlEndpoint() {
    if (!hasShopDomain) {
      throw StateError('Shopify shop domain is not configured.');
    }

    final host = SecurityPolicy.requireHostName(
      shopDomain,
      context: 'Shopify shop domain',
    );
    return SecurityPolicy.requireHttpsUri(
      Uri.https(host, '/api/$storefrontApiVersion/graphql.json'),
      context: 'Shopify Storefront endpoint',
    );
  }

  Uri customerAccountOpenIdDiscoveryEndpoint() {
    if (!hasShopDomain) {
      throw StateError('Shopify shop domain is not configured.');
    }

    final host = SecurityPolicy.requireHostName(
      shopDomain,
      context: 'Shopify shop domain',
    );
    return SecurityPolicy.requireHttpsUri(
      Uri.https(host, '/.well-known/openid-configuration'),
      context: 'Shopify Customer Account OpenID endpoint',
    );
  }

  Uri customerAccountApiDiscoveryEndpoint() {
    if (!hasShopDomain) {
      throw StateError('Shopify shop domain is not configured.');
    }

    final host = SecurityPolicy.requireHostName(
      shopDomain,
      context: 'Shopify shop domain',
    );
    return SecurityPolicy.requireHttpsUri(
      Uri.https(host, '/.well-known/customer-account-api'),
      context: 'Shopify Customer Account API endpoint',
    );
  }
}
