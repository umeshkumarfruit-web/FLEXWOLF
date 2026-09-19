import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/security/security_policy.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('security policy accepts only HTTPS URLs with hosts', () {
    expect(SecurityPolicy.isHttpsUrl('https://cdn.flexwolf.co/a.jpg'), isTrue);
    expect(SecurityPolicy.isHttpsUrl('http://cdn.flexwolf.co/a.jpg'), isFalse);
    expect(SecurityPolicy.isHttpsUrl('https:///a.jpg'), isFalse);
  });

  test('Shopify configuration rejects URL-shaped shop domains', () {
    const config = ShopifyConfig(
      environment: AppEnvironment.production,
      shopDomain: 'https://flexwolf.myshopify.com',
      storefrontApiVersion: ShopifyApiVersions.storefront,
      customerAccountApiVersion: ShopifyApiVersions.customerAccount,
      adminApiVersion: ShopifyApiVersions.admin,
    );

    expect(config.storefrontGraphqlEndpoint, throwsA(isA<AppException>()));
  });

  test('Shopify GraphQL transport rejects non-HTTPS endpoints', () {
    expect(
      () => ShopifyGraphqlHttpClient(
        endpoint: Uri.parse('http://flexwolf.myshopify.com/api/graphql.json'),
        config: _testConfig(),
        logger: AppLogger(_testConfig()),
        headersBuilder: () => const <String, String>{},
      ),
      throwsA(isA<AppException>()),
    );
  });
}

AppConfig _testConfig() {
  return AppConfig(
    environment: AppEnvironment.production,
    appName: 'FLEXWOLF',
    backendBaseUrl: 'https://api.flexwolf.invalid',
    shopify: const ShopifyConfig(
      environment: AppEnvironment.production,
      shopDomain: 'flexwolf.myshopify.com',
      storefrontApiVersion: ShopifyApiVersions.storefront,
      customerAccountApiVersion: ShopifyApiVersions.customerAccount,
      adminApiVersion: ShopifyApiVersions.admin,
    ),
    featureFlags: const FeatureFlags(enableDiagnostics: false),
    networkTimeout: const Duration(seconds: 15),
    allowsProductionSideEffects: true,
    allowsVerboseLogging: false,
    firebase: const FirebaseEnvironmentConfig(),
    deepLinks: const DeepLinkConfig(),
    release: const ReleaseMetadata(),
  );
}
