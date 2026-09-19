import 'package:flexwolf/features/notifications/domain/notification_models.dart';

abstract interface class FirebaseAnalyticsGateway {
  Future<void> trackScreenView(String screenName);
}

abstract interface class FirebaseMessagingGateway {
  Future<void> prepareMessaging();
  Future<NotificationPermissionStatus> permissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<String?> currentToken();
  Stream<String> tokenRefreshes();
  Stream<NotificationPayload> foregroundNotifications();
  Stream<NotificationPayload> notificationOpens();
  Future<NotificationPayload?> initialNotification();
  Future<void> deleteToken();
}

class FirebaseMessagingNotConfigured implements FirebaseMessagingGateway {
  const FirebaseMessagingNotConfigured();
  @override
  Future<void> prepareMessaging() async {}
  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.unknown;
  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.denied;
  @override
  Future<String?> currentToken() async => null;
  @override
  Stream<String> tokenRefreshes() => const Stream<String>.empty();
  @override
  Stream<NotificationPayload> foregroundNotifications() =>
      const Stream<NotificationPayload>.empty();
  @override
  Stream<NotificationPayload> notificationOpens() =>
      const Stream<NotificationPayload>.empty();
  @override
  Future<NotificationPayload?> initialNotification() async => null;
  @override
  Future<void> deleteToken() async {}
}

abstract interface class FirebaseCrashReportingGateway {
  Future<void> recordFatal(Object error, StackTrace stackTrace);
  Future<void> recordNonFatal(Object error, StackTrace stackTrace);
}

class FirebaseCrashReportingNotConfigured
    implements FirebaseCrashReportingGateway {
  const FirebaseCrashReportingNotConfigured();

  @override
  Future<void> recordFatal(Object error, StackTrace stackTrace) async {}

  @override
  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {}
}

abstract interface class FirebaseRemoteConfigGateway {
  Future<Map<String, Object?>> fetchSafeDefaults();
}
