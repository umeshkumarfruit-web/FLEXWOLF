import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';

abstract interface class CustomerAccountRepository {
  Future<CustomerSession?> restoreSession();

  Future<CustomerSession> login({
    required String email,
    required String password,
    required bool rememberSession,
    bool createAccount = false,
  });

  Future<void> handleUnauthorized();

  Future<CustomerProfile?> fetchProfile();

  Future<List<CustomerAddress>> fetchAddresses();

  Future<CustomerProfile> updateProfile(CustomerProfileInput input);

  Future<void> setEmailMarketing(bool subscribed);

  Future<CustomerAddress> addAddress(CustomerAddressInput input);

  Future<CustomerAddress> updateAddress(
    String addressId,
    CustomerAddressInput input,
  );

  Future<void> deleteAddress(String addressId);

  Future<void> setDefaultShippingAddress(String addressId);

  Future<void> setDefaultBillingAddress(String addressId);

  Future<PaginatedResult<CustomerOrder>> fetchOrders(
    PaginationRequest pagination,
  );

  Future<void> logout();
}

class CustomerSession {
  const CustomerSession({
    required this.accessToken,
    required this.expiresAt,
    this.idToken,
    this.remembered = true,
    this.tokenKind = CustomerTokenKind.shopifyCustomerAccessToken,
  });

  final String accessToken;
  final String? idToken;
  final DateTime expiresAt;
  final bool remembered;
  final CustomerTokenKind tokenKind;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canAuthenticateShopify =>
      tokenKind == CustomerTokenKind.shopifyCustomerAccessToken;
}

enum CustomerTokenKind { shopifyCustomerAccessToken, firebaseIdToken }

abstract interface class CustomerAuthFlowCoordinator {
  Future<CustomerSession> authenticate({required bool rememberSession});

  Future<Uri> buildAuthorizationUri({
    required String codeChallenge,
    required String state,
  });

  Future<CustomerSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  });

  Future<CustomerSession> renewSilently({required bool rememberSession});

  Future<void> revokeOrLogout(CustomerSession session);
}

class CustomerProfileInput {
  const CustomerProfileInput({
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String? phone;

  void validate() {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw const FormatException('Customer name is required.');
    }
  }
}

class CustomerAddressInput {
  const CustomerAddressInput({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.city,
    required this.country,
    required this.zip,
    this.company,
    this.address2,
    this.province,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String? company;
  final String address1;
  final String? address2;
  final String city;
  final String? province;
  final String country;
  final String zip;
  final String? phone;

  void validate() {
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        address1.trim().isEmpty ||
        city.trim().isEmpty ||
        country.trim().isEmpty ||
        zip.trim().isEmpty) {
      throw const FormatException('Required address fields are missing.');
    }
  }
}
