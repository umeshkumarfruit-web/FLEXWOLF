import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/app/router/app_router.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/core/utils/environment_guard.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flexwolf/integrations/shopify/storefront/shopify_storefront_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('development config disables production side effects', () {
    final config = AppConfig.forEnvironment(AppEnvironment.development);

    expect(config.environment, AppEnvironment.development);
    expect(config.allowsProductionSideEffects, isFalse);
    expect(config.allowsVerboseLogging, isTrue);
  });

  test('staging config is distinct from development and production', () {
    final development = AppConfig.forEnvironment(AppEnvironment.development);
    final staging = AppConfig.forEnvironment(AppEnvironment.staging);
    final production = AppConfig.forEnvironment(AppEnvironment.production);

    expect(staging.environment, AppEnvironment.staging);
    expect(staging.appName, isNot(development.appName));
    expect(staging.appName, isNot(production.appName));
    expect(staging.allowsProductionSideEffects, isFalse);
  });

  test('production config is explicitly production scoped', () {
    final config = AppConfig.forEnvironment(AppEnvironment.production);

    expect(config.environment.isProduction, isTrue);
    expect(config.allowsProductionSideEffects, isTrue);
    expect(config.allowsVerboseLogging, isFalse);
  });

  test(
    'environment guard blocks production side effects outside production',
    () {
      final config = AppConfig.forEnvironment(AppEnvironment.development);

      expect(
        () => requireProductionSideEffectsAllowed(config),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('router provider creates a GoRouter', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.forEnvironment(AppEnvironment.development),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appRouterProvider), isA<GoRouter>());
  });

  test(
    'network foundation fails safely until concrete client exists',
    () async {
      final config = AppConfig.forEnvironment(AppEnvironment.development);
      final client = NoopApiClient(config);

      await expectLater(
        client.send(const ApiRequest(method: ApiMethod.get, path: '/health')),
        throwsA(isA<AppException>()),
      );
    },
  );

  test(
    'secure and local storage abstractions store only caller-provided values',
    () async {
      final secureStorage = InMemorySecureStorage();
      final localStorage = InMemoryLocalStorage();

      await secureStorage.write('session_token_reference', 'reference-only');
      await localStorage.writeBool('onboarding_seen', true);

      expect(
        await secureStorage.read('session_token_reference'),
        'reference-only',
      );
      expect(await localStorage.readBool('onboarding_seen'), isTrue);
    },
  );

  test('Shopify config records selected stable API versions', () {
    final config = AppConfig.forEnvironment(AppEnvironment.development).shopify;

    expect(config.storefrontApiVersion, ShopifyApiVersions.storefront);
    expect(
      config.customerAccountApiVersion,
      ShopifyApiVersions.customerAccount,
    );
    expect(config.adminApiVersion, ShopifyApiVersions.admin);
    expect(config.hasShopDomain, isTrue);
    expect(config.shopDomain, 'flexwolf-co.myshopify.com');
  });

  test('Shopify endpoint builders fail closed without a shop domain', () {
    const config = ShopifyConfig(
      environment: AppEnvironment.development,
      shopDomain: '',
      storefrontApiVersion: ShopifyApiVersions.storefront,
      customerAccountApiVersion: ShopifyApiVersions.customerAccount,
      adminApiVersion: ShopifyApiVersions.admin,
    );

    expect(config.storefrontGraphqlEndpoint, throwsStateError);
    expect(config.customerAccountOpenIdDiscoveryEndpoint, throwsStateError);
    expect(config.customerAccountApiDiscoveryEndpoint, throwsStateError);
  });

  test('Storefront public token header is only included when configured', () {
    final noTokenConfig = AppConfig.forEnvironment(AppEnvironment.development)
        .shopify;
    final tokenConfig = ShopifyConfig(
      environment: AppEnvironment.development,
      shopDomain: 'example.myshopify.com',
      storefrontApiVersion: ShopifyApiVersions.storefront,
      customerAccountApiVersion: ShopifyApiVersions.customerAccount,
      adminApiVersion: ShopifyApiVersions.admin,
      publicStorefrontAccessToken: 'public-token-reference',
    );

    expect(storefrontHeaders(noTokenConfig), isEmpty);
    expect(
      storefrontHeaders(tokenConfig),
      containsPair(
        'X-Shopify-Storefront-Access-Token',
        'public-token-reference',
      ),
    );
  });
}
