import 'dart:convert';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/account/data/shopify_customer_account_repository.dart';
import 'package:flexwolf/features/account/data/firebase_customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/account/presentation/embedded_customer_auth_screen.dart';
import 'package:flexwolf/features/notifications/data/notification_providers.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';
import 'package:flexwolf/integrations/shopify/customer_account/shopify_customer_auth_flow_coordinator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerTokenStoreProvider = Provider<CustomerTokenStore>(
  (ref) => SecureStorageCustomerTokenStore(ref.watch(secureStorageProvider)),
);

final embeddedCustomerAuthPresenterProvider =
    Provider<EmbeddedCustomerAuthPresenter>((ref) {
      final redirect = Uri.tryParse(
        ref.watch(appConfigProvider).shopify.customerAccountRedirectUri ?? '',
      );
      if (redirect == null || !redirect.hasScheme) {
        throw const AppException(
          kind: AppErrorKind.unavailable,
          message: 'Shopify Customer Account callback is not configured.',
          code: 'customer_auth_callback_not_configured',
          isRetryable: true,
        );
      }
      final presenter = EmbeddedCustomerAuthPresenter(redirectUri: redirect);
      ref.onDispose(presenter.dispose);
      return presenter;
    });

final customerAuthCoordinatorProvider = Provider<CustomerAuthFlowCoordinator>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  if (!config.shopify.hasCustomerAccountClient ||
      (config.shopify.customerAccountRedirectUri?.trim().isEmpty ?? true)) {
    return const ClientDependencyCustomerAuthCoordinator();
  }
  final presenter = ref.watch(embeddedCustomerAuthPresenterProvider);
  return ShopifyCustomerAuthFlowCoordinator(
    shopifyConfig: config.shopify,
    launchUri: presenter.launch,
    callbackStream: presenter.callbackStream,
    clearBrowserSession: presenter.clearSession,
  );
});
final customerAccountRepositoryProvider = Provider<CustomerAccountRepository>((
  ref,
) {
  if (Firebase.apps.isNotEmpty) {
    return PushAwareCustomerAccountRepository(
      delegate: FirebaseCustomerAccountRepository(),
      notifications: ref.watch(notificationRepositoryProvider),
    );
  }
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(customerAuthCoordinatorProvider);
  return PushAwareCustomerAccountRepository(
    delegate: ShopifyCustomerAccountRepository(
      client: ShopifyCustomerAccountClient(
        shopifyConfig: config.shopify,
        appConfig: config,
        logger: ref.watch(loggerProvider),
        endpointDiscovery: auth is CustomerAccountEndpointDiscovery
            ? auth as CustomerAccountEndpointDiscovery
            : null,
      ),
      tokenStore: ref.watch(customerTokenStoreProvider),
      authCoordinator: auth,
    ),
    notifications: ref.watch(notificationRepositoryProvider),
  );
});

/// The shared signed-in customer session used by every shopping entry point.
final customerSessionProvider = FutureProvider<CustomerSession?>((ref) {
  return ref.watch(customerAccountRepositoryProvider).restoreSession();
});

class SecureStorageCustomerTokenStore implements CustomerTokenStore {
  SecureStorageCustomerTokenStore(this.storage);

  static const _key = 'shopify.customer.tokens';
  final SecureStorage storage;

  @override
  Future<CustomerTokenSet?> read() async {
    final raw = await storage.read(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    if (json is! Map<String, Object?>) return null;
    final accessToken = json['accessToken'];
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    if (accessToken is! String || expiresAt == null) return null;
    return CustomerTokenSet(
      accessToken: accessToken,
      idToken: json['idToken'] as String?,
      expiresAt: expiresAt,
      remembered: json['remembered'] as bool? ?? true,
    );
  }

  @override
  Future<void> write(CustomerTokenSet tokenSet) => storage.write(
    _key,
    jsonEncode({
      'accessToken': tokenSet.accessToken,
      'idToken': tokenSet.idToken,
      'expiresAt': tokenSet.expiresAt.toIso8601String(),
      'remembered': tokenSet.remembered,
    }),
  );

  @override
  Future<void> clear() => storage.delete(_key);
}

class ClientDependencyCustomerAuthCoordinator
    implements CustomerAuthFlowCoordinator {
  const ClientDependencyCustomerAuthCoordinator();

  AppException get _pending => const AppException(
    kind: AppErrorKind.unavailable,
    message:
        'CLIENT DEPENDENCY: Shopify Customer Account OAuth is not configured.',
    code: 'customer_auth_not_configured',
    isRetryable: true,
  );

  @override
  Future<CustomerSession> authenticate({required bool rememberSession}) =>
      throw _pending;

  @override
  Future<Uri> buildAuthorizationUri({
    required String codeChallenge,
    required String state,
  }) => throw _pending;

  @override
  Future<CustomerSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) => throw _pending;

  @override
  Future<CustomerSession> renewSilently({
    required String codeChallenge,
    required String state,
  }) => throw _pending;

  @override
  Future<void> revokeOrLogout(CustomerSession session) async {}
}

class PushAwareCustomerAccountRepository implements CustomerAccountRepository {
  const PushAwareCustomerAccountRepository({
    required this.delegate,
    required this.notifications,
  });

  final CustomerAccountRepository delegate;
  final NotificationRepository notifications;

  Future<void> _syncNotifications(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Push availability must not decide whether a customer can sign in/out.
    }
  }

  @override
  Future<CustomerSession?> restoreSession() async {
    final session = await delegate.restoreSession();
    if (session != null) {
      await _syncNotifications(() async {
        await notifications.restoreRegistration();
        await _syncNotifications(notifications.registerDevice);
      });
    }
    return session;
  }

  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
    required bool rememberSession,
    bool createAccount = false,
  }) async {
    final session = await delegate.login(
      email: email,
      password: password,
      rememberSession: rememberSession,
      createAccount: createAccount,
    );
    await _syncNotifications(notifications.registerDevice);
    return session;
  }

  @override
  Future<void> handleUnauthorized() async {
    await delegate.handleUnauthorized();
    await _syncNotifications(notifications.removeRegistration);
  }

  @override
  Future<CustomerProfile?> fetchProfile() => delegate.fetchProfile();

  @override
  Future<List<CustomerAddress>> fetchAddresses() => delegate.fetchAddresses();

  @override
  Future<CustomerProfile> updateProfile(CustomerProfileInput input) =>
      delegate.updateProfile(input);

  @override
  Future<CustomerAddress> addAddress(CustomerAddressInput input) =>
      delegate.addAddress(input);

  @override
  Future<CustomerAddress> updateAddress(
    String addressId,
    CustomerAddressInput input,
  ) => delegate.updateAddress(addressId, input);

  @override
  Future<void> deleteAddress(String addressId) =>
      delegate.deleteAddress(addressId);

  @override
  Future<void> setDefaultShippingAddress(String addressId) =>
      delegate.setDefaultShippingAddress(addressId);

  @override
  Future<void> setDefaultBillingAddress(String addressId) =>
      delegate.setDefaultBillingAddress(addressId);

  @override
  Future<PaginatedResult<CustomerOrder>> fetchOrders(
    PaginationRequest pagination,
  ) => delegate.fetchOrders(pagination);

  @override
  Future<void> logout() async {
    await _syncNotifications(notifications.removeRegistration);
    await delegate.logout();
  }
}
