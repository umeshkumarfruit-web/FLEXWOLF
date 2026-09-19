import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/admin/data/admin_auth_repository.dart';
import 'package:flexwolf/features/admin/data/admin_foundation_repositories.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/features/admin/domain/admin_repositories.dart';
import 'package:flexwolf/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin session is stored securely restored and cleared', () async {
    final storage = InMemorySecureStorage();
    final repository = SecureStorageAdminAuthRepository(
      storage,
      gateway: _FakeAdminAuthGateway(),
    );

    final session = await repository.login(
      const AdminCredentials(email: 'admin@flexwolf.test', password: 'secret'),
    );

    expect(session.user.role, AdminRole.admin);
    expect(await repository.restoreSession(), isNotNull);

    await repository.handleUnauthorized();

    expect(await repository.restoreSession(), isNull);
  });

  test('expired admin sessions are not restored', () async {
    final storage = InMemorySecureStorage();
    final repository = SecureStorageAdminAuthRepository(
      storage,
      gateway: _FakeAdminAuthGateway(expired: true),
    );

    await repository.login(
      const AdminCredentials(email: 'admin@flexwolf.test', password: 'secret'),
    );

    expect(await repository.restoreSession(), isNull);
  });

  test('role policies are configurable and not hardcoded in UI', () async {
    final repository = ConfigurableAdminRoleRepository(
      defaultAdminRolePolicies(),
    );

    final policies = await repository.fetchRolePolicies();

    expect(
      policies.map((policy) => policy.role),
      contains(AdminRole.superAdmin),
    );
    expect(policies.map((policy) => policy.role), contains(AdminRole.support));
    expect(
      policies
          .firstWhere((policy) => policy.role == AdminRole.support)
          .allows(const AdminPermission('support.view')),
      isTrue,
    );
  });

  test(
    'system status maps connectivity without editing configuration',
    () async {
      final repository = FoundationAdminDashboardRepository(
        connectivity: const _FixedConnectivityService(
          ConnectivitySnapshot(quality: ConnectivityQuality.offline),
        ),
      );

      final statuses = await repository.fetchSystemStatus();

      expect(
        statuses
            .firstWhere(
              (status) => status.service == AdminConnectionService.backend,
            )
            .state,
        AdminConnectionState.disconnected,
      );
      expect(statuses.length, 5);
      expect(
        statuses.map((status) => status.service),
        contains(AdminConnectionService.gorgias),
      );
    },
  );

  testWidgets('admin dashboard renders foundation cards and navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.development),
          ),
          localStorageProvider.overrideWithValue(InMemoryLocalStorage()),
          adminAuthRepositoryProvider.overrideWithValue(
            _RestoredAdminAuthRepository(),
          ),
        ],
        child: MaterialApp(home: const AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Returns'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('System Status'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('System Status'), findsWidgets);
    expect(find.text('Content'), findsWidgets);
    expect(find.text('Marketing'), findsWidgets);
  });
}

class _FakeAdminAuthGateway implements AdminAuthGateway {
  const _FakeAdminAuthGateway({this.expired = false});

  final bool expired;

  @override
  Future<AdminSession> login(AdminCredentials credentials) async {
    return AdminSession(
      accessToken: 'test-admin-session-token',
      expiresAt: expired
          ? DateTime.now().subtract(const Duration(minutes: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      user: AdminUser(
        id: 'admin-1',
        email: credentials.email,
        role: AdminRole.admin,
      ),
    );
  }
}

class _RestoredAdminAuthRepository implements AdminAuthRepository {
  @override
  Future<void> handleUnauthorized() async {}

  @override
  Future<AdminSession> login(AdminCredentials credentials) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AdminSession?> restoreSession() async {
    return AdminSession(
      accessToken: 'restored-admin-session-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: const AdminUser(
        id: 'admin-1',
        email: 'admin@flexwolf.test',
        role: AdminRole.superAdmin,
      ),
    );
  }
}

class _FixedConnectivityService implements ConnectivityService {
  const _FixedConnectivityService(this.snapshot);

  final ConnectivitySnapshot snapshot;

  @override
  Future<ConnectivitySnapshot> current() async => snapshot;

  @override
  Stream<ConnectivitySnapshot> watch() => Stream.value(snapshot);
}
