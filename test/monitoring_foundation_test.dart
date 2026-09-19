import 'dart:async';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/monitoring/app_monitoring.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitoring reports fatal startup and suppresses duplicates', () async {
    final analytics = _Analytics();
    final crash = _CrashReporting();
    final monitoring = MonitoringGateway(
      analytics: analytics,
      crashReporting: crash,
    );
    final error = StateError('startup failed');

    await monitoring.trackStartupFailure(error, StackTrace.current);
    await monitoring.trackStartupFailure(error, StackTrace.current);

    expect(crash.fatalCount, 2);
    expect(analytics.events.map((event) => event.name), const [
      MonitoringEvents.startupFailure,
    ]);
  });

  test(
    'analytics validation rejects invalid events and unsafe values',
    () async {
      final analytics = _Analytics();
      final gateway = ValidatingAnalyticsGateway(analytics);

      await gateway.track(const AnalyticsEvent(name: 'Invalid Name'));
      await gateway.track(
        AnalyticsEvent(
          name: 'valid_event',
          parameters: {'Bad Param': 'ok', 'object': Object(), 'count': 1},
        ),
      );

      expect(analytics.events, hasLength(1));
      expect(analytics.events.single.name, 'valid_event');
      expect(analytics.events.single.parameters, {
        'bad_param': 'ok',
        'count': 1,
      });
    },
  );

  test('monitored API client records latency and HTTP failure', () async {
    final analytics = _Analytics();
    final monitoring = MonitoringGateway(
      analytics: analytics,
      crashReporting: _CrashReporting(),
    );
    final client = MonitoredApiClient(
      delegate: _FixedApiClient(
        const ApiResponse(statusCode: 503, headers: <String, String>{}),
      ),
      monitoring: monitoring,
    );

    await client.send(const ApiRequest(method: ApiMethod.get, path: '/health'));

    expect(
      analytics.events.map((event) => event.name),
      containsAll([MonitoringEvents.apiLatency, MonitoringEvents.apiFailure]),
    );
  });

  test('monitored API client reports timeout failures', () async {
    final analytics = _Analytics();
    final monitoring = MonitoringGateway(
      analytics: analytics,
      crashReporting: _CrashReporting(),
    );
    final client = MonitoredApiClient(
      delegate: _ThrowingApiClient(TimeoutException('slow')),
      monitoring: monitoring,
    );

    await expectLater(
      client.send(const ApiRequest(method: ApiMethod.get, path: '/slow')),
      throwsA(isA<TimeoutException>()),
    );

    expect(
      analytics.events.map((event) => event.name),
      containsAll([MonitoringEvents.apiTimeout, MonitoringEvents.apiFailure]),
    );
  });

  test(
    'monitoring tracks connectivity, retry, and notification health',
    () async {
      final analytics = _Analytics();
      final monitoring = MonitoringGateway(
        analytics: analytics,
        crashReporting: _CrashReporting(),
      );

      await monitoring.trackConnectivity(
        const ConnectivitySnapshot(
          quality: ConnectivityQuality.offline,
          isRetryRecommended: true,
        ),
      );
      await monitoring.trackRetrySuccess('catalog_refresh');
      await monitoring.trackNotificationTokenRegistration(success: true);
      await monitoring.trackNotificationDelivery('notification-1');
      await monitoring.trackNotificationOpen('notification-1');

      expect(
        analytics.events.map((event) => event.name),
        containsAll([
          MonitoringEvents.connectivityChanged,
          MonitoringEvents.retrySuccess,
          MonitoringEvents.notificationTokenRegistration,
          MonitoringEvents.notificationDelivery,
          MonitoringEvents.notificationOpen,
        ]),
      );
    },
  );
}

class _Analytics implements AnalyticsGateway {
  final events = <AnalyticsEvent>[];

  @override
  Future<void> track(AnalyticsEvent event) async {
    events.add(event);
  }
}

class _CrashReporting implements FirebaseCrashReportingGateway {
  int fatalCount = 0;
  int nonFatalCount = 0;

  @override
  Future<void> recordFatal(Object error, StackTrace stackTrace) async {
    fatalCount += 1;
  }

  @override
  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    nonFatalCount += 1;
  }
}

class _FixedApiClient implements ApiClient {
  const _FixedApiClient(this.response);

  final ApiResponse response;

  @override
  AppConfig get config => AppConfig.forEnvironment(AppEnvironment.development);

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    CancellationToken? cancelToken,
  }) async {
    return response;
  }
}

class _ThrowingApiClient implements ApiClient {
  const _ThrowingApiClient(this.error);

  final Object error;

  @override
  AppConfig get config => AppConfig.forEnvironment(AppEnvironment.development);

  @override
  Future<ApiResponse> send(
    ApiRequest request, {
    CancellationToken? cancelToken,
  }) async {
    Error.throwWithStackTrace(error, StackTrace.current);
  }
}
