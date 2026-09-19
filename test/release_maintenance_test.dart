import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/release/release_maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release maintenance plans calculate semantic versions safely', () {
    const current = ReleaseMetadata(version: '1.2.3', buildNumber: '9');

    expect(
      ReleaseMaintenancePlan.forType(
        type: ReleaseChangeType.emergencyHotfix,
        current: current,
      ).version,
      '1.2.4',
    );
    expect(
      ReleaseMaintenancePlan.forType(
        type: ReleaseChangeType.patchRelease,
        current: current,
      ).version,
      '1.2.4',
    );
    expect(
      ReleaseMaintenancePlan.forType(
        type: ReleaseChangeType.minorRelease,
        current: current,
      ).version,
      '1.3.0',
    );
    expect(
      ReleaseMaintenancePlan.forType(
        type: ReleaseChangeType.majorRelease,
        current: current,
      ).version,
      '2.0.0',
    );
  });

  test('rollback plans are documentation only and require approval', () {
    const plan = RollbackPlan(
      target: RollbackTarget.androidRelease,
      previousVersion: '1.0.0+1',
      approvalRequired: true,
      steps: ['Pause rollout', 'Select previous release', 'Monitor recovery'],
    );

    expect(plan.approvalRequired, isTrue);
    expect(plan.isExecutableByDocumentationOnly, isFalse);
    expect(plan.steps, hasLength(3));
  });

  test('release checklist blocks unsigned or non-production releases', () {
    final productionReady = ReleaseReadinessChecklist.fromConfig(
      config: AppConfig.forEnvironment(AppEnvironment.production),
      changelogReady: true,
      releaseNotesReady: true,
      signingReady: true,
    );
    final unsigned = ReleaseReadinessChecklist.fromConfig(
      config: AppConfig.forEnvironment(AppEnvironment.production),
      changelogReady: true,
      releaseNotesReady: true,
      signingReady: false,
    );
    final development = ReleaseReadinessChecklist.fromConfig(
      config: AppConfig.forEnvironment(AppEnvironment.development),
      changelogReady: true,
      releaseNotesReady: true,
      signingReady: true,
    );

    expect(productionReady.isReady, isTrue);
    expect(unsigned.isReady, isFalse);
    expect(development.environmentReady, isFalse);
  });

  test('backup manifest forbids duplicating production ecommerce data', () {
    const manifest = BackupManifest(
      sourceCodeTagged: true,
      environmentConfigBackedUp: true,
      firebaseConfigBackedUp: true,
      buildArtifactsArchived: true,
      duplicatesProductionData: false,
    );
    const unsafe = BackupManifest(
      sourceCodeTagged: true,
      environmentConfigBackedUp: true,
      firebaseConfigBackedUp: true,
      buildArtifactsArchived: true,
      duplicatesProductionData: true,
    );

    expect(manifest.isRecoveryReady, isTrue);
    expect(unsafe.isRecoveryReady, isFalse);
  });
}
