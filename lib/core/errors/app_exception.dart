enum AppErrorKind {
  network,
  timeout,
  authentication,
  api,
  validation,
  unavailable,
  checkout,
  unexpected,
}

class AppException implements Exception {
  const AppException({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
    this.isRetryable = false,
  });

  final AppErrorKind kind;
  final String message;
  final String? code;
  final Object? cause;
  final bool isRetryable;

  String get userMessage {
    switch (kind) {
      case AppErrorKind.network:
        return 'Connection problem. Check your network and try again.';
      case AppErrorKind.timeout:
        return 'The request took too long. Try again.';
      case AppErrorKind.authentication:
        return 'Please sign in again to continue.';
      case AppErrorKind.api:
        return 'Something went wrong while loading this information.';
      case AppErrorKind.validation:
        return message;
      case AppErrorKind.unavailable:
        return 'This item is currently unavailable.';
      case AppErrorKind.checkout:
        return 'Checkout could not be completed. Try again.';
      case AppErrorKind.unexpected:
        return 'Something went wrong. Try again.';
    }
  }

  @override
  String toString() {
    final codePrefix = code == null ? '' : '[$code] ';
    return 'AppException.${kind.name}: $codePrefix$message';
  }
}

AppException mapUnknownException(Object error) {
  if (error is AppException) {
    return error;
  }

  return AppException(
    kind: AppErrorKind.unexpected,
    message: 'Unexpected application failure.',
    cause: error,
  );
}
