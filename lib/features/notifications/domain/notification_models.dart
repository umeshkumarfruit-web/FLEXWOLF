import 'package:flexwolf/app/router/deep_link_contract.dart';

class PushTokenRegistration {
  const PushTokenRegistration({
    required this.token,
    this.customerId,
    this.updatedAt,
  });
  final String token;
  final String? customerId;
  final DateTime? updatedAt;
  String get ownerKey => customerId ?? 'guest';
}

enum NotificationPermissionStatus { unknown, granted, denied, provisional }

class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.title,
    this.body,
    this.deepLink,
  });
  final String id;
  final String title;
  final String? body;
  final String? deepLink;
}

class NotificationAction {
  const NotificationAction({required this.isValid, this.route});
  final bool isValid;
  final String? route;
}

abstract interface class NotificationRepository {
  Future<void> initialize();
  Future<NotificationPermissionStatus> permissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<PushTokenRegistration?> restoreRegistration();
  Future<PushTokenRegistration?> registerDevice({String? customerId});
  Future<PushTokenRegistration?> updateToken(
    String token, {
    String? customerId,
  });
  Future<void> removeRegistration();
  NotificationAction actionFor(NotificationPayload payload);
}

NotificationAction notificationActionFor(NotificationPayload payload) {
  final resolution = const DeepLinkParser().parse(payload.deepLink);
  return NotificationAction(
    isValid: resolution.isValid,
    route: resolution.route,
  );
}
