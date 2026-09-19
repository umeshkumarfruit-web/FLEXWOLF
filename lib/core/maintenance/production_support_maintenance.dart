import 'package:flexwolf/app/config/app_config.dart';
import 'package:flutter/foundation.dart';

@immutable
class SupportWorkflowRequest {
  const SupportWorkflowRequest({
    required this.type,
    required this.subject,
    required this.message,
    this.email,
    this.appVersion,
    this.context = const <String, String>{},
  });

  final SupportWorkflowType type;
  final String subject;
  final String message;
  final String? email;
  final String? appVersion;
  final Map<String, String> context;

  bool get isValid =>
      subject.trim().isNotEmpty &&
      message.trim().length >= 10 &&
      (email == null || email!.contains('@'));
}

enum SupportWorkflowType {
  bugReport,
  featureRequest,
  technicalIssue,
  generalFeedback,
}

abstract interface class ProductionSupportWorkflowRepository {
  Future<SupportWorkflowReceipt> submit(SupportWorkflowRequest request);
}

class ClientDependencySupportWorkflowRepository
    implements ProductionSupportWorkflowRepository {
  const ClientDependencySupportWorkflowRepository();

  @override
  Future<SupportWorkflowReceipt> submit(SupportWorkflowRequest request) async {
    if (!request.isValid) {
      return SupportWorkflowReceipt.rejected(reason: 'support_request_invalid');
    }
    return SupportWorkflowReceipt.clientDependency(
      type: request.type,
      reference: 'support-workflow-pending',
    );
  }
}

@immutable
class SupportWorkflowReceipt {
  const SupportWorkflowReceipt({
    required this.accepted,
    required this.clientDependency,
    required this.reference,
    this.reason,
  });

  factory SupportWorkflowReceipt.clientDependency({
    required SupportWorkflowType type,
    required String reference,
  }) {
    return SupportWorkflowReceipt(
      accepted: true,
      clientDependency: true,
      reference: '${type.name}:$reference',
    );
  }

  factory SupportWorkflowReceipt.rejected({required String reason}) {
    return SupportWorkflowReceipt(
      accepted: false,
      clientDependency: false,
      reference: 'rejected',
      reason: reason,
    );
  }

  final bool accepted;
  final bool clientDependency;
  final String reference;
  final String? reason;
}

@immutable
class AppUpdateState {
  const AppUpdateState({
    required this.currentVersion,
    required this.latestVersion,
    required this.policy,
    this.storeUrl,
    this.message,
  });

  factory AppUpdateState.current(ReleaseMetadata release) {
    return AppUpdateState(
      currentVersion: release.version,
      latestVersion: release.version,
      policy: AppUpdatePolicy.none,
    );
  }

  final String currentVersion;
  final String latestVersion;
  final AppUpdatePolicy policy;
  final Uri? storeUrl;
  final String? message;

  bool get isUpdateAvailable => currentVersion != latestVersion;
  bool get isMandatory => policy == AppUpdatePolicy.mandatory;
  bool get isOptional => policy == AppUpdatePolicy.optional;
}

enum AppUpdatePolicy { none, optional, mandatory }

abstract interface class AppUpdateRepository {
  Future<AppUpdateState> checkForUpdate(ReleaseMetadata release);
}

class NoopAppUpdateRepository implements AppUpdateRepository {
  const NoopAppUpdateRepository();

  @override
  Future<AppUpdateState> checkForUpdate(ReleaseMetadata release) async {
    return AppUpdateState.current(release);
  }
}

@immutable
class MaintenanceState {
  const MaintenanceState({
    required this.mode,
    this.bannerMessage,
    this.outageMessage,
    this.updatedAt,
  });

  static const normal = MaintenanceState(mode: MaintenanceMode.normal);

  final MaintenanceMode mode;
  final String? bannerMessage;
  final String? outageMessage;
  final DateTime? updatedAt;

  bool get showsBanner =>
      mode == MaintenanceMode.banner &&
      bannerMessage != null &&
      bannerMessage!.trim().isNotEmpty;

  bool get isReadOnly => mode == MaintenanceMode.readOnly;
  bool get isOutage => mode == MaintenanceMode.outage;
}

enum MaintenanceMode { normal, banner, readOnly, outage }

abstract interface class MaintenanceRepository {
  Future<MaintenanceState> current();
}

class NoopMaintenanceRepository implements MaintenanceRepository {
  const NoopMaintenanceRepository();

  @override
  Future<MaintenanceState> current() async => MaintenanceState.normal;
}
