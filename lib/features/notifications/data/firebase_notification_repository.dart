import 'dart:convert';

import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/backend/backend_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({
    required FirebaseMessagingGateway messaging,
    required SecureStorage storage,
    required PushTokenSyncGateway tokenSync,
  }) : this._(messaging, storage, tokenSync);

  FirebaseNotificationRepository._(
    this._messaging,
    this._storage,
    this._tokenSync,
  );

  static const _tokenKey = 'firebase.fcm.registration';
  final FirebaseMessagingGateway _messaging;
  final SecureStorage _storage;
  final PushTokenSyncGateway _tokenSync;
  PushTokenRegistration? _lastRegistration;

  @override
  Future<void> initialize() => _messaging.prepareMessaging();

  @override
  Future<NotificationPermissionStatus> permissionStatus() =>
      _messaging.permissionStatus();

  @override
  Future<NotificationPermissionStatus> requestPermission() =>
      _messaging.requestPermission();

  @override
  Future<PushTokenRegistration?> restoreRegistration() async {
    final raw = await _storage.read(_tokenKey);
    if (raw == null) return null;
    final json = _decodeJson(raw);
    if (json is! Map<String, Object?> || json['token'] is! String) return null;
    _lastRegistration = PushTokenRegistration(
      token: json['token']! as String,
      customerId: json['customerId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
    return _lastRegistration;
  }

  @override
  Future<PushTokenRegistration?> registerDevice({String? customerId}) async {
    final permission = await permissionStatus();
    if (permission == NotificationPermissionStatus.denied) return null;
    final token = await _messaging.currentToken();
    if (token == null || token.trim().isEmpty) return null;
    return updateToken(token, customerId: customerId);
  }

  @override
  Future<PushTokenRegistration?> updateToken(
    String token, {
    String? customerId,
  }) async {
    final next = PushTokenRegistration(
      token: token,
      customerId: customerId,
      updatedAt: DateTime.now().toUtc(),
    );
    if (_lastRegistration?.token == next.token &&
        _lastRegistration?.ownerKey == next.ownerKey) {
      await _tokenSync.register(next);
      return _lastRegistration;
    }
    await _storage.write(
      _tokenKey,
      jsonEncode({
        'token': next.token,
        if (next.customerId != null) 'customerId': next.customerId,
        'updatedAt': next.updatedAt!.toIso8601String(),
      }),
    );
    await _tokenSync.register(next);
    _lastRegistration = next;
    return next;
  }

  @override
  Future<void> removeRegistration() async {
    final previous = _lastRegistration ?? await restoreRegistration();
    _lastRegistration = null;
    await _storage.delete(_tokenKey);
    await _tokenSync.remove(previous);
    await _messaging.deleteToken();
  }

  @override
  NotificationAction actionFor(NotificationPayload payload) =>
      notificationActionFor(payload);
}

Object? _decodeJson(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}
