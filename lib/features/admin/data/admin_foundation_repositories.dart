import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/features/admin/domain/admin_repositories.dart';

class ConfigurableAdminRoleRepository implements AdminRoleRepository {
  const ConfigurableAdminRoleRepository(this._policies);

  final List<AdminRolePolicy> _policies;

  @override
  Future<List<AdminRolePolicy>> fetchRolePolicies() async => _policies;
}

class FoundationAdminDashboardRepository implements AdminDashboardRepository {
  const FoundationAdminDashboardRepository({required this.connectivity});

  final ConnectivityService connectivity;

  @override
  Future<List<AdminDashboardMetric>> fetchMetrics() async {
    return const <AdminDashboardMetric>[
      AdminDashboardMetric(
        id: 'users',
        label: 'Users',
        valueLabel: 'Client dependency',
        iconName: 'users',
      ),
      AdminDashboardMetric(
        id: 'orders',
        label: 'Orders',
        valueLabel: 'Shopify source',
        iconName: 'orders',
      ),
      AdminDashboardMetric(
        id: 'returns',
        label: 'Returns',
        valueLabel: 'Redo pending',
        iconName: 'returns',
      ),
      AdminDashboardMetric(
        id: 'reviews',
        label: 'Reviews',
        valueLabel: 'Provider pending',
        iconName: 'reviews',
      ),
      AdminDashboardMetric(
        id: 'notifications',
        label: 'Notifications',
        valueLabel: 'Firebase pending',
        iconName: 'notifications',
      ),
      AdminDashboardMetric(
        id: 'revenue',
        label: 'Revenue',
        valueLabel: 'Backend pending',
        iconName: 'revenue',
      ),
      AdminDashboardMetric(
        id: 'support_tickets',
        label: 'Support Tickets',
        valueLabel: 'Gorgias pending',
        iconName: 'support',
      ),
      AdminDashboardMetric(
        id: 'system_health',
        label: 'System Health',
        valueLabel: 'Connection only',
        iconName: 'status',
      ),
    ];
  }

  @override
  Future<List<AdminSystemStatus>> fetchSystemStatus() async {
    final current = await connectivity.current();
    final backendState = switch (current.quality) {
      ConnectivityQuality.offline => AdminConnectionState.disconnected,
      ConnectivityQuality.weak => AdminConnectionState.degraded,
      ConnectivityQuality.online => AdminConnectionState.connected,
      ConnectivityQuality.unknown => AdminConnectionState.unknown,
    };
    return <AdminSystemStatus>[
      const AdminSystemStatus(
        service: AdminConnectionService.shopify,
        state: AdminConnectionState.unknown,
      ),
      const AdminSystemStatus(
        service: AdminConnectionService.firebase,
        state: AdminConnectionState.unknown,
      ),
      AdminSystemStatus(
        service: AdminConnectionService.backend,
        state: backendState,
      ),
      const AdminSystemStatus(
        service: AdminConnectionService.klaviyo,
        state: AdminConnectionState.unknown,
      ),
      const AdminSystemStatus(
        service: AdminConnectionService.gorgias,
        state: AdminConnectionState.unknown,
      ),
    ];
  }
}

class InMemoryAdminAuditLogRepository implements AdminAuditLogRepository {
  final List<AdminAuditEvent> events = <AdminAuditEvent>[];

  @override
  Future<void> record(AdminAuditEvent event) async {
    events.add(event);
  }
}
