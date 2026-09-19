import 'package:flexwolf/core/errors/app_exception.dart';

abstract final class SecurityPolicy {
  static Uri requireHttpsUri(Uri uri, {required String context}) {
    if (!uri.hasScheme || uri.scheme != 'https') {
      throw AppException(
        kind: AppErrorKind.validation,
        message: '$context must use HTTPS.',
        code: 'https_required',
      );
    }
    if (uri.host.trim().isEmpty) {
      throw AppException(
        kind: AppErrorKind.validation,
        message: '$context host is required.',
        code: 'host_required',
      );
    }
    return uri;
  }

  static String requireHostName(String host, {required String context}) {
    final value = host.trim();
    if (value.isEmpty) {
      throw AppException(
        kind: AppErrorKind.validation,
        message: '$context host is required.',
        code: 'host_required',
      );
    }
    if (value.contains('://') || value.contains('/') || value.contains('\\')) {
      throw AppException(
        kind: AppErrorKind.validation,
        message: '$context must be a host name, not a URL.',
        code: 'host_name_required',
      );
    }
    return value;
  }

  static bool isHttpsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.trim().isNotEmpty;
  }
}
