import 'package:flexwolf/app/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger(ref.watch(appConfigProvider));
});

class AppLogger {
  const AppLogger(this._config);

  final AppConfig _config;

  void debug(String message, {Object? error}) {
    if (_config.allowsVerboseLogging) {
      _write('DEBUG', message, error: error);
    }
  }

  void info(String message) {
    if (!_config.environment.isProduction ||
        _config.featureFlags.enableDiagnostics) {
      _write('INFO', message);
    }
  }

  void warning(String message, {Object? error}) {
    _write('WARN', message, error: error);
  }

  void error(String message, {Object? error}) {
    _write('ERROR', message, error: error);
  }

  void _write(String level, String message, {Object? error}) {
    final sanitized = _sanitize(message);
    final detail = error == null || !_config.allowsVerboseLogging
        ? ''
        : ' error=$error';
    debugPrint('[$level] ${_config.environment.label}: $sanitized$detail');
  }

  String _sanitize(String value) {
    return value
        .replaceAll(
          RegExp(r'authorization:\s*bearer\s+[^\s]+', caseSensitive: false),
          'authorization: Bearer <redacted>',
        )
        .replaceAll(
          RegExp(r'access[_-]?token=[^&\s]+', caseSensitive: false),
          'access_token=<redacted>',
        )
        .replaceAll(
          RegExp(r'password=[^&\s]+', caseSensitive: false),
          'password=<redacted>',
        )
        .replaceAll(
          RegExp(r'api[_-]?key=[^&\s]+', caseSensitive: false),
          'api_key=<redacted>',
        )
        .replaceAll(
          RegExp(r'(secret|token|key)[:=][^&\s]+', caseSensitive: false),
          r'$1=<redacted>',
        );
  }
}
