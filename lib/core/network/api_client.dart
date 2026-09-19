import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';

abstract interface class ApiClient {
  AppConfig get config;

  Future<ApiResponse> send(
    ApiRequest request, {
    CancellationToken? cancelToken,
  });
}

class NoopApiClient implements ApiClient {
  const NoopApiClient(this.config);

  @override
  final AppConfig config;

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    CancellationToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const AppException(
        kind: AppErrorKind.unexpected,
        message: 'Request was cancelled before sending.',
        code: 'request_cancelled',
      );
    }

    throw const AppException(
      kind: AppErrorKind.network,
      message: 'No concrete API client is configured yet.',
      code: 'api_client_not_configured',
      isRetryable: true,
    );
  }
}

enum ApiMethod { get, post, put, patch, delete }

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.headers = const <String, String>{},
    this.query = const <String, String>{},
    this.body,
    this.timeout,
  });

  final ApiMethod method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> query;
  final Object? body;
  final Duration? timeout;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.headers,
    this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Object? body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
