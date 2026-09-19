import 'package:flutter/foundation.dart';

enum AdminRole { superAdmin, admin, contentManager, marketing, support }

@immutable
class AdminPermission {
  const AdminPermission(this.id);

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AdminPermission && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class AdminRolePolicy {
  const AdminRolePolicy({required this.role, required this.permissions});

  final AdminRole role;
  final Set<AdminPermission> permissions;

  bool allows(AdminPermission permission) => permissions.contains(permission);
}

@immutable
class AdminUser {
  const AdminUser({required this.id, required this.email, required this.role});

  final String id;
  final String email;
  final AdminRole role;
}

@immutable
class AdminSession {
  const AdminSession({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
  });

  final AdminUser user;
  final String accessToken;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}

@immutable
class AdminCredentials {
  const AdminCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

@immutable
class AdminDashboardMetric {
  const AdminDashboardMetric({
    required this.id,
    required this.label,
    required this.valueLabel,
    required this.iconName,
  });

  final String id;
  final String label;
  final String valueLabel;
  final String iconName;
}

enum AdminConnectionService { shopify, firebase, backend, klaviyo, gorgias }

enum AdminConnectionState { unknown, connected, degraded, disconnected }

@immutable
class AdminSystemStatus {
  const AdminSystemStatus({required this.service, required this.state});

  final AdminConnectionService service;
  final AdminConnectionState state;
}

@immutable
class AdminAuditEvent {
  const AdminAuditEvent({
    required this.action,
    required this.actorId,
    required this.createdAt,
    this.metadata = const <String, Object?>{},
  });

  final String action;
  final String actorId;
  final DateTime createdAt;
  final Map<String, Object?> metadata;
}
