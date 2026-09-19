import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/data/queries/customer_account_queries.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';

class ShopifyCustomerAccountRepository implements CustomerAccountRepository {
  ShopifyCustomerAccountRepository({
    required this.client,
    required this.tokenStore,
    this.authCoordinator,
  });

  final ShopifyCustomerAccountClient client;
  final CustomerTokenStore tokenStore;
  final CustomerAuthFlowCoordinator? authCoordinator;
  CustomerSession? _activeSession;

  AppException get _customerWritePending => const AppException(
    kind: AppErrorKind.unavailable,
    message: 'CLIENT DEPENDENCY: Shopify Customer Account profile and address writes are not configured.',
    code: 'customer_profile_write_not_configured',
    isRetryable: true,
  );

  @override
  Future<CustomerSession?> restoreSession() async {
    final active = _activeSession;
    if (active != null && DateTime.now().isBefore(active.expiresAt)) {
      return active;
    }
    _activeSession = null;
    final tokenSet = await tokenStore.read();
    if (tokenSet == null) {
      return null;
    }
    if (tokenSet.isExpired || !tokenSet.remembered) {
      await tokenStore.clear();
      return null;
    }
    return CustomerSession(
      accessToken: tokenSet.accessToken,
      idToken: tokenSet.idToken,
      expiresAt: tokenSet.expiresAt,
      remembered: tokenSet.remembered,
    );
  }

  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
    required bool rememberSession,
    bool createAccount = false,
  }) async {
    final coordinator = authCoordinator;
    if (coordinator != null &&
        client.shopifyConfig.hasShopDomain &&
        client.shopifyConfig.hasCustomerAccountClient &&
        (client.shopifyConfig.customerAccountRedirectUri?.trim().isNotEmpty ??
            false)) {
      final session = await coordinator.authenticate(
        rememberSession: rememberSession,
      );
      if (rememberSession) {
        await tokenStore.write(
          CustomerTokenSet(
            accessToken: session.accessToken,
            idToken: session.idToken,
            expiresAt: session.expiresAt,
            remembered: session.remembered,
          ),
        );
      } else {
        await tokenStore.clear();
      }
      _activeSession = session;
      return session;
    }

    final configuredToken = client.shopifyConfig.customerAccountAccessToken;
    if (configuredToken == null || configuredToken.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.unavailable,
        message: 'Shopify Customer Account login is not configured. Add shop domain, Customer Account client id, and redirect URI.',
        code: 'customer_auth_not_configured',
        isRetryable: true,
      );
    }

    if (client.shopifyConfig.environment.isProduction) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Customer access tokens must not be embedded in production builds. Use OAuth/PKCE.',
        code: 'customer_auth_token_embedded_in_production',
      );
    }

    final expiresAt =
        client.shopifyConfig.customerAccountTokenExpiresAt ??
        DateTime.now().add(const Duration(hours: 1));
    if (DateTime.now().isAfter(expiresAt)) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Configured Shopify Customer Account token is expired.',
        code: 'customer_auth_token_expired',
        isRetryable: true,
      );
    }

    final tokenSet = CustomerTokenSet(
      accessToken: configuredToken.trim(),
      expiresAt: expiresAt,
      remembered: rememberSession,
    );
    if (rememberSession) {
      await tokenStore.write(tokenSet);
    } else {
      await tokenStore.clear();
    }
    return _activeSession = CustomerSession(
      accessToken: tokenSet.accessToken,
      expiresAt: tokenSet.expiresAt,
      remembered: tokenSet.remembered,
    );
  }

  @override
  Future<void> handleUnauthorized() async {
    _activeSession = null;
    await tokenStore.clear();
  }

  Future<Map<String, Object?>> _customerQuery(String document) async {
    final session = await restoreSession();
    if (session == null) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Please sign in again to view your account.',
        code: 'customer_session_expired',
      );
    }
    return client.query(document, accessToken: session.accessToken);
  }

  @override
  Future<CustomerProfile?> fetchProfile() async {
    final data = await _customerQuery(CustomerAccountQueries.profile);
    final customer = data['customer'];
    return customer is Map<String, Object?>
        ? CustomerProfile.fromShopify(customer)
        : null;
  }

  @override
  Future<List<CustomerAddress>> fetchAddresses() async {
    final data = await _customerQuery(CustomerAccountQueries.addresses);
    final customer = data['customer'] as Map<String, Object?>?;
    final addresses = customer?['addresses'] as Map<String, Object?>?;
    final nodes = addresses?['nodes'] as List? ?? const [];
    return nodes
        .whereType<Map<String, Object?>>()
        .map(CustomerAddress.fromShopify)
        .toList();
  }

  @override
  Future<CustomerProfile> updateProfile(CustomerProfileInput input) {
    input.validate();
    throw _customerWritePending;
  }

  @override
  Future<CustomerAddress> addAddress(CustomerAddressInput input) {
    input.validate();
    throw _customerWritePending;
  }

  @override
  Future<CustomerAddress> updateAddress(
    String addressId,
    CustomerAddressInput input,
  ) {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    input.validate();
    throw _customerWritePending;
  }

  @override
  Future<void> deleteAddress(String addressId) {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    throw _customerWritePending;
  }

  @override
  Future<void> setDefaultShippingAddress(String addressId) {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    throw _customerWritePending;
  }

  @override
  Future<void> setDefaultBillingAddress(String addressId) {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    throw _customerWritePending;
  }

  @override
  Future<PaginatedResult<CustomerOrder>> fetchOrders(
    PaginationRequest pagination,
  ) {
    throw const AppException(
      kind: AppErrorKind.api,
      message: 'Customer Account order queries are not configured yet.',
      code: 'customer_orders_not_configured',
    );
  }

  @override
  Future<void> logout() async {
    final session = await restoreSession();
    await tokenStore.clear();
    _activeSession = null;
    if (session != null) {
      try {
        await authCoordinator?.revokeOrLogout(session);
      } on Object {
        // Local sign-out is authoritative. A temporary Shopify logout outage
        // must not leave the app looking signed in or surface a false failure.
      }
    }
  }
}
