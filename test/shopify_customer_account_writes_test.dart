import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/features/account/data/shopify_customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile edits write supported names and reload the Shopify profile',
    () async {
      final client = _AccountClient();
      final repository = _repository(client);

      final profile = await repository.updateProfile(
        const CustomerProfileInput(firstName: '  Flex ', lastName: ' Wolf '),
      );

      expect(profile.firstName, 'Flex');
      expect(client.calls.first.variables['input'], {
        'firstName': 'Flex',
        'lastName': 'Wolf',
      });
      expect(client.calls.last.document, contains('query CustomerProfile'));
    },
  );

  test(
    'address create, edit, default and delete use Customer Account API',
    () async {
      final client = _AccountClient();
      final repository = _repository(client);
      const address = CustomerAddressInput(
        firstName: 'Flex',
        lastName: 'Wolf',
        address1: '1 Main Street',
        city: 'Los Angeles',
        country: 'us',
        zip: '90001',
        province: 'CA',
        phone: '+15551234567',
      );

      expect((await repository.addAddress(address)).id, 'address-1');
      expect(
        client.calls.last.variables['address'],
        containsPair('territoryCode', 'US'),
      );
      expect(
        client.calls.last.variables['address'],
        containsPair('zoneCode', 'CA'),
      );
      expect(
        client.calls.last.variables['address'],
        containsPair('phoneNumber', '+15551234567'),
      );

      await repository.updateAddress('address-1', address);
      expect(client.calls.last.variables['addressId'], 'address-1');
      await repository.setDefaultShippingAddress('address-1');
      expect(client.calls.last.variables['defaultAddress'], isTrue);
      expect(client.calls.last.variables.containsKey('address'), isFalse);
      await repository.deleteAddress('address-1');
      expect(client.calls.last.variables['addressId'], 'address-1');
    },
  );

  test('Shopify validation errors are shown and unsupported fields cannot silently save', () async {
    final client = _AccountClient()..rejectNext = true;
    final repository = _repository(client);

    await expectLater(
      repository.addAddress(
        const CustomerAddressInput(
          firstName: 'Flex',
          lastName: 'Wolf',
          address1: '1 Main Street',
          city: 'Los Angeles',
          country: 'US',
          zip: '90001',
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          'Address rejected',
        ),
      ),
    );
    await expectLater(
      repository.updateProfile(
        const CustomerProfileInput(
          firstName: 'Flex',
          lastName: 'Wolf',
          phone: '+15551234567',
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'customer_phone_update_unsupported',
        ),
      ),
    );
    await expectLater(
      repository.addAddress(
        const CustomerAddressInput(
          firstName: 'Flex',
          lastName: 'Wolf',
          address1: '1 Main Street',
          city: 'Los Angeles',
          country: 'United States',
          zip: '90001',
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'customer_country_code_invalid',
        ),
      ),
    );
  });

  test(
    'email marketing choices use the authenticated customer consent mutations',
    () async {
      final client = _AccountClient();
      final repository = _repository(client);

      await repository.setEmailMarketing(true);
      await repository.setEmailMarketing(false);

      expect(
        client.calls[0].document,
        contains('customerEmailMarketingSubscribe'),
      );
      expect(
        client.calls[1].document,
        contains('customerEmailMarketingUnsubscribe'),
      );
    },
  );
}

ShopifyCustomerAccountRepository _repository(_AccountClient client) {
  final tokens = _MemoryTokens();
  tokens.value = CustomerTokenSet(
    accessToken: 'test-customer-token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  return ShopifyCustomerAccountRepository(client: client, tokenStore: tokens);
}

class _MemoryTokens implements CustomerTokenStore {
  CustomerTokenSet? value;
  @override
  Future<CustomerTokenSet?> read() async => value;
  @override
  Future<void> write(CustomerTokenSet tokenSet) async => value = tokenSet;
  @override
  Future<void> clear() async => value = null;
}

class _AccountCall {
  const _AccountCall(this.document, this.variables);
  final String document;
  final Map<String, Object?> variables;
}

class _AccountClient extends ShopifyCustomerAccountClient {
  _AccountClient()
    : super(
        shopifyConfig: const ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: 'example.myshopify.com',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
        ),
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      );

  final calls = <_AccountCall>[];
  bool rejectNext = false;

  @override
  Future<Map<String, Object?>> query(
    String document, {
    required String accessToken,
    Map<String, Object?> variables = const <String, Object?>{},
  }) async {
    expect(accessToken, 'test-customer-token');
    calls.add(_AccountCall(document, variables));
    if (document.contains('query CustomerProfile')) {
      return {
        'customer': {
          'id': 'customer-1',
          'firstName': 'Flex',
          'lastName': 'Wolf',
        },
      };
    }
    final field = switch (document) {
      final value when value.contains('mutation CustomerUpdate') =>
        'customerUpdate',
      final value when value.contains('mutation CustomerAddressCreate') =>
        'customerAddressCreate',
      final value when value.contains('mutation CustomerAddressUpdate') =>
        'customerAddressUpdate',
      final value
          when value.contains('mutation CustomerEmailMarketingSubscribe') =>
        'customerEmailMarketingSubscribe',
      final value
          when value.contains('mutation CustomerEmailMarketingUnsubscribe') =>
        'customerEmailMarketingUnsubscribe',
      _ => 'customerAddressDelete',
    };
    if (rejectNext) {
      rejectNext = false;
      return {
        field: {
          'userErrors': [
            {'message': 'Address rejected'},
          ],
        },
      };
    }
    return {
      field: {
        'userErrors': <Object?>[],
        if (field == 'customerAddressCreate' ||
            field == 'customerAddressUpdate')
          'customerAddress': {'id': 'address-1', 'territoryCode': 'US'},
        if (field == 'customerAddressDelete') 'deletedAddressId': 'address-1',
        if (field == 'customerUpdate') 'customer': {'id': 'customer-1'},
        if (field == 'customerEmailMarketingSubscribe' ||
            field == 'customerEmailMarketingUnsubscribe')
          'emailAddress': {'emailAddress': 'customer@example.test'},
      },
    };
  }
}
