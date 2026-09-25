import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/integrations/shopify/shopify_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('environment names resolve safely', () {
    expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
    expect(AppEnvironment.fromName('production'), AppEnvironment.production);
    expect(AppEnvironment.fromName('unknown'), AppEnvironment.development);
  });

  test('config exposes safe environment and release metadata defaults', () {
    final config = AppConfig.forEnvironment(AppEnvironment.production);

    expect(config.backendBaseUrl, 'https://api.flexwolf.invalid');
    expect(config.firebase.configured, isFalse);
    expect(config.deepLinks.scheme, 'flexwolf');
    expect(config.release.version, '1.0.0');
    expect(config.release.buildNumber, '1');
  });

  test('environment configurations remain isolated', () {
    final development = AppConfig.forEnvironment(AppEnvironment.development);
    final staging = AppConfig.forEnvironment(AppEnvironment.staging);
    final production = AppConfig.forEnvironment(AppEnvironment.production);

    expect(development.backendBaseUrl, isNot(staging.backendBaseUrl));
    expect(staging.backendBaseUrl, isNot(production.backendBaseUrl));
    expect(production.allowsVerboseLogging, isFalse);
  });

  test('public Storefront token reaches Shopify configuration', () {
    final config = defaultShopifyConfigFor(
      AppEnvironment.production,
      shopDomain: 'example.myshopify.com',
      publicStorefrontAccessToken: 'public-token',
    );

    expect(config.hasPublicStorefrontToken, isTrue);
    expect(config.publicStorefrontAccessToken, 'public-token');
  });
}
