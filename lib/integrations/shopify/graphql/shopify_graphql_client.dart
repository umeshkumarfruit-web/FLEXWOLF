import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/core/security/security_policy.dart';

abstract interface class ShopifyGraphqlClient {
  Future<ShopifyGraphqlResponse> query(
    ShopifyGraphqlRequest request, {
    CancellationToken? cancelToken,
  });
}

class ShopifyGraphqlHttpClient implements ShopifyGraphqlClient {
  ShopifyGraphqlHttpClient({
    required this.endpoint,
    required this.config,
    required this.logger,
    required this.headersBuilder,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient() {
    SecurityPolicy.requireHttpsUri(
      endpoint,
      context: 'Shopify GraphQL endpoint',
    );
  }

  final Uri endpoint;
  final AppConfig config;
  final AppLogger logger;
  final Map<String, String> Function() headersBuilder;
  final HttpClient _httpClient;

  @override
  Future<ShopifyGraphqlResponse> query(
    ShopifyGraphqlRequest request, {
    CancellationToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const AppException(
        kind: AppErrorKind.unexpected,
        message: 'GraphQL request was cancelled before sending.',
        code: 'shopify_request_cancelled',
      );
    }

    try {
      final httpRequest = await _httpClient
          .postUrl(endpoint)
          .timeout(request.timeout ?? config.networkTimeout);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-store',
        ...headersBuilder(),
      };

      for (final entry in headers.entries) {
        httpRequest.headers.set(entry.key, entry.value);
      }

      httpRequest.write(
        jsonEncode({
          'query': request.document,
          if (request.operationName != null)
            'operationName': request.operationName,
          if (request.variables.isNotEmpty) 'variables': request.variables,
        }),
      );

      final response = await httpRequest.close().timeout(
        request.timeout ?? config.networkTimeout,
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 429) {
        throw const AppException(
          kind: AppErrorKind.api,
          message: 'Shopify throttled the request.',
          code: 'shopify_throttled',
          isRetryable: true,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          kind: AppErrorKind.api,
          message: 'Shopify returned HTTP ${response.statusCode}.',
          code: 'shopify_http_error',
          isRetryable: response.statusCode >= 500,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const AppException(
          kind: AppErrorKind.api,
          message: 'Shopify returned an invalid GraphQL response.',
          code: 'shopify_invalid_response',
        );
      }

      final errors = decoded['errors'];
      if (errors is List && errors.isNotEmpty) {
        throw AppException(
          kind: AppErrorKind.api,
          message: 'Shopify GraphQL returned ${errors.length} error(s).',
          code: 'shopify_graphql_errors',
        );
      }

      return ShopifyGraphqlResponse(
        data: decoded['data'],
        extensions: decoded['extensions'],
      );
    } on TimeoutException catch (error) {
      throw AppException(
        kind: AppErrorKind.timeout,
        message: 'Shopify request timed out.',
        code: 'shopify_timeout',
        cause: error,
        isRetryable: true,
      );
    } on SocketException catch (error) {
      throw AppException(
        kind: AppErrorKind.network,
        message: 'Network failure while contacting Shopify.',
        code: 'shopify_network_failure',
        cause: error,
        isRetryable: true,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      logger.warning('Shopify GraphQL request failed.', error: error);
      throw mapUnknownException(error);
    }
  }
}

class ShopifyGraphqlRequest {
  const ShopifyGraphqlRequest({
    required this.document,
    this.operationName,
    this.variables = const <String, Object?>{},
    this.timeout,
    this.isMutation = false,
  });

  final String document;
  final String? operationName;
  final Map<String, Object?> variables;
  final Duration? timeout;
  final bool isMutation;
}

class ShopifyGraphqlResponse {
  const ShopifyGraphqlResponse({this.data, this.extensions});

  final Object? data;
  final Object? extensions;
}
