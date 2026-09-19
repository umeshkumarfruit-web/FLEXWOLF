import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/maintenance/production_support_maintenance.dart';
import 'package:flexwolf/core/monitoring/app_monitoring.dart';
import 'package:flexwolf/core/release/release_maintenance.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 13 monitoring duplicate suppression is bounded', () async {
    final analytics = _Analytics();
    final monitoring = MonitoringGateway(
      analytics: analytics,
      crashReporting: const FirebaseCrashReportingNotConfigured(),
    );

    for (var i = 0; i < 300; i += 1) {
      await monitoring.trackRetrySuccess('operation-$i');
    }
    await monitoring.trackRetrySuccess('operation-0');

    expect(
      analytics.events.where(
        (event) => event.name == MonitoringEvents.retrySuccess,
      ),
      hasLength(301),
    );
  });

  test('Phase 13 production health marks unavailable services as client dependencies', () async {
    final update = await const NoopAppUpdateRepository().checkForUpdate(
      const ReleaseMetadata(version: '1.0.0', buildNumber: '1'),
    );
    final maintenance = await const NoopMaintenanceRepository().current();
    final production = AppConfig.forEnvironment(AppEnvironment.production);

    expect(update.policy, AppUpdatePolicy.none);
    expect(maintenance, MaintenanceState.normal);
    expect(production.firebase.configured, isFalse);
    expect(production.allowsVerboseLogging, isFalse);
  });

  test('Phase 13 release operations remain gated by signing and docs', () {
    final checklist = ReleaseReadinessChecklist.fromConfig(
      config: AppConfig.forEnvironment(AppEnvironment.production),
      changelogReady: true,
      releaseNotesReady: true,
      signingReady: false,
    );
    const backup = BackupManifest(
      sourceCodeTagged: true,
      environmentConfigBackedUp: true,
      firebaseConfigBackedUp: true,
      buildArtifactsArchived: true,
      duplicatesProductionData: false,
    );

    expect(checklist.isReady, isFalse);
    expect(backup.isRecoveryReady, isTrue);
  });

  test('Phase 13 failure monitoring covers production health areas', () async {
    final analytics = _Analytics();
    final crash = _CrashReporting();
    final monitoring = MonitoringGateway(
      analytics: analytics,
      crashReporting: crash,
    );

    for (final area in AppHealthArea.values) {
      await monitoring.trackFailure(
        area,
        AppException(
          kind: area == AppHealthArea.authentication
              ? AppErrorKind.authentication
              : AppErrorKind.unavailable,
          message: 'Unavailable production dependency.',
          code: '${area.name}_client_dependency',
          isRetryable: true,
        ),
        StackTrace.current,
      );
    }

    expect(crash.nonFatalCount, AppHealthArea.values.length);
    expect(
      analytics.events.map((event) => event.name),
      containsAll(<String>[
        MonitoringEvents.startupFailure,
        MonitoringEvents.apiFailure,
        MonitoringEvents.authenticationFailure,
        MonitoringEvents.checkoutFailure,
        MonitoringEvents.notificationFailure,
      ]),
    );
  });
}

class _Analytics implements AnalyticsGateway {
  final events = <AnalyticsEvent>[];

  @override
  Future<void> track(AnalyticsEvent event) async {
    events.add(event);
  }
}

class _CrashReporting implements FirebaseCrashReportingGateway {
  int nonFatalCount = 0;

  @override
  Future<void> recordFatal(Object error, StackTrace stackTrace) async {}

  @override
  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    nonFatalCount += 1;
  }
}
