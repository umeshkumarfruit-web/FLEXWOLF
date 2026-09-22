import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/admin/data/admin_auth_repository.dart';
import 'package:flexwolf/features/admin/data/firebase_admin_auth_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexwolf/features/admin/data/admin_cms_repository.dart';
import 'package:flexwolf/features/admin/data/admin_foundation_repositories.dart';
import 'package:flexwolf/features/admin/data/admin_operations_repository.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_repositories.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_models.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_repositories.dart';
import 'package:flexwolf/features/admin/domain/admin_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  if (Firebase.apps.isNotEmpty) return FirebaseAdminAuthRepository();
  return SecureStorageAdminAuthRepository(ref.watch(secureStorageProvider));
});

final adminSessionProvider = FutureProvider<AdminSession?>((ref) {
  return ref.watch(adminAuthRepositoryProvider).restoreSession();
});

final adminRolePoliciesProvider = FutureProvider<List<AdminRolePolicy>>((ref) {
  return ref.watch(adminRoleRepositoryProvider).fetchRolePolicies();
});

final adminRoleRepositoryProvider = Provider<AdminRoleRepository>((ref) {
  return ConfigurableAdminRoleRepository(defaultAdminRolePolicies());
});

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((
  ref,
) {
  return FoundationAdminDashboardRepository(
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final adminDashboardMetricsProvider =
    FutureProvider<List<AdminDashboardMetric>>(
      (ref) => ref.watch(adminDashboardRepositoryProvider).fetchMetrics(),
    );

final adminSystemStatusProvider = FutureProvider<List<AdminSystemStatus>>(
  (ref) => ref.watch(adminDashboardRepositoryProvider).fetchSystemStatus(),
);

final adminOperationsRepositoryProvider = Provider<AdminOperationsRepository>((
  ref,
) {
  return CachedAdminOperationsRepository(
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

final adminOperationsSnapshotProvider = FutureProvider<AdminOperationsSnapshot>(
  (ref) => ref.watch(adminOperationsRepositoryProvider).fetchSnapshot(),
);
final adminHomeContentRepositoryProvider = Provider<AdminHomeContentRepository>(
  (ref) {
    return InMemoryAdminHomeContentRepository();
  },
);

final adminHomeContentDraftProvider = FutureProvider<AdminHomeContentDraft>(
  (ref) => ref.watch(adminHomeContentRepositoryProvider).loadDraft(),
);

final adminMediaUploadGatewayProvider = Provider<AdminMediaUploadGateway>((
  ref,
) {
  return const ClientDependencyAdminMediaUploadGateway();
});
final adminAuditLogRepositoryProvider = Provider<AdminAuditLogRepository>((
  ref,
) {
  return InMemoryAdminAuditLogRepository();
});

List<AdminRolePolicy> defaultAdminRolePolicies() => <AdminRolePolicy>[
  AdminRolePolicy(
    role: AdminRole.superAdmin,
    permissions: <AdminPermission>{
      AdminPermission('dashboard.view'),
      AdminPermission('content.view'),
      AdminPermission('notifications.view'),
      AdminPermission('marketing.view'),
      AdminPermission('support.view'),
      AdminPermission('settings.view'),
    },
  ),
  AdminRolePolicy(
    role: AdminRole.admin,
    permissions: <AdminPermission>{
      AdminPermission('dashboard.view'),
      AdminPermission('content.view'),
      AdminPermission('notifications.view'),
      AdminPermission('marketing.view'),
      AdminPermission('support.view'),
      AdminPermission('settings.view'),
    },
  ),
  AdminRolePolicy(
    role: AdminRole.contentManager,
    permissions: <AdminPermission>{
      AdminPermission('dashboard.view'),
      AdminPermission('content.view'),
    },
  ),
  AdminRolePolicy(
    role: AdminRole.marketing,
    permissions: <AdminPermission>{
      AdminPermission('dashboard.view'),
      AdminPermission('marketing.view'),
      AdminPermission('notifications.view'),
    },
  ),
  AdminRolePolicy(
    role: AdminRole.support,
    permissions: <AdminPermission>{
      AdminPermission('dashboard.view'),
      AdminPermission('support.view'),
    },
  ),
];
