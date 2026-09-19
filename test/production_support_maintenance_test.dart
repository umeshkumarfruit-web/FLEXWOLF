import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/incidents/incident_management.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/maintenance/production_support_maintenance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support workflow accepts required production support types', () async {
    const repository = ClientDependencySupportWorkflowRepository();

    for (final type in SupportWorkflowType.values) {
      final receipt = await repository.submit(
        SupportWorkflowRequest(
          type: type,
          subject: 'Production support intake',
          message: 'This request has enough detail for support triage.',
          email: 'support@flexwolf.test',
          appVersion: '1.0.0',
        ),
      );

      expect(receipt.accepted, isTrue);
      expect(receipt.clientDependency, isTrue);
      expect(receipt.reference, startsWith(type.name));
    }
  });

  test('support workflow rejects invalid intake safely', () async {
    const repository = ClientDependencySupportWorkflowRepository();

    final receipt = await repository.submit(
      const SupportWorkflowRequest(
        type: SupportWorkflowType.bugReport,
        subject: '',
        message: 'short',
        email: 'invalid-email',
      ),
    );

    expect(receipt.accepted, isFalse);
    expect(receipt.reason, 'support_request_invalid');
  });

  test('incident repository logs priority status and resolution', () async {
    final repository = ClientDependencyIncidentRepository(
      clock: () => DateTime.utc(2026, 9, 8, 12),
    );

    final incident = await repository.log(
      const IncidentDraft(
        title: 'Checkout outage',
        priority: IncidentPriority.critical,
        area: 'checkout',
      ),
    );
    final triaged = await repository.updateStatus(
      id: incident.id,
      status: IncidentStatus.inProgress,
    );
    final resolved = await repository.updateStatus(
      id: incident.id,
      status: IncidentStatus.resolved,
      resolution: 'Checkout provider recovered.',
    );

    expect(incident.status, IncidentStatus.open);
    expect(incident.priority, IncidentPriority.critical);
    expect(triaged.isOpen, isTrue);
    expect(resolved.status, IncidentStatus.resolved);
    expect(resolved.resolution, 'Checkout provider recovered.');
    expect(resolved.resolvedAt, DateTime.utc(2026, 9, 8, 12));
  });

  test(
    'app update foundation supports current optional and mandatory states',
    () async {
      const release = ReleaseMetadata(version: '1.0.0', buildNumber: '1');
      const repository = NoopAppUpdateRepository();

      final current = await repository.checkForUpdate(release);
      final optional = AppUpdateState(
        currentVersion: release.version,
        latestVersion: '1.1.0',
        policy: AppUpdatePolicy.optional,
        storeUrl: Uri.parse('https://flexwolf.co'),
      );
      final mandatory = AppUpdateState(
        currentVersion: release.version,
        latestVersion: '2.0.0',
        policy: AppUpdatePolicy.mandatory,
      );

      expect(current.isUpdateAvailable, isFalse);
      expect(optional.isOptional, isTrue);
      expect(optional.isUpdateAvailable, isTrue);
      expect(mandatory.isMandatory, isTrue);
    },
  );

  test(
    'maintenance foundation supports banner read-only and outage states',
    () async {
      const repository = NoopMaintenanceRepository();

      final normal = await repository.current();
      const banner = MaintenanceState(
        mode: MaintenanceMode.banner,
        bannerMessage: 'Shipping support is delayed today.',
      );
      const readOnly = MaintenanceState(mode: MaintenanceMode.readOnly);
      const outage = MaintenanceState(
        mode: MaintenanceMode.outage,
        outageMessage: 'Checkout is temporarily unavailable.',
      );

      expect(normal, MaintenanceState.normal);
      expect(banner.showsBanner, isTrue);
      expect(readOnly.isReadOnly, isTrue);
      expect(outage.isOutage, isTrue);
    },
  );

  test('production logger redacts secrets from output', () {
    final messages = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };

    try {
      final logger = AppLogger(
        AppConfig.forEnvironment(AppEnvironment.production),
      );
      logger.error(
        'token=abc123 secret=hidden api_key=key123 password=pw authorization: Bearer live-token',
      );
    } finally {
      debugPrint = previous;
    }

    final output = messages.join('\n');
    expect(output, isNot(contains('abc123')));
    expect(output, isNot(contains('hidden')));
    expect(output, isNot(contains('key123')));
    expect(output, isNot(contains('pw')));
    expect(output, isNot(contains('live-token')));
    expect(output, contains('<redacted>'));
  });
}
