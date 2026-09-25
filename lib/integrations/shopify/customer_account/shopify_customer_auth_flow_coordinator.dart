import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/integrations/shopify/customer_account/customer_account_client.dart';
import 'package:flexwolf/integrations/shopify/shopify_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopifyCustomerAuthFlowCoordinator
    implements CustomerAuthFlowCoordinator, CustomerAccountEndpointDiscovery {
  ShopifyCustomerAuthFlowCoordinator({
    required this.shopifyConfig,
    AppLinks? appLinks,
    HttpClient? httpClient,
    Future<bool> Function(Uri uri)? launchUri,
    this.clearBrowserSession,
    Random? random,
    this.callbackStream,
    this.callbackTimeout = const Duration(minutes: 3),
  }) : _appLinks = appLinks ?? AppLinks(),
       _httpClient = httpClient ?? HttpClient(),
       _launchUri = launchUri ?? _launchAccountAuthorization,
       _random = random ?? Random.secure();

  final ShopifyConfig shopifyConfig;
  final AppLinks _appLinks;
  final HttpClient _httpClient;
  final Future<bool> Function(Uri uri) _launchUri;
  final Future<void> Function()? clearBrowserSession;
  final Random _random;
  final Stream<Uri>? callbackStream;
  final Duration callbackTimeout;

  @override
  Future<Uri> buildAuthorizationUri({
    required String codeChallenge,
    required String state,
  }) async {
    _ensureConfigured();
    final discovery = await _discoverAuthConfiguration();
    return discovery.authorizationEndpoint.replace(
      queryParameters: <String, String>{
        'scope': 'openid email customer-account-api:full',
        'client_id': shopifyConfig.customerAccountClientId!.trim(),
        'response_type': 'code',
        'redirect_uri': shopifyConfig.customerAccountRedirectUri!.trim(),
        'state': state,
        'nonce': _randomToken(),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  @override
  Future<CustomerSession> authenticate({required bool rememberSession}) =>
      _authorize(rememberSession: rememberSession, silent: false);

  @override
  Future<CustomerSession> renewSilently({required bool rememberSession}) =>
      _authorize(rememberSession: rememberSession, silent: true);

  Future<CustomerSession> _authorize({
    required bool rememberSession,
    required bool silent,
  }) async {
    final codeVerifier = _pkceVerifier();
    final codeChallenge = _pkceChallenge(codeVerifier);
    final state = _randomToken();
    var authUri = await buildAuthorizationUri(
      codeChallenge: codeChallenge,
      state: state,
    );
    if (silent) {
      authUri = authUri.replace(
        queryParameters: <String, String>{
          ...authUri.queryParameters,
          'prompt': 'none',
        },
      );
    }

    // Subscribe before opening the browser: immediate callbacks must not be lost.
    final callbacks = StreamController<Uri>();
    final subscription = (callbackStream ?? _appLinks.uriLinkStream).listen(
      callbacks.add,
      onError: callbacks.addError,
    );
    try {
      final launched = await _launchUri(authUri);
      if (!launched) {
        throw const AppException(
          kind: AppErrorKind.unavailable,
          message: 'Could not open customer login. Please try again.',
          code: 'customer_auth_browser_unavailable',
          isRetryable: true,
        );
      }
      final callback = await _waitForCallback(state, callbacks.stream);
      final session = await exchangeAuthorizationCode(
        code: callback.queryParameters['code']!,
        codeVerifier: codeVerifier,
      );
      return CustomerSession(
        accessToken: session.accessToken,
        idToken: session.idToken,
        expiresAt: session.expiresAt,
        remembered: rememberSession,
      );
    } on TimeoutException {
      throw const AppException(
        kind: AppErrorKind.timeout,
        message: 'Sign-in was not completed. Please try again.',
        code: 'customer_auth_callback_timeout',
        isRetryable: true,
      );
    } finally {
      await subscription.cancel();
      unawaited(callbacks.close());
    }
  }

  @override
  Future<CustomerSession> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    _ensureConfigured();
    final discovery = await _discoverAuthConfiguration();
    final response = await _postForm(discovery.tokenEndpoint, <String, String>{
      'grant_type': 'authorization_code',
      'client_id': shopifyConfig.customerAccountClientId!.trim(),
      'redirect_uri': shopifyConfig.customerAccountRedirectUri!.trim(),
      'code': code,
      'code_verifier': codeVerifier,
    });

    final accessToken = response['access_token'];
    final idToken = response['id_token'];
    final expiresIn = response['expires_in'];
    if (accessToken is! String || accessToken.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Shopify did not return a customer access token.',
        code: 'customer_auth_token_missing',
      );
    }

    final expiresAt = DateTime.now().toUtc().add(
      Duration(seconds: expiresIn is int ? expiresIn : 3600),
    );
    return CustomerSession(
      accessToken: accessToken.trim(),
      idToken: idToken is String ? idToken : null,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> revokeOrLogout(CustomerSession session) async {
    try {
      _ensureConfigured();
      final idToken = session.idToken?.trim();
      if (idToken != null && idToken.isNotEmpty) {
        final discovery = await _discoverAuthConfiguration();
        final logoutUri = discovery.logoutEndpoint.replace(
          queryParameters: <String, String>{'id_token_hint': idToken},
        );
        await _sendLogoutRequest(logoutUri);
      }
    } finally {
      // HttpClient and WebView do not share a cookie jar.
      await clearBrowserSession?.call();
    }
  }

  @override
  Future<CustomerAccountAuthConfiguration> discover(ShopifyConfig config) =>
      _discoverAuthConfiguration();

  Future<CustomerAccountAuthConfiguration> _discoverAuthConfiguration() async {
    final openId = await _getJson(
      shopifyConfig.customerAccountOpenIdDiscoveryEndpoint(),
    );
    final customerApi = await _getJson(
      shopifyConfig.customerAccountApiDiscoveryEndpoint(),
    );

    final authorizationEndpoint = openId['authorization_endpoint'];
    final tokenEndpoint = openId['token_endpoint'];
    final logoutEndpoint = openId['end_session_endpoint'];
    final graphqlEndpoint =
        customerApi['customer_account_api_endpoint'] ??
        customerApi['graphql_endpoint'] ??
        customerApi['graphql_api'];

    if (authorizationEndpoint is! String ||
        tokenEndpoint is! String ||
        logoutEndpoint is! String ||
        graphqlEndpoint is! String) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Shopify Customer Account discovery response is incomplete.',
        code: 'customer_account_discovery_invalid',
        isRetryable: true,
      );
    }

    return CustomerAccountAuthConfiguration(
      authorizationEndpoint: Uri.parse(authorizationEndpoint),
      tokenEndpoint: Uri.parse(tokenEndpoint),
      logoutEndpoint: Uri.parse(logoutEndpoint),
      graphqlEndpoint: Uri.parse(graphqlEndpoint),
    );
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'FLEXWOLF mobile app');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          kind: AppErrorKind.api,
          message: 'Shopify discovery failed with HTTP ${response.statusCode}.',
          code: 'customer_account_discovery_http_error',
          isRetryable: true,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
      throw const FormatException('Expected JSON object.');
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppException(
        kind: AppErrorKind.timeout,
        message: 'Shopify Customer Account request timed out.',
        code: 'customer_account_timeout',
        cause: error,
        isRetryable: true,
      );
    } on Object catch (error) {
      throw AppException(
        kind: AppErrorKind.network,
        message: 'Could not reach Shopify Customer Account endpoints.',
        code: 'customer_account_network_failure',
        cause: error,
        isRetryable: true,
      );
    }
  }

  Future<Map<String, Object?>> _postForm(
    Uri uri,
    Map<String, String> form,
  ) async {
    try {
      final request = await _httpClient.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'FLEXWOLF mobile app');
      request.write(Uri(queryParameters: form).query);
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await utf8.decodeStream(response);
      final decoded = body.isEmpty ? <String, Object?>{} : jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          kind: AppErrorKind.authentication,
          message: 'Shopify customer login failed.',
          code: 'customer_auth_token_exchange_failed',
          cause: decoded,
          isRetryable: true,
        );
      }
      if (decoded is Map<String, Object?>) return decoded;
      throw const FormatException('Expected JSON object.');
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppException(
        kind: AppErrorKind.timeout,
        message: 'Shopify token exchange timed out.',
        code: 'customer_auth_timeout',
        cause: error,
        isRetryable: true,
      );
    } on Object catch (error) {
      throw AppException(
        kind: AppErrorKind.network,
        message: 'Could not complete Shopify customer login.',
        code: 'customer_auth_network_failure',
        cause: error,
        isRetryable: true,
      );
    }
  }

  Future<void> _sendLogoutRequest(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'FLEXWOLF mobile app');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          kind: AppErrorKind.authentication,
          message: 'Shopify customer logout failed.',
          code: 'customer_logout_failed',
          isRetryable: true,
        );
      }
    } on AppException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AppException(
        kind: AppErrorKind.timeout,
        message: 'Shopify customer logout timed out.',
        code: 'customer_logout_timeout',
        cause: error,
        isRetryable: true,
      );
    } on Object catch (error) {
      throw AppException(
        kind: AppErrorKind.network,
        message: 'Could not complete Shopify customer logout.',
        code: 'customer_logout_network_failure',
        cause: error,
        isRetryable: true,
      );
    }
  }

  Future<Uri> _waitForCallback(
    String expectedState,
    Stream<Uri> callbacks,
  ) async {
    final redirectUri = Uri.parse(
      shopifyConfig.customerAccountRedirectUri!.trim(),
    );
    final callback = await callbacks
        .firstWhere((uri) {
          return uri.scheme == redirectUri.scheme &&
              uri.host == redirectUri.host &&
              uri.port == redirectUri.port &&
              uri.path == redirectUri.path;
        })
        .timeout(callbackTimeout);

    if (callback.queryParameters['state'] != expectedState) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Shopify login state check failed.',
        code: 'customer_auth_state_mismatch',
      );
    }
    final error = callback.queryParameters['error'];
    if (error != null) {
      throw AppException(
        kind: AppErrorKind.authentication,
        message: 'Shopify customer login was not completed.',
        code: 'customer_auth_$error',
        isRetryable: true,
      );
    }
    if ((callback.queryParameters['code'] ?? '').isEmpty) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message:
            'Shopify login callback did not include an authorization code.',
        code: 'customer_auth_code_missing',
      );
    }
    return callback;
  }

  void _ensureConfigured() {
    if (!shopifyConfig.hasShopDomain ||
        !shopifyConfig.hasCustomerAccountClient ||
        (shopifyConfig.customerAccountRedirectUri?.trim().isEmpty ?? true)) {
      throw const AppException(
        kind: AppErrorKind.unavailable,
        message: 'Shopify Customer Account OAuth is not configured. Add shop domain, client id, and redirect URI.',
        code: 'customer_auth_not_configured',
        isRetryable: true,
      );
    }
    final redirect = Uri.tryParse(
      shopifyConfig.customerAccountRedirectUri!.trim(),
    );
    if (redirect == null ||
        !redirect.hasScheme ||
        !redirect.scheme.startsWith('shop.') ||
        redirect.host.isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Shopify mobile callback must use the shop.{shop_id}.* custom scheme configured for this app.',
        code: 'customer_auth_redirect_invalid',
      );
    }
  }

  String _pkceVerifier() => _randomToken(byteLength: 64);

  String _pkceChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _randomToken({int byteLength = 32}) {
    final bytes = List<int>.generate(byteLength, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

Future<bool> _launchAccountAuthorization(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}
