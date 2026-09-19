import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/features/account/data/shopify_customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomerProfile parses protected customer fields when provided', () {
    final customer = CustomerProfile.fromShopify(<String, Object?>{
      'id': 'gid://shopify/Customer/1',
      'displayName': 'FLEXWOLF Customer',
      'firstName': 'Flex',
      'lastName': 'Customer',
      'emailAddress': <String, Object?>{
        'emailAddress': 'customer@example.test',
      },
      'phoneNumber': <String, Object?>{'phoneNumber': '+15555550123'},
      'defaultAddress': <String, Object?>{
        'id': 'gid://shopify/MailingAddress/1',
        'city': 'Los Angeles',
        'country': 'United States',
      },
    });

    expect(customer.id, 'gid://shopify/Customer/1');
    expect(customer.email, 'customer@example.test');
    expect(customer.phone, '+15555550123');
    expect(customer.defaultAddress?.city, 'Los Angeles');
  });

  test('CustomerProfile parses billing address and account defaults', () {
    final customer = CustomerProfile.fromShopify(<String, Object?>{
      'id': 'gid://shopify/Customer/2',
      'defaultBillingAddress': <String, Object?>{
        'id': 'gid://shopify/MailingAddress/2',
        'address1': '10 Billing Road',
        'city': 'Austin',
        'country': 'United States',
        'zip': '78701',
      },
    });

    expect(customer.accountStatus, CustomerAccountStatus.active);
    expect(customer.defaultBillingAddress?.isDefaultBilling, isTrue);
    expect(customer.defaultBillingAddress?.city, 'Austin');
  });

  test('profile and address inputs validate required fields', () {
    expect(
      () => const CustomerProfileInput(
        firstName: '',
        lastName: 'Wolf',
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => const CustomerAddressInput(
        firstName: 'Flex',
        lastName: 'Wolf',
        address1: '',
        city: 'Los Angeles',
        country: 'United States',
        zip: '90001',
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => const CustomerAddressInput(
        firstName: 'Flex',
        lastName: 'Wolf',
        address1: '1 Main Street',
        city: 'Los Angeles',
        country: 'United States',
        zip: '90001',
      ).validate(),
      returnsNormally,
    );
  });

  test(
    'CustomerOrder maps line item selected options and fulfillment tracking',
    () {
      final order = CustomerOrder.fromShopify(<String, Object?>{
        'id': 'gid://shopify/Order/1',
        'name': '#1001',
        'processedAt': '2026-08-31T12:00:00Z',
        'fulfillmentStatus': 'FULFILLED',
        'totalPrice': <String, Object?>{
          'amount': '89.90',
          'currencyCode': 'USD',
        },
        'lineItems': <String, Object?>{
          'nodes': <Map<String, Object?>>[
            <String, Object?>{
              'title': 'Flex Tee',
              'quantity': 2,
              'sku': 'FW-TEE-BLK-M',
              'selectedOptions': <Map<String, Object?>>[
                <String, Object?>{'name': 'Color', 'value': 'Black'},
                <String, Object?>{'name': 'Size', 'value': 'M'},
              ],
            },
          ],
        },
        'fulfillments': <Map<String, Object?>>[
          <String, Object?>{
            'status': 'SUCCESS',
            'trackingCompany': 'UPS',
            'trackingNumber': 'TRACK123',
            'trackingUrl': 'https://tracking.example.test/TRACK123',
          },
        ],
      });

      expect(order.orderNumber, '#1001');
      expect(order.totalPrice?.amount.toString(), '89.90');
      expect(order.lineItems.single.color, 'Black');
      expect(order.lineItems.single.size, 'M');
      expect(order.fulfillments.single.trackingNumber, 'TRACK123');
    },
  );

  test('Customer Account repository restores valid sessions and clears expired sessions', () async {
    final tokenStore = MemoryCustomerTokenStore();
    final repository = ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: const ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: '',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
        ),
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      ),
      tokenStore: tokenStore,
    );

    await tokenStore.write(
      CustomerTokenSet(
        accessToken: 'customer-token-reference',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    expect(
      (await repository.restoreSession())?.accessToken,
      'customer-token-reference',
    );

    await tokenStore.write(
      CustomerTokenSet(
        accessToken: 'expired-token-reference',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    expect(await repository.restoreSession(), isNull);
    expect(await tokenStore.read(), isNull);
  });

  test('logout clears only customer token state', () async {
    final tokenStore = MemoryCustomerTokenStore();
    final repository = ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: const ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: '',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
        ),
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      ),
      tokenStore: tokenStore,
    );

    await tokenStore.write(
      CustomerTokenSet(
        accessToken: 'customer-token-reference',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await repository.logout();

    expect(await tokenStore.read(), isNull);
  });

  test(
    'session restore skips non-remembered Customer Account sessions',
    () async {
      final tokenStore = MemoryCustomerTokenStore();
      final repository = ShopifyCustomerAccountRepository(
        client: ShopifyCustomerAccountClient(
          shopifyConfig: const ShopifyConfig(
            environment: AppEnvironment.development,
            shopDomain: '',
            storefrontApiVersion: ShopifyApiVersions.storefront,
            customerAccountApiVersion: ShopifyApiVersions.customerAccount,
            adminApiVersion: ShopifyApiVersions.admin,
          ),
          appConfig: AppConfig.forEnvironment(AppEnvironment.development),
          logger: AppLogger(
            AppConfig.forEnvironment(AppEnvironment.development),
          ),
        ),
        tokenStore: tokenStore,
      );

      await tokenStore.write(
        CustomerTokenSet(
          accessToken: 'short-lived-customer-token-reference',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          remembered: false,
        ),
      );

      expect(await repository.restoreSession(), isNull);
      expect(await tokenStore.read(), isNull);
    },
  );

  test('unauthorized handling clears Customer Account session only', () async {
    final tokenStore = MemoryCustomerTokenStore();
    final repository = ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: const ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: '',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
        ),
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      ),
      tokenStore: tokenStore,
    );

    await tokenStore.write(
      CustomerTokenSet(
        accessToken: 'unauthorized-customer-token-reference',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    await repository.handleUnauthorized();

    expect(await tokenStore.read(), isNull);
  });

  test('login stores configured development Customer Account token', () async {
    final tokenStore = MemoryCustomerTokenStore();
    final expiresAt = DateTime.now().add(const Duration(hours: 2));
    final repository = ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: 'flexwolf.myshopify.com',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
          customerAccountAccessToken: 'configured-customer-token',
          customerAccountTokenExpiresAt: expiresAt,
        ),
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      ),
      tokenStore: tokenStore,
    );

    final session = await repository.login(
      email: 'customer@example.test',
      password: 'not-persisted',
      rememberSession: true,
    );

    expect(session.accessToken, 'configured-customer-token');
    expect((await tokenStore.read())?.accessToken, 'configured-customer-token');
    expect((await tokenStore.read())?.expiresAt, expiresAt);
  });

  test(
    'login reports clear error when Customer Account token is absent',
    () async {
      final repository = ShopifyCustomerAccountRepository(
        client: ShopifyCustomerAccountClient(
          shopifyConfig: const ShopifyConfig(
            environment: AppEnvironment.development,
            shopDomain: 'flexwolf.myshopify.com',
            storefrontApiVersion: ShopifyApiVersions.storefront,
            customerAccountApiVersion: ShopifyApiVersions.customerAccount,
            adminApiVersion: ShopifyApiVersions.admin,
          ),
          appConfig: AppConfig.forEnvironment(AppEnvironment.development),
          logger: AppLogger(
            AppConfig.forEnvironment(AppEnvironment.development),
          ),
        ),
        tokenStore: MemoryCustomerTokenStore(),
      );

      expect(
        repository.login(
          email: 'customer@example.test',
          password: 'password',
          rememberSession: true,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'customer_auth_not_configured',
          ),
        ),
      );
    },
  );
  test('checkout close is not treated as purchase success', () {
    const closed = CheckoutResult.closed();
    const completedWithoutOrder = CheckoutResult.completed();
    const completedWithOrder = CheckoutResult.completed(
      orderId: 'gid://shopify/Order/1',
    );

    expect(closed.isSuccessfulPurchase, isFalse);
    expect(completedWithoutOrder.isSuccessfulPurchase, isFalse);
    expect(completedWithOrder.isSuccessfulPurchase, isTrue);
  });
}

class MemoryCustomerTokenStore implements CustomerTokenStore {
  CustomerTokenSet? _value;

  @override
  Future<void> clear() async {
    _value = null;
  }

  @override
  Future<CustomerTokenSet?> read() async => _value;

  @override
  Future<void> write(CustomerTokenSet tokenSet) async {
    _value = tokenSet;
  }
}
