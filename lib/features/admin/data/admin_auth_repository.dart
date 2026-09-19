import 'dart:convert';

import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/features/admin/domain/admin_repositories.dart';

class SecureStorageAdminAuthRepository implements AdminAuthRepository {
  SecureStorageAdminAuthRepository(this._storage, {AdminAuthGateway? gateway})
    : _gateway = gateway ?? const ClientDependencyAdminAuthGateway();

  static const _sessionKey = 'admin.session';

  final SecureStorage _storage;
  final AdminAuthGateway _gateway;

  @override
  Future<AdminSession?> restoreSession() async {
    final raw = await _storage.read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      await _storage.delete(_sessionKey);
      return null;
    }
    final session = _sessionFromJson(decoded);
    if (session == null || session.isExpired) {
      await _storage.delete(_sessionKey);
      return null;
    }
    return session;
  }

  @override
  Future<AdminSession> login(AdminCredentials credentials) async {
    if (credentials.email.trim().isEmpty || credentials.password.isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Enter admin email and password.',
        code: 'admin_login_invalid',
      );
    }
    final session = await _gateway.login(credentials);
    await _storage.write(_sessionKey, jsonEncode(_sessionToJson(session)));
    return session;
  }

  @override
  Future<void> logout() => _storage.delete(_sessionKey);

  @override
  Future<void> handleUnauthorized() => logout();
}

abstract interface class AdminAuthGateway {
  Future<AdminSession> login(AdminCredentials credentials);
}

class ClientDependencyAdminAuthGateway implements AdminAuthGateway {
  const ClientDependencyAdminAuthGateway();

  @override
  Future<AdminSession> login(AdminCredentials credentials) {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message:
          'CLIENT DEPENDENCY: Admin authentication endpoint is not configured.',
      code: 'admin_auth_not_configured',
      isRetryable: true,
    );
  }
}

Map<String, Object?> _sessionToJson(AdminSession session) => <String, Object?>{
  'accessToken': session.accessToken,
  'expiresAt': session.expiresAt.toIso8601String(),
  'user': <String, Object?>{
    'id': session.user.id,
    'email': session.user.email,
    'role': session.user.role.name,
  },
};

AdminSession? _sessionFromJson(Map<String, Object?> json) {
  final accessToken = json['accessToken'];
  final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
  final userJson = json['user'];
  if (accessToken is! String || accessToken.isEmpty || expiresAt == null) {
    return null;
  }
  if (userJson is! Map<String, Object?>) return null;
  final id = userJson['id'];
  final email = userJson['email'];
  final roleName = userJson['role'];
  final role = AdminRole.values
      .where((value) => value.name == roleName)
      .firstOrNull;
  if (id is! String || email is! String || role == null) return null;
  return AdminSession(
    accessToken: accessToken,
    expiresAt: expiresAt,
    user: AdminUser(id: id, email: email, role: role),
  );
}
