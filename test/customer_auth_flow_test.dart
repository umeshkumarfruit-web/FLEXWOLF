import 'dart:async';

import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/data/shopify_customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';
import 'package:flexwolf/integrations/shopify/customer_account/shopify_customer_auth_flow_coordinator.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_checkout_foundation_test.dart' show MemoryCustomerTokenStore;

const config = ShopifyConfig(
  environment: AppEnvironment.development,
  shopDomain: 'example.myshopify.com',
  storefrontApiVersion: ShopifyApiVersions.storefront,
  customerAccountApiVersion: ShopifyApiVersions.customerAccount,
  adminApiVersion: ShopifyApiVersions.admin,
  customerAccountClientId: 'public-client',
  customerAccountRedirectUri: 'shop.123456.flexwolf://auth/callback',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('callback arriving during browser launch is retained and exchanged', () async {
    final links = StreamController<Uri>.broadcast(sync: true);
    final flow = TestFlow(links.stream, (uri) async {
      links.add(
        Uri.parse(
          "shop.123456.flexwolf://auth/callback?code=verified&state=${uri.queryParameters['state']}",
        ),
      );
      return true;
    });
    final session = await flow.authenticate(rememberSession: false);
    expect(session.accessToken, 'test-token');
    expect(session.remembered, isFalse);
    expect(flow.exchanges, 1);
    expect(links.hasListener, isFalse);
    await links.close();
  });
  test('expired remembered session renews through an in-app silent OAuth callback', () async {
    final links = StreamController<Uri>.broadcast(sync: true);
    Uri? opened;
    final flow = TestFlow(links.stream, (uri) async {
      opened = uri;
      links.add(
        Uri.parse(
          "shop.123456.flexwolf://auth/callback?code=verified&state=${uri.queryParameters['state']}",
        ),
      );
      return true;
    });
    final tokens = MemoryCustomerTokenStore();
    await tokens.write(
      CustomerTokenSet(
        accessToken: 'expired-token',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    final repository = ShopifyCustomerAccountRepository(
      client: ProfileClient(),
      tokenStore: tokens,
      authCoordinator: flow,
    );

    final session = await repository.restoreSession();

    expect(opened?.queryParameters['prompt'], 'none');
    expect(session?.accessToken, 'test-token');
    expect((await tokens.read())?.accessToken, 'test-token');
    expect(flow.exchanges, 1);
    await links.close();
  });
  test(
    'customer profile and addresses use the current customer token',
    () async {
      final store = MemoryCustomerTokenStore();
      await store.write(
        CustomerTokenSet(
          accessToken: 'customer-only',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      final client = ProfileClient();
      final repository = ShopifyCustomerAccountRepository(
        client: client,
        tokenStore: store,
      );
      expect((await repository.fetchProfile())?.firstName, 'Alex');
      expect((await repository.fetchAddresses()).single.city, 'Mumbai');
      expect(client.tokens, ['customer-only', 'customer-only']);
      await repository.handleUnauthorized();
      await expectLater(
        repository.fetchProfile(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'customer_session_expired',
          ),
        ),
      );
    },
  );
  test(
    'notification failures cannot undo login or leave logout incomplete',
    () async {
      final store = MemoryCustomerTokenStore();
      final app = AppConfig.forEnvironment(AppEnvironment.development);
      final flow = TestFlow(const Stream.empty(), (_) async => true)
        ..directLogin = true;
      final repository = PushAwareCustomerAccountRepository(
        delegate: ShopifyCustomerAccountRepository(
          client: ShopifyCustomerAccountClient(
            shopifyConfig: config,
            appConfig: app,
            logger: AppLogger(app),
          ),
          tokenStore: store,
          authCoordinator: flow,
        ),
        notifications: FailingNotifications(),
      );
      expect(
        (await repository.login(
          email: '',
          password: '',
          rememberSession: true,
        )).accessToken,
        'test-token',
      );
      expect(await repository.restoreSession(), isNotNull);
      await repository.logout();
      expect(await repository.restoreSession(), isNull);
    },
  );

  test('callback with wrong state is rejected before code exchange', () async {
    final links = StreamController<Uri>.broadcast(sync: true);
    final flow = TestFlow(links.stream, (_) async {
      links.add(
        Uri.parse(
          'shop.123456.flexwolf://auth/callback?code=verified&state=wrong',
        ),
      );
      return true;
    });
    await expectLater(
      flow.authenticate(rememberSession: true),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          'customer_auth_state_mismatch',
        ),
      ),
    );
    expect(flow.exchanges, 0);
    expect(links.hasListener, isFalse);
    await links.close();
  });
  test(
    'cancelled browser login times out and releases callback listener',
    () async {
      final links = StreamController<Uri>.broadcast();
      final flow = TestFlow(links.stream, (_) async => true);
      await expectLater(
        flow.authenticate(rememberSession: true),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'customer_auth_callback_timeout',
          ),
        ),
      );
      expect(links.hasListener, isFalse);
      await links.close();
    },
  );
  test('non-remembered login stays in memory and logout clears it on browser failure', () async {
    final store = MemoryCustomerTokenStore();
    final app = AppConfig.forEnvironment(AppEnvironment.development);
    final flow = TestFlow(const Stream.empty(), (_) async => false);
    final repository = ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: config,
        appConfig: app,
        logger: AppLogger(app),
      ),
      tokenStore: store,
      authCoordinator: flow,
    );
    flow.directLogin = true;
    await repository.login(email: '', password: '', rememberSession: false);
    expect(await store.read(), isNull);
    expect(await repository.restoreSession(), isNotNull);
    await repository.logout();
    expect(await repository.restoreSession(), isNull);
    expect(await store.read(), isNull);
  });
  test(
    'non-Shopify mobile callback scheme is rejected before launch',
    () async {
      final flow = ShopifyCustomerAuthFlowCoordinator(
        shopifyConfig: const ShopifyConfig(
          environment: AppEnvironment.development,
          shopDomain: 'example.myshopify.com',
          storefrontApiVersion: ShopifyApiVersions.storefront,
          customerAccountApiVersion: ShopifyApiVersions.customerAccount,
          adminApiVersion: ShopifyApiVersions.admin,
          customerAccountClientId: 'public-client',
          customerAccountRedirectUri: 'flexwolf://auth/callback',
        ),
        launchUri: (_) async => true,
      );

      await expectLater(
        flow.buildAuthorizationUri(codeChallenge: 'challenge', state: 'state'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'customer_auth_redirect_invalid',
          ),
        ),
      );
    },
  );
}

class TestFlow extends ShopifyCustomerAuthFlowCoordinator {
  TestFlow(Stream<Uri> links, Future<bool> Function(Uri) launch)
    : super(
        shopifyConfig: config,
        callbackStream: links,
        launchUri: launch,
        callbackTimeout: const Duration(milliseconds: 100),
      );
  int exchanges = 0;
  bool directLogin = false;
  @override
  Future<Uri> buildAuthorizationUri({
    required String codeChallenge,
    required String state,
  }) async => Uri.https('example.com', '/authorize', {
    'state': state,
    'code_challenge': codeChallenge,
  });
  @override
  Future<CustomerSession> authenticate({required bool rememberSession}) =>
      directLogin
      ? Future.value(
          CustomerSession(
            accessToken: 'test-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            remembered: rememberSession,
          ),
        )
      : super.authenticate(rememberSession: rememberSession);
  @override
  Future<CustomerSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    exchanges++;
    expect(code, 'verified');
    expect(codeVerifier.length, greaterThanOrEqualTo(43));
    return CustomerSession(
      accessToken: 'test-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> revokeOrLogout(CustomerSession session) async =>
      throw const AppException(
        kind: AppErrorKind.network,
        message: 'Browser unavailable',
      );
}

class ProfileClient extends ShopifyCustomerAccountClient {
  ProfileClient()
    : super(
        shopifyConfig: config,
        appConfig: AppConfig.forEnvironment(AppEnvironment.development),
        logger: AppLogger(AppConfig.forEnvironment(AppEnvironment.development)),
      );
  final tokens = <String>[];
  @override
  Future<Map<String, Object?>> query(
    String document, {
    required String accessToken,
    Map<String, Object?> variables = const <String, Object?>{},
  }) async {
    tokens.add(accessToken);
    return {
      'customer': {
        'id': 'customer-1',
        'firstName': 'Alex',
        'addresses': {
          'nodes': [
            {'id': 'address-1', 'city': 'Mumbai'},
          ],
        },
      },
    };
  }
}

class FailingNotifications implements NotificationRepository {
  @override
  Future<PushTokenRegistration?> registerDevice({String? customerId}) async =>
      throw StateError('Push unavailable');
  @override
  Future<PushTokenRegistration?> restoreRegistration() async =>
      throw StateError('Push unavailable');
  @override
  Future<void> removeRegistration() async =>
      throw StateError('Push unavailable');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
