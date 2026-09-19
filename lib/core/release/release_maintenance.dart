import 'package:flexwolf/app/config/app_config.dart';
import 'package:flutter/foundation.dart';

@immutable
class ReleaseMaintenancePlan {
  const ReleaseMaintenancePlan({
    required this.type,
    required this.version,
    required this.buildNumber,
    required this.requiresStoreReview,
    required this.requiresBackendCoordination,
    required this.requiresFirebaseReview,
  });

  factory ReleaseMaintenancePlan.forType({
    required ReleaseChangeType type,
    required ReleaseMetadata current,
  }) {
    return ReleaseMaintenancePlan(
      type: type,
      version: _nextVersion(current.version, type),
      buildNumber: _nextBuildNumber(current.buildNumber),
      requiresStoreReview: true,
      requiresBackendCoordination: type != ReleaseChangeType.patchRelease,
      requiresFirebaseReview:
          type == ReleaseChangeType.emergencyHotfix ||
          type == ReleaseChangeType.majorRelease,
    );
  }

  final ReleaseChangeType type;
  final String version;
  final String buildNumber;
  final bool requiresStoreReview;
  final bool requiresBackendCoordination;
  final bool requiresFirebaseReview;
}

enum ReleaseChangeType {
  emergencyHotfix,
  patchRelease,
  minorRelease,
  majorRelease,
}

@immutable
class RollbackPlan {
  const RollbackPlan({
    required this.target,
    required this.previousVersion,
    required this.approvalRequired,
    required this.steps,
  });

  final RollbackTarget target;
  final String previousVersion;
  final bool approvalRequired;
  final List<String> steps;

  bool get isExecutableByDocumentationOnly => false;
}

enum RollbackTarget { androidRelease, backend, firebaseConfiguration }

@immutable
class ReleaseReadinessChecklist {
  const ReleaseReadinessChecklist({
    required this.version,
    required this.buildNumber,
    required this.changelogReady,
    required this.releaseNotesReady,
    required this.environmentReady,
    required this.signingReady,
  });

  factory ReleaseReadinessChecklist.fromConfig({
    required AppConfig config,
    required bool changelogReady,
    required bool releaseNotesReady,
    required bool signingReady,
  }) {
    return ReleaseReadinessChecklist(
      version: config.release.version,
      buildNumber: config.release.buildNumber,
      changelogReady: changelogReady,
      releaseNotesReady: releaseNotesReady,
      environmentReady:
          config.environment.isProduction &&
          config.allowsProductionSideEffects &&
          !config.allowsVerboseLogging,
      signingReady: signingReady,
    );
  }

  final String version;
  final String buildNumber;
  final bool changelogReady;
  final bool releaseNotesReady;
  final bool environmentReady;
  final bool signingReady;

  bool get isReady =>
      version.trim().isNotEmpty &&
      buildNumber.trim().isNotEmpty &&
      changelogReady &&
      releaseNotesReady &&
      environmentReady &&
      signingReady;
}

@immutable
class BackupManifest {
  const BackupManifest({
    required this.sourceCodeTagged,
    required this.environmentConfigBackedUp,
    required this.firebaseConfigBackedUp,
    required this.buildArtifactsArchived,
    required this.duplicatesProductionData,
  });

  final bool sourceCodeTagged;
  final bool environmentConfigBackedUp;
  final bool firebaseConfigBackedUp;
  final bool buildArtifactsArchived;
  final bool duplicatesProductionData;

  bool get isRecoveryReady =>
      sourceCodeTagged &&
      environmentConfigBackedUp &&
      firebaseConfigBackedUp &&
      buildArtifactsArchived &&
      !duplicatesProductionData;
}

String _nextVersion(String current, ReleaseChangeType type) {
  final parts = current.split('.').map(int.tryParse).toList();
  final major = parts.isNotEmpty ? parts[0] ?? 0 : 0;
  final minor = parts.length > 1 ? parts[1] ?? 0 : 0;
  final patch = parts.length > 2 ? parts[2] ?? 0 : 0;
  switch (type) {
    case ReleaseChangeType.emergencyHotfix:
    case ReleaseChangeType.patchRelease:
      return '$major.$minor.${patch + 1}';
    case ReleaseChangeType.minorRelease:
      return '$major.${minor + 1}.0';
    case ReleaseChangeType.majorRelease:
      return '${major + 1}.0.0';
  }
}

String _nextBuildNumber(String current) {
  final parsed = int.tryParse(current.trim());
  return ((parsed ?? 0) + 1).toString();
}
