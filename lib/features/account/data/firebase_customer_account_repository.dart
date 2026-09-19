import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';

class FirebaseCustomerAccountRepository implements CustomerAccountRepository {
  FirebaseCustomerAccountRepository({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  static const _shopifySyncEnabled = bool.fromEnvironment(
    'ENABLE_SHOPIFY_CUSTOMER_SYNC',
  );
  CustomerProfile? _profile;

  @override
  Future<CustomerSession?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _sessionFor(user, remembered: true);
  }

  @override
  Future<CustomerSession> login({
    required String email,
    required String password,
    required bool rememberSession,
    bool createAccount = false,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Enter a valid email address.',
        code: 'customer_email_invalid',
      );
    }
    if (password.length < 6) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Password must contain at least 6 characters.',
        code: 'customer_password_too_short',
      );
    }

    try {
      final credential = createAccount
          ? await _auth.createUserWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            )
          : await _auth.signInWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          kind: AppErrorKind.authentication,
          message: 'Firebase did not return a signed-in customer.',
          code: 'firebase_customer_missing',
        );
      }
      _profile = await _syncCustomerOrFirebaseProfile(user);
      return await _sessionFor(user, remembered: rememberSession);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  Future<CustomerSession> _sessionFor(
    User user, {
    required bool remembered,
  }) async {
    final tokenResult = await user.getIdTokenResult();
    final token = tokenResult.token;
    if (token == null || token.isEmpty) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Could not create a secure Firebase session.',
        code: 'firebase_id_token_missing',
      );
    }
    return CustomerSession(
      accessToken: token,
      expiresAt:
          tokenResult.expirationTime ??
          DateTime.now().add(const Duration(hours: 1)),
      remembered: remembered,
      tokenKind: CustomerTokenKind.firebaseIdToken,
    );
  }

  Future<CustomerProfile> _syncCustomer({
    String? firstName,
    String? lastName,
  }) async {
    final result = await _functions.httpsCallable('syncCustomerAccount').call({
      'firstName': ?firstName,
      'lastName': ?lastName,
    });
    final data = Map<String, Object?>.from(result.data as Map);
    final uid = data['uid'] as String? ?? _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Customer sync returned an invalid profile.',
        code: 'customer_sync_profile_invalid',
      );
    }
    return CustomerProfile(
      id: data['shopifyCustomerId'] as String? ?? uid,
      displayName: data['displayName'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String? ?? _auth.currentUser?.email,
    );
  }

  Future<CustomerProfile> _syncCustomerOrFirebaseProfile(User user) async {
    if (!_shopifySyncEnabled) return _firebaseProfile(user);
    try {
      return await _syncCustomer();
    } on FirebaseFunctionsException {
      // Firebase Authentication is authoritative for app access. Shopify sync
      // is retried when the profile is next loaded after the backend deploys.
      return _firebaseProfile(user);
    }
  }

  CustomerProfile _firebaseProfile(User user) {
    final name = user.displayName?.trim();
    final parts = name == null || name.isEmpty
        ? const <String>[]
        : name.split(' ');
    return CustomerProfile(
      id: user.uid,
      displayName: name ?? user.email,
      firstName: parts.isEmpty ? null : parts.first,
      lastName: parts.length < 2 ? null : parts.sublist(1).join(' '),
      email: user.email,
      phone: user.phoneNumber,
    );
  }

  @override
  Future<void> handleUnauthorized() => _auth.signOut();

  @override
  Future<CustomerProfile?> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _profile ??= await _syncCustomerOrFirebaseProfile(user);
  }

  @override
  Future<List<CustomerAddress>> fetchAddresses() async => const [];

  @override
  Future<CustomerProfile> updateProfile(CustomerProfileInput input) async {
    input.validate();
    await _auth.currentUser?.updateDisplayName(
      '${input.firstName.trim()} ${input.lastName.trim()}'.trim(),
    );
    if (!_shopifySyncEnabled) {
      return _profile = _firebaseProfile(_auth.currentUser!);
    }
    try {
      return _profile = await _syncCustomer(
        firstName: input.firstName.trim(),
        lastName: input.lastName.trim(),
      );
    } on FirebaseFunctionsException {
      return _profile = _firebaseProfile(_auth.currentUser!);
    }
  }

  AppException get _addressUnavailable => const AppException(
    kind: AppErrorKind.unavailable,
    message:
        'Address management will be available after Shopify account linking.',
    code: 'firebase_customer_address_unavailable',
  );

  @override
  Future<CustomerAddress> addAddress(CustomerAddressInput input) {
    input.validate();
    throw _addressUnavailable;
  }

  @override
  Future<CustomerAddress> updateAddress(
    String addressId,
    CustomerAddressInput input,
  ) {
    input.validate();
    throw _addressUnavailable;
  }

  @override
  Future<void> deleteAddress(String addressId) => throw _addressUnavailable;

  @override
  Future<void> setDefaultShippingAddress(String addressId) =>
      throw _addressUnavailable;

  @override
  Future<void> setDefaultBillingAddress(String addressId) =>
      throw _addressUnavailable;

  @override
  Future<PaginatedResult<CustomerOrder>> fetchOrders(
    PaginationRequest pagination,
  ) {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message: 'Order history will be available after Shopify account linking.',
      code: 'firebase_customer_orders_unavailable',
    );
  }

  @override
  Future<void> logout() async {
    _profile = null;
    await _auth.signOut();
  }
}

AppException _mapFirebaseAuthError(FirebaseAuthException error) {
  final message = switch (error.code) {
    'email-already-in-use' =>
      'An account already exists for this email. Sign in instead.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'Email or password is incorrect.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' =>
      'Network unavailable. Check your connection and retry.',
    _ => error.message ?? 'Could not authenticate your FLEXWOLF account.',
  };
  return AppException(
    kind: error.code == 'network-request-failed'
        ? AppErrorKind.network
        : AppErrorKind.authentication,
    message: message,
    code: 'firebase_auth_${error.code}',
    cause: error,
    isRetryable:
        error.code == 'network-request-failed' ||
        error.code == 'too-many-requests',
  );
}
