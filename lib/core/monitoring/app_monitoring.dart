import 'dart:async';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flutter/painting.dart';

abstract final class MonitoringEvents {
  static const startupFailure = 'health_startup_failure';
  static const startupTime = 'performance_startup_time';
  static const apiFailure = 'health_api_failure';
  static const apiTimeout = 'health_api_timeout';
  static const apiLatency = 'performance_api_latency';
  static const authenticationFailure = 'health_authentication_failure';
  static const checkoutFailure = 'health_checkout_failure';
  static const notificationFailure = 'health_notification_failure';
  static const notificationTokenRegistration =
      'health_notification_token_registration';
  static const notificationDelivery = 'health_notification_delivery';
  static const notificationOpen = 'health_notification_open';
  static const connectivityChanged = 'health_connectivity_changed';
  static const retrySuccess = 'health_retry_success';
  static const memoryUsage = 'performance_memory_usage';
  static const imageCache = 'performance_image_cache';
}

enum AppHealthArea { startup, api, authentication, checkout, notification }

class MonitoringGateway {
  MonitoringGateway({
    required AnalyticsGateway analytics,
    required FirebaseCrashReportingGateway crashReporting,
  }) : this._(ValidatingAnalyticsGateway(analytics), crashReporting);

  MonitoringGateway._(this._analytics, this._crashReporting);

  final AnalyticsGateway _analytics;
  final FirebaseCrashReportingGateway _crashReporting;
  static const _maxRecentEventKeys = 256;
  final Set<String> _recentEventKeys = <String>{};

  Future<void> recordFatal(Object error, StackTrace stackTrace) =>
      _crashReporting.recordFatal(error, stackTrace);

  Future<void> recordNonFatal(Object error, StackTrace stackTrace) =>
      _crashReporting.recordNonFatal(error, stackTrace);

  Future<void> trackStartupFailure(Object error, StackTrace stackTrace) async {
    await recordFatal(error, stackTrace);
    await _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.startupFailure,
        parameters: _failureParameters(AppHealthArea.startup, error),
      ),
    );
  }

  Future<void> trackFailure(
    AppHealthArea area,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    if (stackTrace != null) {
      await recordNonFatal(error, stackTrace);
    }
    await _trackOnce(
      AnalyticsEvent(
        name: _eventForArea(area),
        parameters: _failureParameters(area, error),
      ),
    );
  }

  Future<void> trackApiLatency({
    required String path,
    required Duration latency,
    required bool success,
  }) {
    return _track(
      AnalyticsEvent(
        name: MonitoringEvents.apiLatency,
        parameters: {
          'path': _safePath(path),
          'latency_ms': latency.inMilliseconds,
          'success': success,
        },
      ),
    );
  }

  Future<void> trackApiTimeout(String path) {
    return _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.apiTimeout,
        parameters: {'path': _safePath(path)},
      ),
    );
  }

  Future<void> trackConnectivity(ConnectivitySnapshot snapshot) {
    return _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.connectivityChanged,
        parameters: {
          'quality': snapshot.quality.name,
          'retry_recommended': snapshot.isRetryRecommended,
        },
      ),
    );
  }

  Future<void> trackRetrySuccess(String operation) {
    return _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.retrySuccess,
        parameters: {'operation': operation},
      ),
    );
  }

  Future<void> trackNotificationTokenRegistration({required bool success}) {
    return _track(
      AnalyticsEvent(
        name: MonitoringEvents.notificationTokenRegistration,
        parameters: {'success': success},
      ),
    );
  }

  Future<void> trackNotificationDelivery(String notificationId) {
    return _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.notificationDelivery,
        parameters: {'notification_id': notificationId},
      ),
    );
  }

  Future<void> trackNotificationOpen(String notificationId) {
    return _trackOnce(
      AnalyticsEvent(
        name: MonitoringEvents.notificationOpen,
        parameters: {'notification_id': notificationId},
      ),
    );
  }

  Future<void> trackStartupTime(Duration startupTime) {
    return _track(
      AnalyticsEvent(
        name: MonitoringEvents.startupTime,
        parameters: {'startup_ms': startupTime.inMilliseconds},
      ),
    );
  }

  Future<void> trackMemoryUsage({required int usedBytes}) {
    return _track(
      AnalyticsEvent(
        name: MonitoringEvents.memoryUsage,
        parameters: {'used_bytes': usedBytes},
      ),
    );
  }

  Future<void> trackImageCache({ImageCache? cache}) {
    final imageCache = cache ?? PaintingBinding.instance.imageCache;
    return _track(
      AnalyticsEvent(
        name: MonitoringEvents.imageCache,
        parameters: {
          'current_size': imageCache.currentSize,
          'live_image_count': imageCache.liveImageCount,
          'pending_image_count': imageCache.pendingImageCount,
          'current_size_bytes': imageCache.currentSizeBytes,
          'maximum_size_bytes': imageCache.maximumSizeBytes,
        },
      ),
    );
  }

  Future<void> _track(AnalyticsEvent event) => _analytics.track(event);

  Future<void> _trackOnce(AnalyticsEvent event) {
    final key = _eventKey(event);
    if (_recentEventKeys.contains(key)) return Future<void>.value();
    if (_recentEventKeys.length >= _maxRecentEventKeys) {
      _recentEventKeys.remove(_recentEventKeys.first);
    }
    _recentEventKeys.add(key);
    return _track(event);
  }
}

class ValidatingAnalyticsGateway implements AnalyticsGateway {
  const ValidatingAnalyticsGateway(this._delegate);

  final AnalyticsGateway _delegate;

  @override
  Future<void> track(AnalyticsEvent event) {
    final normalized = event.name.trim();
    if (!_isValidEventName(normalized)) return Future<void>.value();
    final parameters = Map<String, Object?>.from(event.parameters)
      ..removeWhere((key, value) => !_isValidParameterValue(value));
    return _delegate.track(
      AnalyticsEvent(
        name: normalized,
        parameters: Map<String, Object?>.unmodifiable(
          parameters.map(
            (key, value) => MapEntry(_normalizeParameterName(key), value),
          ),
        ),
      ),
    );
  }
}

class MonitoredApiClient implements ApiClient {
  const MonitoredApiClient({
    required ApiClient delegate,
    required MonitoringGateway monitoring,
  }) : this._(delegate, monitoring);

  const MonitoredApiClient._(this._delegate, this._monitoring);

  final ApiClient _delegate;
  final MonitoringGateway _monitoring;

  @override
  AppConfig get config => _delegate.config;

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    CancellationToken? cancelToken,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final response = await _delegate.send(request, cancelToken: cancelToken);
      await _monitoring.trackApiLatency(
        path: request.path,
        latency: watch.elapsed,
        success: response.isSuccess,
      );
      if (!response.isSuccess) {
        await _monitoring.trackFailure(
          AppHealthArea.api,
          AppException(
            kind: AppErrorKind.api,
            message: 'API returned HTTP ${response.statusCode}.',
            code: 'api_http_error',
            isRetryable: response.statusCode >= 500,
          ),
          StackTrace.current,
        );
      }
      return response;
    } on TimeoutException catch (error, stackTrace) {
      await _monitoring.trackApiTimeout(request.path);
      await _monitoring.trackFailure(
        AppHealthArea.api,
        AppException(
          kind: AppErrorKind.timeout,
          message: 'API request timed out.',
          code: 'api_timeout',
          cause: error,
          isRetryable: true,
        ),
        stackTrace,
      );
      rethrow;
    } on AppException catch (error, stackTrace) {
      await _monitoring.trackFailure(AppHealthArea.api, error, stackTrace);
      rethrow;
    }
  }
}

Map<String, Object?> _failureParameters(AppHealthArea area, Object error) {
  if (error is AppException) {
    return {
      'area': area.name,
      'kind': error.kind.name,
      if (error.code != null) 'code': error.code,
      'retryable': error.isRetryable,
    };
  }
  return {'area': area.name, 'kind': 'unexpected'};
}

String _eventForArea(AppHealthArea area) {
  switch (area) {
    case AppHealthArea.startup:
      return MonitoringEvents.startupFailure;
    case AppHealthArea.api:
      return MonitoringEvents.apiFailure;
    case AppHealthArea.authentication:
      return MonitoringEvents.authenticationFailure;
    case AppHealthArea.checkout:
      return MonitoringEvents.checkoutFailure;
    case AppHealthArea.notification:
      return MonitoringEvents.notificationFailure;
  }
}

String _eventKey(AnalyticsEvent event) {
  final keys = event.parameters.keys.toList()..sort();
  final parameterKey = keys
      .map((key) => '$key=${event.parameters[key]}')
      .join('|');
  return '${event.name}|$parameterKey';
}

String _safePath(String path) {
  final queryIndex = path.indexOf('?');
  return queryIndex == -1 ? path : path.substring(0, queryIndex);
}

String _normalizeParameterName(String key) {
  final normalized = key.trim().toLowerCase().replaceAll(
    RegExp('[^a-z0-9_]'),
    '_',
  );
  return normalized.isEmpty ? 'parameter' : normalized;
}

bool _isValidEventName(String name) {
  return RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(name);
}

bool _isValidParameterValue(Object? value) {
  return value == null || value is String || value is num || value is bool;
}
