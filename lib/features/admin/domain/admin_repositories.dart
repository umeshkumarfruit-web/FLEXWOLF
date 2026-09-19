import 'package:flexwolf/features/admin/domain/admin_models.dart';

abstract interface class AdminAuthRepository {
  Future<AdminSession?> restoreSession();
  Future<AdminSession> login(AdminCredentials credentials);
  Future<void> logout();
  Future<void> handleUnauthorized();
}

abstract interface class AdminRoleRepository {
  Future<List<AdminRolePolicy>> fetchRolePolicies();
}

abstract interface class AdminDashboardRepository {
  Future<List<AdminDashboardMetric>> fetchMetrics();
  Future<List<AdminSystemStatus>> fetchSystemStatus();
}

abstract interface class AdminAuditLogRepository {
  Future<void> record(AdminAuditEvent event);
}
