import 'dart:io';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';

class ShopifyCustomerAccountClient {
  ShopifyCustomerAccountClient({
    required this.shopifyConfig,
    required this.appConfig,
    required this.logger,
    this.endpointDiscovery,
  });

  final ShopifyConfig shopifyConfig;
  final AppConfig appConfig;
  final AppLogger logger;
  final CustomerAccountEndpointDiscovery? endpointDiscovery;

  Future<CustomerAccountAuthConfiguration> discoverAuthConfiguration() async {
    _ensureConfigured();
    final discovery = endpointDiscovery;
    if (discovery == null) {
      throw const AppException(
        kind: AppErrorKind.api,
        message:
            'Customer Account endpoint discovery transport is not configured.',
        code: 'customer_account_discovery_not_configured',
      );
    }

    return discovery.discover(shopifyConfig);
  }

  Future<Map<String, Object?>> query(
    String document, {
    required String accessToken,
    Map<String, Object?> variables = const <String, Object?>{},
  }) async {
    final discovery = await discoverAuthConfiguration();
    final transport = HttpClient();
    try {
      final response = await ShopifyGraphqlHttpClient(
        httpClient: transport,
        endpoint: discovery.graphqlEndpoint,
        config: appConfig,
        logger: logger,
        headersBuilder: () => {'Authorization': accessToken},
      ).query(ShopifyGraphqlRequest(document: document, variables: variables));
      final data = response.data;
      if (data is! Map<String, Object?>) {
        throw const AppException(
          kind: AppErrorKind.api,
          message: 'Could not load your account. Please try again.',
          code: 'customer_data_invalid',
          isRetryable: true,
        );
      }
      return data;
    } finally {
      transport.close(force: true);
    }
  }

  void _ensureConfigured() {
    if (!shopifyConfig.hasShopDomain) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Shopify customer account shop domain is not configured.',
        code: 'customer_account_not_configured',
      );
    }
  }
}

abstract interface class CustomerAccountEndpointDiscovery {
  Future<CustomerAccountAuthConfiguration> discover(ShopifyConfig config);
}

class CustomerAccountAuthConfiguration {
  const CustomerAccountAuthConfiguration({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.logoutEndpoint,
    required this.graphqlEndpoint,
  });

  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri logoutEndpoint;
  final Uri graphqlEndpoint;
}

class CustomerTokenSet {
  const CustomerTokenSet({
    required this.accessToken,
    required this.expiresAt,
    this.idToken,
    this.remembered = true,
  });

  final String accessToken;
  final String? idToken;
  final DateTime expiresAt;
  final bool remembered;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

abstract interface class CustomerTokenStore {
  Future<CustomerTokenSet?> read();

  Future<void> write(CustomerTokenSet tokenSet);

  Future<void> clear();
}

class CustomerAuthSessionCoordinator {
  Future<CustomerTokenSet>? _refreshInFlight;

  Future<CustomerTokenSet> refreshOnce(
    Future<CustomerTokenSet> Function() refresh,
  ) {
    return _refreshInFlight ??= refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }
}
