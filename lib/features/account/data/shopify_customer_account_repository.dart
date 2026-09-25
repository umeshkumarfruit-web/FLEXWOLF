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
  Future<CustomerSession?>? _renewInFlight;
  int _sessionEpoch = 0;

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
    if (!tokenSet.remembered) {
      await tokenStore.clear();
      return null;
    }
    if (tokenSet.isExpired) {
      final coordinator = authCoordinator;
      if (coordinator == null ||
          !client.shopifyConfig.hasCustomerAccountClient) {
        await tokenStore.clear();
        return null;
      }
      return _renewInFlight ??= _renewSession(coordinator).whenComplete(() {
        _renewInFlight = null;
      });
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
    _sessionEpoch++;
    _activeSession = null;
    await tokenStore.clear();
  }

  Future<Map<String, Object?>> _customerQuery(
    String document, {
    Map<String, Object?> variables = const <String, Object?>{},
  }) async {
    final session = await restoreSession();
    if (session == null) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Please sign in again to view your account.',
        code: 'customer_session_expired',
      );
    }
    return client.query(
      document,
      accessToken: session.accessToken,
      variables: variables,
    );
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
  Future<CustomerProfile> updateProfile(CustomerProfileInput input) async {
    input.validate();
    if (input.phone != null) {
      throw const AppException(
        kind: AppErrorKind.unavailable,
        message: 'Phone changes are not supported by this Shopify account connection.',
        code: 'customer_phone_update_unsupported',
      );
    }
    final payload = await _mutation(
      CustomerAccountQueries.profileUpdate,
      'customerUpdate',
      <String, Object?>{
        'input': <String, Object?>{
          'firstName': input.firstName.trim(),
          'lastName': input.lastName.trim(),
        },
      },
    );
    if (payload['customer'] is! Map<String, Object?>) {
      throw const FormatException(
        'Shopify did not confirm the profile update.',
      );
    }
    final profile = await fetchProfile();
    if (profile == null) {
      throw const FormatException(
        'Updated Shopify customer profile is missing.',
      );
    }
    return profile;
  }

  @override
  Future<void> setEmailMarketing(bool subscribed) async {
    final payload = await _mutation(
      subscribed
          ? CustomerAccountQueries.emailMarketingSubscribe
          : CustomerAccountQueries.emailMarketingUnsubscribe,
      subscribed
          ? 'customerEmailMarketingSubscribe'
          : 'customerEmailMarketingUnsubscribe',
      const <String, Object?>{},
    );
    if (payload['emailAddress'] is! Map<String, Object?>) {
      throw const FormatException(
        'Shopify did not confirm the marketing choice.',
      );
    }
  }

  Future<CustomerSession?> _renewSession(
    CustomerAuthFlowCoordinator coordinator,
  ) async {
    final epoch = _sessionEpoch;
    try {
      final renewed = await coordinator.renewSilently(rememberSession: true);
      if (epoch != _sessionEpoch) return null;
      await tokenStore.write(
        CustomerTokenSet(
          accessToken: renewed.accessToken,
          idToken: renewed.idToken,
          expiresAt: renewed.expiresAt,
        ),
      );
      return _activeSession = renewed;
    } on Object {
      if (epoch == _sessionEpoch) await tokenStore.clear();
      return null;
    }
  }

  @override
  Future<CustomerAddress> addAddress(CustomerAddressInput input) async {
    input.validate();
    final payload = await _mutation(
      CustomerAccountQueries.addressCreate,
      'customerAddressCreate',
      <String, Object?>{'address': _addressInput(input)},
    );
    return _addressFromPayload(payload);
  }

  @override
  Future<CustomerAddress> updateAddress(
    String addressId,
    CustomerAddressInput input,
  ) async {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    input.validate();
    final payload = await _mutation(
      CustomerAccountQueries.addressUpdate,
      'customerAddressUpdate',
      <String, Object?>{
        'addressId': addressId,
        'address': _addressInput(input),
      },
    );
    return _addressFromPayload(payload);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    final payload = await _mutation(
      CustomerAccountQueries.addressDelete,
      'customerAddressDelete',
      <String, Object?>{'addressId': addressId},
    );
    if (payload['deletedAddressId'] != addressId) {
      throw const FormatException('Shopify did not confirm address deletion.');
    }
  }

  @override
  Future<void> setDefaultShippingAddress(String addressId) async {
    if (addressId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Address id is required.',
        code: 'customer_address_id_required',
      );
    }
    final payload = await _mutation(
      CustomerAccountQueries.addressUpdate,
      'customerAddressUpdate',
      <String, Object?>{'addressId': addressId, 'defaultAddress': true},
    );
    _addressFromPayload(payload);
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
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message: 'Shopify customer accounts support one default address, not a separate default billing address.',
      code: 'customer_billing_default_unsupported',
    );
  }

  Future<Map<String, Object?>> _mutation(
    String document,
    String field,
    Map<String, Object?> variables,
  ) async {
    final data = await _customerQuery(document, variables: variables);
    final payload = data[field];
    if (payload is! Map<String, Object?>) {
      throw FormatException('Shopify $field response is missing.');
    }
    final errors = payload['userErrors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final message = first is Map ? first['message'] : null;
      throw AppException(
        kind: AppErrorKind.validation,
        message: message is String && message.isNotEmpty
            ? message
            : 'Shopify could not save your account changes.',
        code: 'customer_${field}_rejected',
      );
    }
    return payload;
  }

  CustomerAddress _addressFromPayload(Map<String, Object?> payload) {
    final address = payload['customerAddress'];
    if (address is! Map<String, Object?>) {
      throw const FormatException('Saved Shopify address is missing.');
    }
    return CustomerAddress.fromShopify(address);
  }

  Map<String, Object?> _addressInput(CustomerAddressInput input) {
    final countryCode = input.country.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Enter a two-letter country code, for example US or IN.',
        code: 'customer_country_code_invalid',
      );
    }
    final phone = input.phone?.trim();
    if (phone != null &&
        phone.isNotEmpty &&
        !RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phone)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Enter the phone number with country code, for example +15551234567.',
        code: 'customer_phone_invalid',
      );
    }
    return <String, Object?>{
      'firstName': input.firstName.trim(),
      'lastName': input.lastName.trim(),
      'address1': input.address1.trim(),
      if (input.address2?.trim().isNotEmpty ?? false)
        'address2': input.address2!.trim(),
      if (input.company?.trim().isNotEmpty ?? false)
        'company': input.company!.trim(),
      'city': input.city.trim(),
      'territoryCode': countryCode,
      if (input.province?.trim().isNotEmpty ?? false)
        'zoneCode': input.province!.trim(),
      'zip': input.zip.trim(),
      if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
    };
  }

  @override
  Future<PaginatedResult<CustomerOrder>> fetchOrders(
    PaginationRequest pagination,
  ) async {
    if (pagination.first < 1 || pagination.first > 50) {
      throw const FormatException('Order page size must be between 1 and 50.');
    }
    final data = await _customerQuery(
      CustomerAccountQueries.orders,
      variables: <String, Object?>{
        'first': pagination.first,
        'after': pagination.after,
      },
    );
    final customer = data['customer'];
    if (customer is! Map<String, Object?>) {
      throw const FormatException('Shopify customer orders are missing.');
    }
    final orders = customer['orders'];
    if (orders is! Map<String, Object?>) {
      throw const FormatException('Shopify order connection is missing.');
    }
    final nodes = orders['nodes'];
    final pageInfo = orders['pageInfo'];
    if (nodes is! List || pageInfo is! Map<String, Object?>) {
      throw const FormatException('Shopify order page is invalid.');
    }
    return PaginatedResult<CustomerOrder>(
      items: nodes
          .whereType<Map<String, Object?>>()
          .map(CustomerOrder.fromShopify)
          .toList(growable: false),
      pageInfo: PageInfo.fromShopify(pageInfo),
    );
  }

  @override
  Future<void> logout() async {
    _sessionEpoch++;
    final saved = await tokenStore.read();
    final session =
        _activeSession ??
        (saved == null
            ? null
            : CustomerSession(
                accessToken: saved.accessToken,
                idToken: saved.idToken,
                expiresAt: saved.expiresAt,
              ));
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
