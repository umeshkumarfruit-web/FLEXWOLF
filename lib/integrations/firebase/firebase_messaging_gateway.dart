import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flexwolf/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await _initializeFirebaseApp();
    }
  } on Object {
    return;
  }
}

class FlutterFireMessagingGateway implements FirebaseMessagingGateway {
  FlutterFireMessagingGateway({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  Future<bool>? _prepared;

  @override
  Future<void> prepareMessaging() async {
    await _prepare();
  }

  Future<bool> _prepare() {
    return _prepared ??= _prepareOnce();
  }

  Future<bool> _prepareOnce() async {
    try {
      if (Firebase.apps.isEmpty) {
        await _initializeFirebaseApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _messaging.setAutoInitEnabled(true);
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    if (!await _prepare()) return NotificationPermissionStatus.unknown;
    final settings = await _messaging.getNotificationSettings();
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!await _prepare()) return NotificationPermissionStatus.denied;
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<String?> currentToken() async {
    if (!await _prepare()) return null;
    try {
      return await _messaging.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> tokenRefreshes() async* {
    if (!await _prepare()) return;
    yield* _messaging.onTokenRefresh.where((token) => token.trim().isNotEmpty);
  }

  @override
  Stream<NotificationPayload> foregroundNotifications() async* {
    if (!await _prepare()) return;
    yield* FirebaseMessaging.onMessage
        .map(_payloadFromRemoteMessage)
        .where((payload) => payload != null)
        .cast<NotificationPayload>();
  }

  @override
  Stream<NotificationPayload> notificationOpens() async* {
    if (!await _prepare()) return;
    yield* FirebaseMessaging.onMessageOpenedApp
        .map(_payloadFromRemoteMessage)
        .where((payload) => payload != null)
        .cast<NotificationPayload>();
  }

  @override
  Future<NotificationPayload?> initialNotification() async {
    if (!await _prepare()) return null;
    return _payloadFromRemoteMessage(await _messaging.getInitialMessage());
  }

  @override
  Future<void> deleteToken() async {
    if (!await _prepare()) return;
    try {
      await _messaging.deleteToken();
    } on Object {
      return;
    }
  }
}

NotificationPermissionStatus _mapAuthorizationStatus(
  AuthorizationStatus status,
) {
  return switch (status) {
    AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
    AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
    AuthorizationStatus.denied => NotificationPermissionStatus.denied,
    AuthorizationStatus.deniedPermanently =>
      NotificationPermissionStatus.denied,
    AuthorizationStatus.notDetermined => NotificationPermissionStatus.unknown,
  };
}

NotificationPayload? _payloadFromRemoteMessage(RemoteMessage? message) {
  if (message == null) return null;
  final title =
      message.notification?.title ?? message.data['title']?.toString();
  if (title == null || title.trim().isEmpty) return null;
  return NotificationPayload(
    id:
        message.messageId ??
        message.sentTime?.millisecondsSinceEpoch.toString() ??
        title,
    title: title,
    body: message.notification?.body ?? message.data['body']?.toString(),
    deepLink:
        message.data['deepLink']?.toString() ??
        message.data['deep_link']?.toString() ??
        message.data['route']?.toString(),
  );
}

Future<void> _initializeFirebaseApp() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    rethrow;
  }
}
