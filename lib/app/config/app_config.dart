import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/security/security_policy.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flexwolf/integrations/shopify/shopify_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _compileApiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _compileShopDomain = String.fromEnvironment('SHOPIFY_STORE_DOMAIN');
const _compilePublicStorefrontToken = String.fromEnvironment(
  'SHOPIFY_STOREFRONT_PUBLIC_TOKEN',
);
const _defaultShopDomain = 'flexwolf-co.myshopify.com';
const _defaultCustomerAccountRedirectUri =
    'shop.70241911041.flexwolf://customer-account/callback';
const _compileFirebaseProject = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _compileDeepLinkScheme = String.fromEnvironment(
  'DEEP_LINK_SCHEME',
  defaultValue: 'flexwolf',
);
const _compileDeepLinkHost = String.fromEnvironment('DEEP_LINK_HOST');
const _compileAppVersion = String.fromEnvironment('APP_VERSION');
const _compileBuildNumber = String.fromEnvironment('BUILD_NUMBER');
const _compileReleaseNotes = String.fromEnvironment('RELEASE_NOTES');
const _compileCustomerAccountClientId = String.fromEnvironment(
  'SHOPIFY_CUSTOMER_ACCOUNT_CLIENT_ID',
);
const _compileCustomerAccountRedirectUri = String.fromEnvironment(
  'SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI',
);
const _compileCustomerAccountAccessToken = String.fromEnvironment(
  'SHOPIFY_CUSTOMER_ACCOUNT_ACCESS_TOKEN',
);
const _compileCustomerAccountTokenExpiresAt = String.fromEnvironment(
  'SHOPIFY_CUSTOMER_ACCOUNT_TOKEN_EXPIRES_AT',
);

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('AppConfig must be provided during bootstrap.'),
);

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.backendBaseUrl,
    required this.shopify,
    required this.featureFlags,
    required this.networkTimeout,
    required this.allowsProductionSideEffects,
    required this.allowsVerboseLogging,
    required this.firebase,
    required this.deepLinks,
    required this.release,
  });

  factory AppConfig.forEnvironment(AppEnvironment environment) {
    final defaults = _defaultsFor(environment);
    return AppConfig(
      environment: environment,
      appName: defaults.appName,
      backendBaseUrl: _secureBackendBaseUrl(defaults.backendBaseUrl),
      shopify: defaultShopifyConfigFor(
        environment,
        shopDomain: _override(_compileShopDomain, _defaultShopDomain),
        publicStorefrontAccessToken: _optional(_compilePublicStorefrontToken),
        customerAccountClientId: _customerAccountClientId(),
        customerAccountRedirectUri: _customerAccountRedirectUri(),
        customerAccountAccessToken: _optionalCustomerAccountAccessToken(
          environment,
        ),
        customerAccountTokenExpiresAt: _customerAccountTokenExpiresAt(),
      ),
      featureFlags: defaults.featureFlags,
      networkTimeout: defaults.networkTimeout,
      allowsProductionSideEffects: defaults.allowsProductionSideEffects,
      allowsVerboseLogging: defaults.allowsVerboseLogging,
      firebase: FirebaseEnvironmentConfig(
        projectId: _compileFirebaseProject,
        configured: _compileFirebaseProject.isNotEmpty,
      ),
      deepLinks: DeepLinkConfig(
        scheme: _compileDeepLinkScheme,
        host: _compileDeepLinkHost,
      ),
      release: ReleaseMetadata(
        version: _override(_compileAppVersion, '1.0.0'),
        buildNumber: _override(_compileBuildNumber, '1'),
        releaseNotes: _compileReleaseNotes.trim(),
      ),
    );
  }

  static AppConfig _defaultsFor(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.development:
        return AppConfig._defaults(
          environment: AppEnvironment.development,
          appName: 'FLEXWOLF Dev',
          backendBaseUrl: 'https://dev-api.flexwolf.invalid',
          shopify: defaultShopifyConfigFor(AppEnvironment.development),
          featureFlags: const FeatureFlags(enableDiagnostics: true),
          networkTimeout: const Duration(seconds: 20),
          allowsProductionSideEffects: false,
          allowsVerboseLogging: true,
        );
      case AppEnvironment.staging:
        return AppConfig._defaults(
          environment: AppEnvironment.staging,
          appName: 'FLEXWOLF Staging',
          backendBaseUrl: 'https://staging-api.flexwolf.invalid',
          shopify: defaultShopifyConfigFor(AppEnvironment.staging),
          featureFlags: const FeatureFlags(enableDiagnostics: true),
          networkTimeout: const Duration(seconds: 20),
          allowsProductionSideEffects: false,
          allowsVerboseLogging: true,
        );
      case AppEnvironment.production:
        return AppConfig._defaults(
          environment: AppEnvironment.production,
          appName: 'FLEXWOLF',
          backendBaseUrl: 'https://api.flexwolf.invalid',
          shopify: defaultShopifyConfigFor(AppEnvironment.production),
          featureFlags: const FeatureFlags(enableDiagnostics: false),
          networkTimeout: const Duration(seconds: 15),
          allowsProductionSideEffects: true,
          allowsVerboseLogging: false,
        );
    }
  }

  const AppConfig._defaults({
    required this.environment,
    required this.appName,
    required this.backendBaseUrl,
    required this.shopify,
    required this.featureFlags,
    required this.networkTimeout,
    required this.allowsProductionSideEffects,
    required this.allowsVerboseLogging,
  }) : firebase = const FirebaseEnvironmentConfig(),
       deepLinks = const DeepLinkConfig(),
       release = const ReleaseMetadata();

  final AppEnvironment environment;
  final String appName;
  final String backendBaseUrl;
  final ShopifyConfig shopify;
  final FeatureFlags featureFlags;
  final Duration networkTimeout;
  final bool allowsProductionSideEffects;
  final bool allowsVerboseLogging;
  final FirebaseEnvironmentConfig firebase;
  final DeepLinkConfig deepLinks;
  final ReleaseMetadata release;
}

String _override(String value, String fallback) =>
    value.trim().isEmpty ? fallback : value.trim();

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _customerAccountClientId() =>
    _optional(_compileCustomerAccountClientId);

String? _customerAccountRedirectUri() {
  if (_customerAccountClientId() == null) return null;
  return _optional(_compileCustomerAccountRedirectUri) ??
      _defaultCustomerAccountRedirectUri;
}

String? _optionalCustomerAccountAccessToken(AppEnvironment environment) {
  final token = _optional(_compileCustomerAccountAccessToken);
  if (token != null && environment.isProduction) {
    throw StateError(
      'SHOPIFY_CUSTOMER_ACCOUNT_ACCESS_TOKEN must not be embedded in production builds.',
    );
  }
  return token;
}

DateTime? _customerAccountTokenExpiresAt() {
  final value = _optional(_compileCustomerAccountTokenExpiresAt);
  if (value == null) return null;
  return DateTime.tryParse(value);
}

String _secureBackendBaseUrl(String fallback) {
  final value = _override(_compileApiBaseUrl, fallback);
  SecurityPolicy.requireHttpsUri(Uri.parse(value), context: 'Backend base URL');
  return value;
}

class FirebaseEnvironmentConfig {
  const FirebaseEnvironmentConfig({
    this.projectId = '',
    this.configured = false,
  });

  final String projectId;
  final bool configured;
}

class DeepLinkConfig {
  const DeepLinkConfig({this.scheme = 'flexwolf', this.host = ''});

  final String scheme;
  final String host;
}

class ReleaseMetadata {
  const ReleaseMetadata({
    this.version = '1.0.0',
    this.buildNumber = '1',
    this.releaseNotes = '',
  });

  final String version;
  final String buildNumber;
  final String releaseNotes;
}

class FeatureFlags {
  const FeatureFlags({required this.enableDiagnostics});

  final bool enableDiagnostics;
}
