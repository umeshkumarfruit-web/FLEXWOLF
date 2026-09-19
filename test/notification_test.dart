import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/features/notifications/data/firebase_notification_repository.dart';
import 'package:flexwolf/features/notifications/data/notification_coordinator.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/backend/backend_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification action accepts only supported deep links', () {
    expect(
      notificationActionFor(
        const NotificationPayload(id: '1', title: 'T', deepLink: '/wishlist'),
      ).isValid,
      isTrue,
    );
    expect(
      notificationActionFor(
        const NotificationPayload(id: '2', title: 'T', deepLink: '/admin'),
      ).isValid,
      isFalse,
    );
    expect(
      notificationActionFor(
        const NotificationPayload(id: '3', title: 'T', deepLink: '/'),
      ).route,
      '/',
    );
    expect(
      notificationActionFor(
        const NotificationPayload(
          id: '4',
          title: 'T',
          deepLink: '/products/hoodie',
        ),
      ).route,
      '/shop/products/hoodie',
    );
    expect(
      notificationActionFor(
        const NotificationPayload(
          id: '5',
          title: 'T',
          deepLink: '/account/orders',
        ),
      ).route,
      '/account',
    );
  });

  test('fcm registration prevents duplicate secure writes', () async {
    final storage = _CountingSecureStorage();
    final repo = FirebaseNotificationRepository(
      messaging: const _Messaging(),
      storage: storage,
      tokenSync: const NoopPushTokenSyncGateway(),
    );
    await repo.registerDevice(customerId: 'c1');
    await repo.registerDevice(customerId: 'c1');
    expect(storage.writes, 1);
    expect((await repo.restoreRegistration())?.token, 'token-1');
  });

  test('fcm registration restore ignores malformed secure storage', () async {
    final storage = _CountingSecureStorage();
    await storage.write('firebase.fcm.registration', '{bad json');
    final repo = FirebaseNotificationRepository(
      messaging: const _Messaging(),
      storage: storage,
      tokenSync: const NoopPushTokenSyncGateway(),
    );
    expect(await repo.restoreRegistration(), isNull);
  });
  test(
    'notification coordinator tracks received once and opens valid link',
    () async {
      final analytics = _Analytics();
      final routes = <String>[];
      final repo = FirebaseNotificationRepository(
        messaging: const _Messaging(),
        storage: _CountingSecureStorage(),
        tokenSync: const NoopPushTokenSyncGateway(),
      );
      final coordinator = NotificationCoordinator(
        repository: repo,
        messaging: const _Messaging(),
        analytics: analytics,
        openRoute: routes.add,
      );
      const payload = NotificationPayload(
        id: 'n1',
        title: 'Drop',
        deepLink: '/wishlist',
      );
      await coordinator.handleReceived(payload);
      await coordinator.handleReceived(payload);
      await coordinator.handleOpened(payload);
      expect(analytics.events, const [
        AppAnalyticsEvents.notificationReceived,
        AppAnalyticsEvents.notificationNavigation,
      ]);
      expect(routes, const ['/wishlist']);
    },
  );
}

class _Messaging implements FirebaseMessagingGateway {
  const _Messaging();
  @override
  Future<String?> currentToken() async => 'token-1';
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<NotificationPayload> foregroundNotifications() => const Stream.empty();
  @override
  Future<NotificationPayload?> initialNotification() async => null;
  @override
  Stream<NotificationPayload> notificationOpens() => const Stream.empty();
  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<void> prepareMessaging() async {}
  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;
  @override
  Stream<String> tokenRefreshes() => const Stream.empty();
}

class _CountingSecureStorage implements SecureStorage {
  final values = <String, String>{};
  int writes = 0;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    writes += 1;
    values[key] = value;
  }
}

class _Analytics implements AnalyticsGateway {
  final events = <String>[];
  @override
  Future<void> track(AnalyticsEvent event) async => events.add(event.name);
}
