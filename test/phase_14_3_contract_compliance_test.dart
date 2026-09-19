import 'dart:io';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/admin/data/admin_auth_repository.dart';
import 'package:flexwolf/features/admin/data/admin_cms_repository.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 14.3 audit records every requested section once', () {
    final audit = File(
      'docs/PHASE_14_3_CONTRACT_COMPLIANCE_AUDIT.md',
    ).readAsStringSync();

    const requiredSections = <String>[
      'Admin Portal',
      'CMS',
      'Roles & Permissions',
      'Analytics Dashboard',
      'Push Notification Dashboard',
      'Remote Configuration',
      'Logs',
      'Monitoring',
      'App Configuration',
      'Feature Flags',
      'Error Reporting',
      'Security Review',
    ];
    const allowedStatuses = <String>{
      'COMPLETE',
      'PARTIAL',
      'CLIENT DEPENDENCY',
      'MISSING',
    };

    for (final section in requiredSections) {
      final matches = RegExp(
        r'^\| ' + RegExp.escape(section) + r' \| ([A-Z &]+) \|',
        multiLine: true,
      ).allMatches(audit).toList();
      expect(matches, hasLength(1), reason: section);
      expect(
        allowedStatuses,
        contains(matches.single.group(1)),
        reason: section,
      );
    }
  });

  test('Phase 14.3 admin role restrictions remain policy driven', () {
    final policies = defaultAdminRolePolicies();
    final contentManager = policies.firstWhere(
      (policy) => policy.role == AdminRole.contentManager,
    );
    final marketing = policies.firstWhere(
      (policy) => policy.role == AdminRole.marketing,
    );
    final support = policies.firstWhere(
      (policy) => policy.role == AdminRole.support,
    );

    expect(contentManager.allows(const AdminPermission('content.view')), isTrue);
    expect(
      contentManager.allows(const AdminPermission('settings.view')),
      isFalse,
    );
    expect(marketing.allows(const AdminPermission('notifications.view')), isTrue);
    expect(marketing.allows(const AdminPermission('support.view')), isFalse);
    expect(support.allows(const AdminPermission('support.view')), isTrue);
    expect(support.allows(const AdminPermission('marketing.view')), isFalse);
  });

  test('Phase 14.3 admin secure access and dependency errors are explicit', () async {
    final auth = SecureStorageAdminAuthRepository(
      InMemorySecureStorage(),
      gateway: const _ExpiredGateway(),
    );

    await auth.login(
      const AdminCredentials(email: 'admin@flexwolf.test', password: 'secret'),
    );
    expect(await auth.restoreSession(), isNull);

    final cms = InMemoryAdminHomeContentRepository();
    await expectLater(
      cms.publish('hero-banner'),
      throwsA(isA<AppException>()),
    );

    const uploader = ClientDependencyAdminMediaUploadGateway();
    expect(
      () => uploader.prepareUploadUrl(fileName: 'hero-banner.jpg'),
      throwsA(isA<AppException>()),
    );

    final config = AppConfig.forEnvironment(AppEnvironment.production);
    expect(config.allowsVerboseLogging, isFalse);
    expect(config.featureFlags.enableDiagnostics, isFalse);
  });
}

class _ExpiredGateway implements AdminAuthGateway {
  const _ExpiredGateway();

  @override
  Future<AdminSession> login(AdminCredentials credentials) async {
    return AdminSession(
      accessToken: 'expired-session-token',
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      user: AdminUser(
        id: 'admin-expired',
        email: credentials.email,
        role: AdminRole.admin,
      ),
    );
  }
}



